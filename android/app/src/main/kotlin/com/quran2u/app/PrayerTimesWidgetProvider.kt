package com.quran2u.app

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
 * Correctness contract
 * --------------------
 * Dart (WidgetService) publishes only *facts*: each prayer's display strings
 * and its minutes-since-midnight. It never tells this receiver which prayer is
 * "next".
 *
 * This receiver derives the active prayer from the live system clock on every
 * single draw. That is what makes the highlight self-correcting: if Android
 * throttles our WorkManager job — very common with aggressive OEM battery
 * management — the widget still moves from Fajr to Dhuhr on time, because the
 * decision is made at render, not at refresh.
 *
 * It also redraws on TIME_SET / TIMEZONE_CHANGED / DATE_CHANGED so travelling
 * across a timezone or crossing midnight fixes itself immediately.
 */
class PrayerTimesWidgetProvider : AppWidgetProvider() {

    private companion object {
        const val JADE = "#74C6A4"
        const val IVORY = "#ECEFE9"
        const val SAGE = "#A2AFA6"

        /** Cell order — must match the layout and WidgetService's schedule map. */
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
         * Matches "4:48", "4:48 AM", "16:48". The separator class covers
         * the narrow no-break space modern ICU emits before the meridiem,
         * which a plain \\s would miss.
         */
        val CLOCK_RE = Regex("(\\d{1,2}):(\\d{2})[ \\u00A0\\u202F]*([AaPp][.]?[Mm][.]?)?")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(widgetId, buildViews(context))
        }
    }

    /**
     * AppWidgetProvider only routes APPWIDGET_UPDATE to onUpdate(). Clock and
     * calendar changes arrive as plain broadcasts, so redraw explicitly.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                val manager = AppWidgetManager.getInstance(context) ?: return
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, PrayerTimesWidgetProvider::class.java)
                )
                if (ids != null && ids.isNotEmpty()) {
                    onUpdate(context, manager, ids)
                }
            }
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )

        fun str(key: String, fallback: String) =
            prefs.getString(key, fallback) ?: fallback

        /** home_widget may store ints as Long on some plugin versions. */
        fun rawMinutes(key: String): Int = try {
            prefs.getInt(key, -1)
        } catch (e: ClassCastException) {
            try {
                prefs.getLong(key, -1L).toInt()
            } catch (e2: ClassCastException) {
                -1
            }
        }

        // -- Format-tolerant readers -------------------------------------
        // The widget must render correctly even when it finds data written by
        // an older build ("4:48 AM" only, with no _hm/_mer/_min companions).
        // Every display value is therefore derived from whatever is present.

        /** "4:48 AM" -> ("4:48", "AM"). Tolerates NBSP separators. */
        fun splitClock(raw: String): Pair<String, String> {
            val m = CLOCK_RE.find(raw) ?: return Pair(raw.trim(), "")
            val meridiem = m.groupValues[3].replace(".", "").uppercase()
            return Pair(m.groupValues[1] + ":" + m.groupValues[2], meridiem)
        }

        /** Minutes since midnight parsed out of a display string. */
        fun parseMinutes(raw: String): Int {
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

        /** Big line for a cell: prefers *_hm, falls back to parsing *_time. */
        fun display(key: String): String {
            val hm = str(key + "_hm", "")
            if (hm.isNotBlank()) return hm
            val full = str(key + "_time", "")
            return if (full.isBlank()) "--:--" else splitClock(full).first
        }

        /** Meridiem for a cell: prefers *_mer, falls back to parsing *_time. */
        fun meridiem(key: String): String {
            val mer = str(key + "_mer", "")
            if (mer.isNotBlank()) return mer
            return splitClock(str(key + "_time", "")).second
        }

        /** Minutes for a cell: prefers *_min, falls back to parsing *_time. */
        fun minutes(key: String): Int {
            val stored = rawMinutes(key + "_min")
            if (stored >= 0) return stored
            return parseMinutes(str(key + "_time", ""))
        }

        val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

        // ── Header dates ──────────────────────────────────────────────────
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

        // ── Cell contents ─────────────────────────────────────────────────
        val mins = IntArray(KEYS.size) { minutes(KEYS[it]) }
        for (i in KEYS.indices) {
            views.setTextViewText(TIME_IDS[i], display(KEYS[i]))
            views.setTextViewText(MERIDIEM_IDS[i], meridiem(KEYS[i]))
        }

        // ── Which prayer is next? Decided here, from the live clock. ──────
        val now = Calendar.getInstance()
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        var activeIndex = -1
        for (i in mins.indices) {
            if (mins[i] in 0..MINUTES_PER_DAY && mins[i] > nowMinutes) {
                activeIndex = i
                break
            }
        }
        // Every prayer for today has passed → the next one is tomorrow's Fajr.
        val allPassed = activeIndex == -1
        if (allPassed) activeIndex = 0

        val haveTimes = mins.any { it >= 0 }

        // ── Paint the cells ───────────────────────────────────────────────
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

        // ── Header pill ───────────────────────────────────────────────────
        if (haveTimes) {
            views.setTextViewText(R.id.tv_next_prayer_label, NAMES[activeIndex])

            var delta = mins[activeIndex] - nowMinutes
            if (delta < 0) delta += MINUTES_PER_DAY
            val hours = delta / 60
            val minutesLeft = delta % 60
            val countdown =
                if (hours > 0) "in ${hours}h ${minutesLeft}m" else "in ${minutesLeft}m"
            views.setTextViewText(R.id.tv_countdown, countdown)
            views.setViewVisibility(R.id.tv_countdown, View.VISIBLE)
        } else {
            views.setTextViewText(R.id.tv_next_prayer_label, "Open app")
            views.setViewVisibility(R.id.tv_countdown, View.GONE)
        }

        // ── Tap to open the app ───────────────────────────────────────────
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
