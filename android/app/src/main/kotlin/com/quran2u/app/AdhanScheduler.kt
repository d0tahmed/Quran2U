package com.quran2u.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
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
 * and this scheduler. If the widget shows Asr at 5:08 then the adhan fires at
 * 5:08, because there is only one set of numbers.
 *
 * ─────────────────────────────────────────────────────────────────────────
 * THE BUG THIS FILE WAS REWRITTEN TO KILL: THE WRONG PRAYER
 * ─────────────────────────────────────────────────────────────────────────
 * The first version identified an alarm by its position in a queue — slot 0
 * was "the next prayer", slot 1 "the one after", and the prayer's identity
 * travelled in the intent's EXTRAS.
 *
 * Extras are the one part of an Intent that `Intent.filterEquals` ignores, and
 * filterEquals is what `PendingIntent` uses to decide whether two requests are
 * the same pending intent. So all twenty slots were, as far as the system was
 * concerned, twenty copies of one intent distinguished only by request code —
 * and the mapping from slot to prayer changed every single time the batch was
 * re-armed, because prayers drop off the front as the day goes by.
 *
 * Re-arm at 12:00 and slot 0 means Dhuhr. Re-arm at 12:40 and slot 0 means
 * Asr. If a cancel does not land before the re-arm — a race this design invites
 * on every app resume, and one that OEM alarm managers lose routinely — an
 * alarm scheduled for Dhuhr's minute is left holding Asr's extras. Which is
 * exactly what was reported: the Asr adhan, at Dhuhr time.
 *
 * The fix is to stop identifying alarms by queue position at all. An alarm is
 * now identified by WHICH PRAYER ON WHICH DAY, carried in the intent's DATA
 * URI — `quran2u://adhan/20260825/2`. Data *is* part of filterEquals, so:
 *
 *   • two different prayers can never collapse onto one PendingIntent;
 *   • cancelling a prayer cancels that prayer and nothing else;
 *   • re-arming the same prayer overwrites its own alarm, so re-arming is
 *     idempotent and racing with itself is harmless.
 *
 * Nothing about which prayer is firing depends on when the batch was last
 * rebuilt any more, because nothing about it is positional.
 *
 * And a belt to go with the braces: before playing, the receiver looks the
 * prayer up in the live schedule and refuses to sound if the clock does not
 * agree to within [TOLERANCE_MIN] minutes. A wrong-prayer adhan now requires
 * both the identity and the clock to be wrong at once.
 */
object AdhanScheduler {

    private const val TAG = "AdhanScheduler"

    const val PREFS = "HomeWidgetPreferences"
    const val KEY_SCHEDULE = "sched_v2"
    const val KEY_ENABLED = "adhan_enabled"

    /** Guards against the same prayer sounding twice. */
    private const val KEY_LAST_FIRED = "adhan_last_fired"

    const val ACTION_FIRE = "com.quran2u.app.ADHAN_FIRE"
    const val SCHEME = "quran2u"

    /** Request-code block reserved for adhan alarms. */
    private const val BASE_REQUEST = 9000

    /** Days of schedule published by Dart. Bounds the request-code block. */
    private const val DAYS = 7

    /** Cells per day in `sched_v2`. */
    private const val CELLS = 6

    /**
     * How far from its scheduled minute an alarm may fire and still be
     * believed. Generous enough for an inexact fallback that the system
     * deferred, tight enough that no prayer's window can overlap another's.
     */
    const val TOLERANCE_MIN = 15

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

    // ── One prayer, on one day ───────────────────────────────────────────

    /** A single occurrence: which prayer, on which date, at what instant. */
    data class Occurrence(val stamp: String, val index: Int, val atMillis: Long)

    /**
     * The identity of an occurrence, as a URI.
     *
     * This string is the whole fix. It goes in the intent's data, which
     * `filterEquals` compares, so the system can tell Dhuhr's alarm from
     * Asr's — which it could not when the difference lived in the extras.
     */
    private fun uriFor(stamp: String, index: Int): Uri =
        Uri.parse("$SCHEME://adhan/$stamp/$index")

    /**
     * A request code that is stable for a given prayer on a given day.
     *
     * Derived from the day's offset from today rather than from a queue
     * position, so it does not shift under us as the day advances. Collisions
     * across the 7-day window are impossible: `dayOffset` is 0..6 and `index`
     * is 0..5, so the block is exactly 42 codes wide.
     */
    private fun requestCode(dayOffset: Int, index: Int): Int =
        BASE_REQUEST + dayOffset * CELLS + index

