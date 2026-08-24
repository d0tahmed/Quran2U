package com.quran2u.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar

/**
 * Arms the alarms that fire the adhan.
 *
 * WHY THIS LIVES IN KOTLIN AND NOT IN DART
 * ----------------------------------------
 * Every step after "the alarm was set" happens with the Flutter process dead:
 * the device is dozing, the app has been swiped away, and there is no Dart
 * isolate to run. So the schedule is published by Dart into SharedPreferences
 * and everything downstream of it is native.
 *
 * IT READS THE SAME ROWS THE WIDGET DRAWS
 * ---------------------------------------
 * `sched_v2` is written once by WidgetService and consumed by both the widget
 * and this scheduler. That is deliberate: if the widget shows Asr at 5:10 then
 * the adhan fires at 5:10, because there is only one set of numbers. The old
 * failure mode — widget stale, so the call would have been stale too — cannot
 * happen if there is only one source.
 *
 * ALARM STRATEGY
 * --------------
 * The soonest prayer gets `setAlarmClock`, the strongest primitive Android
 * offers: the system leaves low-power mode for it, never slides its delivery,
 * and surfaces it as the next alarm. The ones behind it get
 * `setExactAndAllowWhileIdle`, which is nearly as reliable and does not put a
 * second alarm icon in the status bar.
 *
 * A batch is armed rather than a single self-chaining alarm so that one lost
 * broadcast costs one prayer, not every prayer after it.
 */
object AdhanScheduler {

    private const val TAG = "AdhanScheduler"

    const val PREFS = "HomeWidgetPreferences"
    const val KEY_SCHEDULE = "sched_v2"
    const val KEY_ENABLED = "adhan_enabled"
    const val KEY_VOLUME = "adhan_volume"

    const val ACTION_FIRE = "com.quran2u.app.ADHAN_FIRE"
    const val EXTRA_PRAYER = "prayer"

    /** Request-code block reserved for adhan alarms. */
    private const val BASE_REQUEST = 9000

    /** How many upcoming prayers are armed at once — roughly four days. */
    private const val BATCH = 20

    /**
     * Cell order matches WidgetService.prayerKeys. Sunrise is index 1 and is
     * deliberately never armed: there is no call to prayer at sunrise, and
     * firing one would be a straightforward error of fact.
     */
    val KEYS = arrayOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
    val LABELS = arrayOf("Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha")
    private val ADHAN_INDICES = intArrayOf(0, 2, 3, 4, 5)

    /** Per-prayer mode, stored as `adhan_mode_fajr` etc. */
    const val MODE_FULL = "full"
    const val MODE_NOTIFY = "notify"
    const val MODE_OFF = "off"

    fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun modeFor(context: Context, index: Int): String {
        if (index !in KEYS.indices) return MODE_OFF
        return try {
            prefs(context).getString("adhan_mode_" + KEYS[index], MODE_OFF) ?: MODE_OFF
        } catch (e: ClassCastException) {
            MODE_OFF
        }
    }

    fun isEnabled(context: Context): Boolean = try {
        prefs(context).getBoolean(KEY_ENABLED, false)
    } catch (e: ClassCastException) {
        false
    }

    // ── Arming ───────────────────────────────────────────────────────────

    /**
     * Cancels the whole reserved block and re-arms it from the current
     * schedule. Safe to call as often as you like — on boot, on app resume,
     * after every firing, after a settings change. Never throws.
     */
    fun rearm(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        for (i in 0 until BATCH) {
            try {
                alarms.cancel(firePendingIntent(context, i, 0))
            } catch (e: Exception) {
                // Cancelling a slot that was never armed is not an error.
            }
        }

        if (!isEnabled(context)) {
            Log.d(TAG, "adhan disabled — nothing armed")
            return
        }

        val upcoming = upcomingPrayers(context)
        if (upcoming.isEmpty()) {
            Log.w(TAG, "no usable schedule — nothing armed")
            return
        }

        var slot = 0
        for ((atMillis, prayerIndex) in upcoming) {
            if (slot >= BATCH) break
            val pi = firePendingIntent(context, slot, prayerIndex)
            val armed = if (slot == 0) {
                armAlarmClock(context, alarms, atMillis, pi)
            } else {
                armExact(alarms, atMillis, pi)
            }
            if (armed) slot++
        }
        Log.d(TAG, "armed $slot adhan alarm(s)")
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        for (i in 0 until BATCH) {
            try {
                alarms.cancel(firePendingIntent(context, i, 0))
            } catch (e: Exception) {
            }
        }
    }

