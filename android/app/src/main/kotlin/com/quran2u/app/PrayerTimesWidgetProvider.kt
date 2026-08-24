package com.quran2u.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

/**
 * Sakina prayer-times widget.
 *
 * CORRECTNESS CONTRACT
 * --------------------
 * Dart (WidgetService) publishes only *facts*: a rolling multi-day schedule of
 * prayer times as minutes since midnight. It never says which prayer is
 * "next". This receiver derives that from the live system clock on every draw.
 *
 * THE TWO BUGS THIS FILE EXISTS TO PREVENT
 * ----------------------------------------
 * 1. STALE DATA. The old build published a single day. Leave the app closed
 *    past midnight and the widget was doing clock arithmetic against
 *    yesterday's times — wrong prayer highlighted, wrong countdown — and it
 *    only healed when the app was next opened. It now reads a seven-day
 *    schedule and selects the row for today, so the data stays right for a
 *    week whether or not the app is ever launched.
 *
 * 2. NO REDRAW. `updatePeriodMillis` is the only automatic trigger a widget
 *    gets, its floor is 30 minutes, and Android coalesces or outright drops it
 *    in Doze. So even with correct data the widget sat on a passed prayer for
 *    hours. This receiver now sets its own alarm for the minute of the next
 *    prayer transition; when it fires, the widget redraws and arms the
 *    following one. The chain is self-perpetuating and needs no app process.
 *
 * The redraw alarm is deliberately INEXACT (`setAndAllowWhileIdle`): it needs
 * no permission on any Android version, survives Doze, and a widget repainting
 * a minute late is invisible. The adhan is a separate, exact alarm — a call to
 * prayer and a repaint have very different tolerances.
 */
class PrayerTimesWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val JADE = "#74C6A4"
        const val IVORY = "#ECEFE9"
        const val SAGE = "#A2AFA6"

        /** Our own broadcast, sent by the self-scheduled redraw alarm. */
        const val ACTION_TICK = "com.quran2u.app.WIDGET_TICK"
        const val TICK_REQUEST_CODE = 8801

        /** Cell order — must match the layout and WidgetService.prayerKeys. */
        val KEYS = arrayOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
        val NAMES = arrayOf("Fajr", "Shuruq", "Dhuhr", "Asr", "Maghrib", "Isha")

        val ROW_IDS = intArrayOf(
            R.id.row_fajr, R.id.row_sunrise, R.id.row_dhuhr,
            R.id.row_asr, R.id.row_maghrib, R.id.row_isha
        )
        val TIME_IDS = intArrayOf(
            R.id.tv_fajr, R.id.tv_sunrise, R.id.tv_dhuhr,
            R.id.tv_asr, R.id.tv_maghrib, R.id.tv_isha
        )
        val LABEL_IDS = intArrayOf(
            R.id.lbl_fajr, R.id.lbl_sunrise, R.id.lbl_dhuhr,
            R.id.lbl_asr, R.id.lbl_maghrib, R.id.lbl_isha
        )
        val MERIDIEM_IDS = intArrayOf(
            R.id.mer_fajr, R.id.mer_sunrise, R.id.mer_dhuhr,
            R.id.mer_asr, R.id.mer_maghrib, R.id.mer_isha
        )

        const val MINUTES_PER_DAY = 24 * 60

        /**
         * Matches "4:48", "4:48 AM", "16:48". The separator class covers the
         * narrow no-break space modern ICU emits before the meridiem, which a
         * plain \\s would miss.
         */
        val CLOCK_RE = Regex("(\\d{1,2}):(\\d{2})[ \\u00A0\\u202F]*([AaPp][.]?[Mm][.]?)?")
    }

    // ── Entry points ─────────────────────────────────────────────────────

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(widgetId, buildViews(context))
        }
        scheduleNextTick(context)
    }

    /**
     * AppWidgetProvider only routes APPWIDGET_UPDATE to onUpdate(). Clock
     * changes, boot and our own tick arrive as plain broadcasts.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TICK,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> redrawAll(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleNextTick(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelTick(context)
    }

    private fun redrawAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrayerTimesWidgetProvider::class.java)
        )
        if (ids != null && ids.isNotEmpty()) {
            onUpdate(context, manager, ids)
        } else {
            // No widgets left on the home screen — stop waking the device.
            cancelTick(context)
        }
    }

    // ── The self-perpetuating redraw ─────────────────────────────────────

    /**
     * Arms one alarm for the next prayer transition. Every firing redraws and
     * arms the next, so the widget keeps itself current with no app process
     * and without relying on `updatePeriodMillis`.
     *
     * Falls back to just after midnight when there is no usable schedule, so
     * even a widget showing "Open app" rolls into the new day by itself.
     */
    private fun scheduleNextTick(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val at = nextTransitionMillis(context)

        try {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, tickIntent(context))
        } catch (e: SecurityException) {
            // Some OEM builds restrict even inexact wake alarms for background
            // apps. The 30-minute updatePeriodMillis remains as a backstop.
        } catch (e: Exception) {
            // Never let a scheduling failure take the widget down with it.
        }
    }

    private fun cancelTick(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarms.cancel(tickIntent(context))
        } catch (e: Exception) {
        }
    }

    private fun tickIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerTimesWidgetProvider::class.java)
            .setAction(ACTION_TICK)
        return PendingIntent.getBroadcast(
            context, TICK_REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** Wall-clock instant of the next cell change, or just after midnight. */
    private fun nextTransitionMillis(context: Context): Long {
        val now = Calendar.getInstance()
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val mins = readMinutes(context, now)

        val nextToday = mins.filter { it in (nowMinutes + 1)..MINUTES_PER_DAY }.minOrNull()

        val target = Calendar.getInstance().apply {
            set(Calendar.MILLISECOND, 0)
            if (nextToday != null) {
                set(Calendar.HOUR_OF_DAY, nextToday / 60)
                set(Calendar.MINUTE, nextToday % 60)
                set(Calendar.SECOND, 5)   // a few seconds past, never before
            } else {
                // Nothing left today — wake just after midnight for the new row.
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 20)
            }
        }

        // Guard against a target that has already slipped past.
        if (target.timeInMillis <= System.currentTimeMillis()) {
            return System.currentTimeMillis() + 60_000L
        }
        return target.timeInMillis
    }

    // ── Reading the published schedule ───────────────────────────────────

    private fun prefs(context: Context) =
        context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

    /**
     * The six prayer times for [day] as minutes since midnight, or -1 each.
     *
     * Prefers the multi-day schedule; falls back to the single-day keys an
     * older build published, so upgrading never blanks a live widget.
     */
    private fun readMinutes(context: Context, day: Calendar): IntArray {
        fromSchedule(context, day)?.let { return it }

        val p = prefs(context)
        fun str(key: String): String = try {
            p.getString(key, "") ?: ""
        } catch (e: ClassCastException) {
            ""
        }
        /** home_widget stores ints as Long on some plugin versions. */
        fun rawMinutes(key: String): Int = try {
            p.getInt(key, -1)
        } catch (e: ClassCastException) {
            try {
                p.getLong(key, -1L).toInt()
            } catch (e2: ClassCastException) {
                -1
            }
        }

        return IntArray(KEYS.size) { i ->
            val stored = rawMinutes(KEYS[i] + "_min")
            if (stored >= 0) stored else parseMinutes(str(KEYS[i] + "_time"))
        }
    }

    /** Parses `sched_v2` and returns the row whose date matches [day]. */
    private fun fromSchedule(context: Context, day: Calendar): IntArray? {
        val raw = try {
            prefs(context).getString("sched_v2", "") ?: ""
        } catch (e: ClassCastException) {
            ""
        }
        if (raw.isBlank()) return null

        val stamp = "%04d%02d%02d".format(
            day.get(Calendar.YEAR),
            day.get(Calendar.MONTH) + 1,
            day.get(Calendar.DAY_OF_MONTH)
        )

        for (row in raw.split(';')) {
            val sep = row.indexOf(':')
            if (sep <= 0 || row.substring(0, sep) != stamp) continue

            val parts = row.substring(sep + 1).split(',')
            if (parts.size < KEYS.size) return null
            val out = IntArray(KEYS.size) { parts[it].trim().toIntOrNull() ?: -1 }
            return if (out.all { it in 0..MINUTES_PER_DAY }) out else null
        }
        return null
    }

    private fun parseMinutes(raw: String): Int {
        val m = CLOCK_RE.find(raw) ?: return -1
        var hour = m.groupValues[1].toIntOrNull() ?: return -1
        val minute = m.groupValues[2].toIntOrNull() ?: return -1
        when (m.groupValues[3].replace(".", "").uppercase()) {
            "AM" -> if (hour == 12) hour = 0
            "PM" -> if (hour < 12) hour += 12
        }
        if (hour !in 0..23 || minute !in 0..59) return -1
        return hour * 60 + minute
    }

    /** 288 -> "4:48". Formatted here so every day's row renders identically. */
    private fun hourMinute(minutes: Int): String {
        if (minutes < 0) return "--:--"
        var h = (minutes / 60) % 24
        if (h == 0) h = 12 else if (h > 12) h -= 12
        return "%d:%02d".format(h, minutes % 60)
    }

    private fun meridiem(minutes: Int): String =
        if (minutes < 0) "" else if ((minutes / 60) % 24 < 12) "AM" else "PM"

    // ── Drawing ──────────────────────────────────────────────────────────

    private fun buildViews(context: Context): RemoteViews {
        val p = prefs(context)
        fun str(key: String, fallback: String) = try {
            p.getString(key, fallback) ?: fallback
        } catch (e: ClassCastException) {
            fallback
        }

        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

        // ── Header dates ─────────────────────────────────────────────────
        val hijri = str("hijri_date", "")
        val greg = str("greg_date", "")
        views.setTextViewText(R.id.tv_hijri_date, hijri)
        views.setTextViewText(R.id.tv_greg_date, greg)
        views.setViewVisibility(
            R.id.tv_hijri_date, if (hijri.isBlank()) View.GONE else View.VISIBLE
        )
        views.setViewVisibility(
            R.id.tv_greg_date, if (greg.isBlank()) View.GONE else View.VISIBLE
        )

        // ── Today's row, chosen by the live clock ────────────────────────
        val now = Calendar.getInstance()
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val mins = readMinutes(context, now)

        for (i in KEYS.indices) {
            views.setTextViewText(TIME_IDS[i], hourMinute(mins[i]))
            views.setTextViewText(MERIDIEM_IDS[i], meridiem(mins[i]))
        }

        // ── Which prayer is next? ────────────────────────────────────────
        var activeIndex = -1
        for (i in mins.indices) {
            if (mins[i] in 0..MINUTES_PER_DAY && mins[i] > nowMinutes) {
                activeIndex = i
                break
            }
        }

        // Everything today has passed → tomorrow's Fajr. Read the real value
        // from the schedule rather than reusing today's, which drifts by about
        // a minute a day.
        val countdownTarget: Int
        if (activeIndex == -1) {
            activeIndex = 0
            val tomorrow = (now.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            val tomorrowFajr = readMinutes(context, tomorrow)[0]
            countdownTarget =
                (if (tomorrowFajr >= 0) tomorrowFajr else mins[0]) + MINUTES_PER_DAY
        } else {
            countdownTarget = mins[activeIndex]
        }

        val haveTimes = mins.any { it >= 0 }

        // ── Paint the cells ──────────────────────────────────────────────
        for (i in KEYS.indices) {
            val active = haveTimes && i == activeIndex
            views.setInt(
                ROW_IDS[i],
                "setBackgroundResource",
                if (active) R.drawable.widget_cell_active else R.drawable.widget_cell_normal
            )
            val timeColor = Color.parseColor(if (active) JADE else IVORY)
            val subColor = Color.parseColor(if (active) JADE else SAGE)
            views.setTextColor(TIME_IDS[i], timeColor)
            views.setTextColor(LABEL_IDS[i], subColor)
            views.setTextColor(MERIDIEM_IDS[i], subColor)
        }

        // ── Header pill ──────────────────────────────────────────────────
        if (haveTimes) {
            views.setTextViewText(R.id.tv_next_prayer_label, NAMES[activeIndex])

            var delta = countdownTarget - nowMinutes
            if (delta < 0) delta += MINUTES_PER_DAY
            val hours = delta / 60
            val minutesLeft = delta % 60
            views.setTextViewText(
                R.id.tv_countdown,
                if (hours > 0) "in ${hours}h ${minutesLeft}m" else "in ${minutesLeft}m"
            )
            views.setViewVisibility(R.id.tv_countdown, View.VISIBLE)
        } else {
            views.setTextViewText(R.id.tv_next_prayer_label, "Open app")
            views.setViewVisibility(R.id.tv_countdown, View.GONE)
        }

        // ── Tap to open the app ──────────────────────────────────────────
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            val pi = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
        }

        return views
    }
}
