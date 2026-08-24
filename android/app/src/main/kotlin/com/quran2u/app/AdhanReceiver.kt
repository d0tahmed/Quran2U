package com.quran2u.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Catches the adhan alarm and everything that should cause a re-arm.
 *
 * A BroadcastReceiver gets roughly ten seconds before Android considers it
 * hung, so this does exactly two things: hand off to the foreground service,
 * and re-arm the batch. No I/O beyond SharedPreferences, no playback here.
 *
 * Starting a foreground service from the background is blocked on Android 12+,
 * with an explicit exemption for a broadcast delivered by an exact alarm —
 * which is precisely how we get here. That exemption is the reason the alarm
 * has to be exact and not merely inexact.
 */
class AdhanReceiver : BroadcastReceiver() {

    private companion object {
        const val TAG = "AdhanReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            AdhanScheduler.ACTION_FIRE -> {
                val prayer = intent.getIntExtra(AdhanScheduler.EXTRA_PRAYER, -1)
                Log.d(TAG, "adhan alarm for prayer index $prayer")

                if (prayer in AdhanScheduler.KEYS.indices &&
                    AdhanScheduler.isEnabled(context)
                ) {
                    val mode = AdhanScheduler.modeFor(context, prayer)
                    if (mode != AdhanScheduler.MODE_OFF) {
                        startAdhan(context, prayer, mode)
                    }
                }

                // Re-arm immediately: the slot we just consumed has to be
                // refilled, and this is the one moment we are guaranteed to be
                // running even if the app is never opened again.
                AdhanScheduler.rearm(context)
            }

            // Every one of these can invalidate a pending alarm: a reboot
            // clears them all, a clock or timezone change moves the target,
            // and an app update wipes the block.
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "re-arming after ${intent.action}")
                AdhanScheduler.rearm(context)
            }

            // Anything else is the poke Dart sends after writing a new
            // schedule or changing a setting. The intent is explicit, so it
            // reaches us whatever action it carries.
            else -> AdhanScheduler.rearm(context)
        }
    }

    private fun startAdhan(context: Context, prayerIndex: Int, mode: String) {
        val service = Intent(context, AdhanService::class.java)
            .setAction(AdhanService.ACTION_PLAY)
            .putExtra(AdhanService.EXTRA_PRAYER, prayerIndex)
            .putExtra(AdhanService.EXTRA_MODE, mode)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(service)
            } else {
                context.startService(service)
            }
        } catch (e: Exception) {
            // A blocked foreground start must not take the re-arm down with it.
            Log.e(TAG, "could not start AdhanService: $e")
        }
    }
}