    /**
     * `setAlarmClock` is the only alarm type the system treats as
     * user-critical. It also needs an exact-alarm permission on Android 12+;
     * when that is missing we degrade rather than throw, because a late adhan
     * beats no adhan.
     */
    private fun armAlarmClock(
        context: Context,
        alarms: AlarmManager,
        atMillis: Long,
        pi: PendingIntent
    ): Boolean {
        if (canScheduleExact(alarms)) {
            try {
                val show = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.let {
                        PendingIntent.getActivity(
                            context, 0, it,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                    }
                alarms.setAlarmClock(AlarmManager.AlarmClockInfo(atMillis, show), pi)
                return true
            } catch (e: Exception) {
                Log.w(TAG, "setAlarmClock failed: $e")
            }
        }
        return armExact(alarms, atMillis, pi)
    }

    private fun armExact(alarms: AlarmManager, atMillis: Long, pi: PendingIntent): Boolean {
        if (canScheduleExact(alarms)) {
            try {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
                return true
            } catch (e: Exception) {
                Log.w(TAG, "setExactAndAllowWhileIdle failed: $e")
            }
        }
        // Last resort: inexact, but it needs no permission and still fires.
        return try {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            true
        } catch (e: Exception) {
            Log.e(TAG, "all alarm strategies failed: $e")
            false
        }
    }

    /**
     * On Android 12+ exact alarms need permission. The manifest declares
     * USE_EXACT_ALARM, which is auto-granted from Android 13, so in practice
     * this is only false on Android 12 with the permission withheld.
     */
    fun canScheduleExact(alarms: AlarmManager): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                alarms.canScheduleExactAlarms()
            } catch (e: Exception) {
                false
            }
        } else {
            true
        }

    fun canScheduleExact(context: Context): Boolean {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: return false
        return canScheduleExact(alarms)
    }

    private fun firePendingIntent(context: Context, slot: Int, prayerIndex: Int): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_PRAYER, prayerIndex)
        return PendingIntent.getBroadcast(
            context, BASE_REQUEST + slot, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    // ── Reading the published schedule ───────────────────────────────────

    /**
     * Every enabled prayer still in the future, soonest first, as
     * (epochMillis, prayerIndex).
     */
    private fun upcomingPrayers(context: Context): List<Pair<Long, Int>> {
        val raw = try {
            prefs(context).getString(KEY_SCHEDULE, "") ?: ""
        } catch (e: ClassCastException) {
            ""
        }
        if (raw.isBlank()) return emptyList()

        val now = System.currentTimeMillis()
        val out = ArrayList<Pair<Long, Int>>()

        for (row in raw.split(';')) {
            val sep = row.indexOf(':')
            if (sep <= 0) continue

            val stamp = row.substring(0, sep)
            if (stamp.length != 8) continue
            val year = stamp.substring(0, 4).toIntOrNull() ?: continue
            val month = stamp.substring(4, 6).toIntOrNull() ?: continue
            val day = stamp.substring(6, 8).toIntOrNull() ?: continue

            val parts = row.substring(sep + 1).split(',')
            if (parts.size < KEYS.size) continue

            for (index in ADHAN_INDICES) {
                if (modeFor(context, index) == MODE_OFF) continue
                val minutes = parts[index].trim().toIntOrNull() ?: continue
                if (minutes !in 0..(24 * 60)) continue

                val at = Calendar.getInstance().apply {
                    set(Calendar.YEAR, year)
                    set(Calendar.MONTH, month - 1)
                    set(Calendar.DAY_OF_MONTH, day)
                    set(Calendar.HOUR_OF_DAY, minutes / 60)
                    set(Calendar.MINUTE, minutes % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis

                // A few seconds of slack so an alarm that fires marginally
                // early is not immediately re-armed for the same instant.
                if (at > now + 5_000L) out.add(Pair(at, index))
            }
        }

        out.sortBy { it.first }
        return out
    }
}
