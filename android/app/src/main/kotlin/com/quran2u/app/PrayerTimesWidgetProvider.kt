package com.quran2u.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val fajr        = prefs.getString("fajr_time",    "--:--") ?: "--:--"
        val sunrise     = prefs.getString("sunrise_time", "--:--") ?: "--:--"
        val dhuhr       = prefs.getString("dhuhr_time",   "--:--") ?: "--:--"
        val asr         = prefs.getString("asr_time",     "--:--") ?: "--:--"
        val maghrib     = prefs.getString("maghrib_time", "--:--") ?: "--:--"
        val isha        = prefs.getString("isha_time",    "--:--") ?: "--:--"
        val nextName    = prefs.getString("next_prayer_name", "Fajr") ?: "Fajr"
        val nextRemain  = prefs.getString("next_prayer_remaining", "") ?: ""
        val highlightIdx = prefs.getInt("highlight_index", 0)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget)

            views.setTextViewText(R.id.tv_fajr,              fajr)
            views.setTextViewText(R.id.tv_sunrise,           sunrise)
            views.setTextViewText(R.id.tv_dhuhr,             dhuhr)
            views.setTextViewText(R.id.tv_asr,               asr)
            views.setTextViewText(R.id.tv_maghrib,           maghrib)
            views.setTextViewText(R.id.tv_isha,              isha)
            views.setTextViewText(R.id.tv_next_prayer_label, "Next: $nextName")
            views.setTextViewText(R.id.tv_countdown,         nextRemain)

            // Highlight active prayer cell with green tint.
            // Layout order: fajr=0, dhuhr=1, maghrib=2, sunrise=3, asr=4, isha=5
            val rowIds = intArrayOf(
                R.id.row_fajr, R.id.row_dhuhr, R.id.row_maghrib,
                R.id.row_sunrise, R.id.row_asr, R.id.row_isha
            )
            // Map highlight_index (0=fajr,1=sunrise,2=dhuhr,3=asr,4=maghrib,5=isha)
            // to layout positions
            val layoutOrder = intArrayOf(0, 3, 1, 4, 2, 5)
            val activeLayoutIdx = if (highlightIdx < layoutOrder.size) layoutOrder[highlightIdx] else 0

            for (i in rowIds.indices) {
                if (i == activeLayoutIdx) {
                    views.setInt(rowIds[i], "setBackgroundColor", Color.parseColor("#7700C853"))
                } else {
                    views.setInt(rowIds[i], "setBackgroundColor", Color.parseColor("#1AFFFFFF"))
                }
            }

            // Tap to open app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pi = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pi)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