    private fun firePendingIntent(
        context: Context,
        stamp: String,
        index: Int,
        dayOffset: Int
    ): PendingIntent {
        val intent = Intent(context, AdhanReceiver::class.java)
            .setAction(ACTION_FIRE)
            .setData(uriFor(stamp, index))
        return PendingIntent.getBroadcast(
            context, requestCode(dayOffset, index), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** Reads the prayer index back out of a fired alarm's data URI. */
    fun indexFromUri(data: Uri?): Int {
        val segments = data?.pathSegments ?: return -1
        if (segments.size < 2) return -1
        return segments[1].toIntOrNull() ?: -1
    }

    /** Reads the date stamp back out of a fired alarm's data URI. */
    fun stampFromUri(data: Uri?): String? {
        val segments = data?.pathSegments ?: return null
        if (segments.isEmpty()) return null
        return segments[0].takeIf { it.length == 8 }
    }

    // ── Arming ───────────────────────────────────────────────────────────

    /**
     * Cancels the whole reserved block and re-arms it from the current
     * schedule. Safe to call as often as you like — on boot, on app resume,
     * after every firing, after a settings change. Never throws.
     */
    fun rearm(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

        val occurrences = upcomingPrayers(context)

        // Cancel by identity across the whole window, using the same stamps
        // the schedule publishes. Because the data URI is part of the match,
        // each cancel removes exactly the alarm it names — no cross-talk with
        // a neighbouring prayer, which is what the old positional block had.
        cancelWindow(context, alarms)

        if (!isEnabled(context)) {
            Log.d(TAG, "adhan disabled — nothing armed")
            return
        }
        if (occurrences.isEmpty()) {
            Log.w(TAG, "no usable schedule — nothing armed")
            return
        }

        var armedCount = 0
        var first = true
        for (occurrence in occurrences) {
            val dayOffset = dayOffsetOf(context, occurrence.stamp)
            if (dayOffset < 0) continue

            val pi = firePendingIntent(context, occurrence.stamp, occurrence.index, dayOffset)

            // Only the soonest gets setAlarmClock. It is the strongest
            // primitive Android offers — the system leaves low-power mode for
            // it and never slides its delivery — but it also puts an alarm
            // icon in the status bar, and five icons would be absurd.
            val ok = if (first) {
                armAlarmClock(context, alarms, occurrence.atMillis, pi)
            } else {
                armExact(alarms, occurrence.atMillis, pi)
            }

            if (ok) {
                armedCount++
                first = false
            }
        }

        Log.d(TAG, "armed $armedCount adhan alarm(s); next=" +
            (occurrences.firstOrNull()?.let { "${LABELS[it.index]} @ ${it.atMillis}" } ?: "none"))
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        cancelWindow(context, alarms)
    }

    /**
     * Cancels every alarm in the 7-day block.
     *
     * The stamps are recomputed from today's date rather than read back from
     * the schedule, so this still clears the block when the schedule string is
     * missing or has been rewritten — which is precisely when orphaned alarms
     * would otherwise survive and fire for a day that no longer applies.
     */
    private fun cancelWindow(context: Context, alarms: AlarmManager) {
        val cal = Calendar.getInstance()
        for (dayOffset in 0 until DAYS) {
            val stamp = stampOf(cal)
            for (index in ADHAN_INDICES) {
                try {
                    alarms.cancel(firePendingIntent(context, stamp, index, dayOffset))
                } catch (e: Exception) {
                    // Cancelling something that was never armed is not an error.
                }
            }
            cal.add(Calendar.DAY_OF_MONTH, 1)
        }
    }

    private fun stampOf(cal: Calendar): String = String.format(
        "%04d%02d%02d",
        cal.get(Calendar.YEAR),
        cal.get(Calendar.MONTH) + 1,
        cal.get(Calendar.DAY_OF_MONTH)
    )

    /** How many days after today [stamp] falls, or -1 if outside the window. */
    private fun dayOffsetOf(context: Context, stamp: String): Int {
        val cal = Calendar.getInstance()
        for (offset in 0 until DAYS) {
            if (stampOf(cal) == stamp) return offset
            cal.add(Calendar.DAY_OF_MONTH, 1)
        }
        return -1
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

    // ── Verification ─────────────────────────────────────────────────────

    /**
     * The scheduled instant for one occurrence, straight from the published
     * schedule, or null when the schedule does not contain it.
     */
    fun scheduledMillis(context: Context, stamp: String, index: Int): Long? {
        for (occurrence in allPrayers(context)) {
            if (occurrence.stamp == stamp && occurrence.index == index) {
                return occurrence.atMillis
            }
        }
        return null
    }

    /**
     * Whether an alarm that has just fired should actually sound.
     *
     * Three ways to fail, and all three are worth failing on:
     *   • the prayer is not in the published schedule at all;
     *   • the clock disagrees with it by more than the tolerance, which means
     *     this alarm is stale — a leftover from a schedule that has since been
     *     replaced;
     *   • this exact occurrence has already sounded, so a duplicate delivery
     *     or an early-then-rearmed alarm cannot play it twice.
     */
    fun shouldSound(context: Context, stamp: String, index: Int): Boolean {
        val scheduled = scheduledMillis(context, stamp, index)
        if (scheduled == null) {
            Log.w(TAG, "refusing $stamp/$index — not in the published schedule")
            return false
        }

        val drift = Math.abs(System.currentTimeMillis() - scheduled)
        if (drift > TOLERANCE_MIN * 60_000L) {
            Log.w(TAG, "refusing $stamp/$index — ${drift / 60_000}min from its slot")
            return false
        }

        val key = "$stamp/$index"
        val last = try {
            prefs(context).getString(KEY_LAST_FIRED, "")
        } catch (e: ClassCastException) {
            ""
        }
        if (last == key) {
            Log.w(TAG, "refusing $key — already sounded")
            return false
        }

        try {
            prefs(context).edit().putString(KEY_LAST_FIRED, key).apply()
        } catch (e: Exception) {
            // Losing the de-dup marker is survivable; a missed adhan is not.
        }
        return true
    }

    // ── Reading the published schedule ───────────────────────────────────

    /** Every enabled prayer still in the future, soonest first. */
    private fun upcomingPrayers(context: Context): List<Occurrence> {
        val now = System.currentTimeMillis()

        // Two seconds, and no more.
        //
        // The temptation is to widen this to a minute so that a prayer which
        // has only just fired cannot be re-armed and sound twice. That trade is
        // a bad one: re-arming happens on every app resume, so a one-minute
        // window means opening the app at 12:34:30 drops the 12:35 Dhuhr
        // entirely — the prayer is cancelled with the rest of the block and
        // then filtered out of the batch that replaces it. Silently missing a
        // prayer is far worse than briefly risking a repeat.
        //
        // Double-play is prevented properly instead, by [shouldSound], which
        // records the occurrence that last sounded and refuses to repeat it.
        // An occurrence armed a moment after it was due simply fires at once
        // and is turned away there.
        return allPrayers(context)
            .filter { it.atMillis > now + 2_000L && modeFor(context, it.index) != MODE_OFF }
    }

    /** Every prayer in the published window, enabled or not, soonest first. */
    private fun allPrayers(context: Context): List<Occurrence> {
        val raw = try {
            prefs(context).getString(KEY_SCHEDULE, "") ?: ""
        } catch (e: ClassCastException) {
            ""
        }
        if (raw.isBlank()) return emptyList()

        val out = ArrayList<Occurrence>()

        for (row in raw.split(';')) {
            val sep = row.indexOf(':')
            if (sep <= 0) continue

            val stamp = row.substring(0, sep)
            if (stamp.length != 8) continue
            val year = stamp.substring(0, 4).toIntOrNull() ?: continue
            val month = stamp.substring(4, 6).toIntOrNull() ?: continue
            val day = stamp.substring(6, 8).toIntOrNull() ?: continue

            val parts = row.substring(sep + 1).split(',')
            if (parts.size < CELLS) continue

            for (index in ADHAN_INDICES) {
                val minutes = parts[index].trim().toIntOrNull() ?: continue
                if (minutes !in 0..(24 * 60)) continue

                // Built from a cleared calendar rather than from "now".
                // Calendar.getInstance() carries today's fields, and a partial
                // overwrite leaves whichever ones you did not set — a quiet
                // source of off-by-a-day and off-by-an-hour bugs.
                val cal = Calendar.getInstance()
                cal.clear()
                cal.set(year, month - 1, day, minutes / 60, minutes % 60, 0)
                out.add(Occurrence(stamp, index, cal.timeInMillis))
            }
        }

        out.sortBy { it.atMillis }
        return out
    }

    /** The next prayer that will actually sound, for the Settings readout. */
    fun nextAudible(context: Context): Occurrence? =
        if (!isEnabled(context)) null else upcomingPrayers(context).firstOrNull()
}
