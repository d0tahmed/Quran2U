package com.quran2u.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log

/**
 * Plays the adhan.
 *
 * WHY A FOREGROUND SERVICE AND NOT A NOTIFICATION SOUND
 * -----------------------------------------------------
 * A notification sound is truncated by most OEM builds at around thirty
 * seconds, is silenced by Do Not Disturb, plays on the notification stream,
 * and cannot offer a Stop button. This adhan is four minutes long. None of
 * those constraints are survivable, so the audio is played by a service we
 * control from start to finish.
 *
 * STREAM_ALARM IS THE POINT
 * -------------------------
 * Audio is routed with USAGE_ALARM, so it plays at alarm volume and is heard
 * when the ringer is silent. That is the behaviour someone is asking for when
 * they switch an adhan on — if it could be silenced by the ringer it would be
 * useless at Fajr, which is the one that matters most.
 *
 * A wake lock covers the gap between the alarm waking the CPU and playback
 * actually starting; without it the device can return to sleep mid-adhan.
 */
class AdhanService : Service() {

    companion object {
        const val ACTION_PLAY = "com.quran2u.app.ADHAN_PLAY"
        const val ACTION_STOP = "com.quran2u.app.ADHAN_STOP"
        const val EXTRA_PRAYER = "prayer"
        const val EXTRA_MODE = "mode"

        private const val TAG = "AdhanService"
        private const val CHANNEL_ID = "adhan_channel"
        private const val NOTIFICATION_ID = 7701

        /** Hard ceiling, in case a malformed asset never reports completion. */
        private const val MAX_MILLIS = 7 * 60 * 1000L
    }

    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopEverything()
                return START_NOT_STICKY
            }
        }

        val prayerIndex = intent?.getIntExtra(EXTRA_PRAYER, 0) ?: 0
        val mode = intent?.getStringExtra(EXTRA_MODE) ?: AdhanScheduler.MODE_FULL
        val label = AdhanScheduler.LABELS.getOrElse(prayerIndex) { "Prayer" }

        // Must happen within a few seconds of the service starting or Android
        // kills it, so it comes before anything that can be slow.
        startInForeground(label, playing = mode == AdhanScheduler.MODE_FULL)

        if (mode == AdhanScheduler.MODE_FULL) {
            acquireWakeLock()
            play()
        } else {
            // Silent mode: the notification alone is the whole point, so leave
            // it posted and let the service go.
            stopSelf()
        }

        // Do not let Android resurrect this with a null intent after a kill —
        // an adhan that starts an hour late is worse than one that is missed.
        return START_NOT_STICKY
    }

    // ── Playback ─────────────────────────────────────────────────────────

    private fun play() {
        stopPlayer()

        try {
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val mp = MediaPlayer()
            mp.setAudioAttributes(attributes)

            resources.openRawResourceFd(R.raw.adhan).use { fd ->
                mp.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
            }

            mp.isLooping = false
            mp.setOnCompletionListener {
                Log.d(TAG, "adhan finished")
                stopEverything()
            }
            mp.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                stopEverything()
                true
            }
            mp.setOnPreparedListener { it.start() }
            mp.prepareAsync()

            player = mp
        } catch (e: Exception) {
            Log.e(TAG, "playback failed: $e")
            stopEverything()
        }
    }

    private fun stopPlayer() {
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (e: Exception) {
            }
            try {
                it.release()
            } catch (e: Exception) {
            }
        }
        player = null
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK, "Quran2U:adhan"
            ).apply { acquire(MAX_MILLIS) }
        } catch (e: Exception) {
            Log.w(TAG, "wake lock unavailable: $e")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (e: Exception) {
        }
        wakeLock = null
    }

    private fun stopEverything() {
        stopPlayer()
        releaseWakeLock()
        stopForegroundCompat()
        stopSelf()
    }

    override fun onDestroy() {
        stopPlayer()
        releaseWakeLock()
        super.onDestroy()
    }

    // ── Notification ─────────────────────────────────────────────────────

    private fun startInForeground(label: String, playing: Boolean) {
        createChannel()

        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(
                this, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val stop = PendingIntent.getService(
            this, 1,
            Intent(this, AdhanService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("$label — time for prayer")
            .setContentText(if (playing) "Adhan is playing" else "It is time for $label")
            .setOngoing(playing)
            .setAutoCancel(!playing)
            .setCategory(Notification.CATEGORY_ALARM)
        open?.let { builder.setContentIntent(it) }

        if (playing) {
            builder.addAction(
                Notification.Action.Builder(
                    null, "Stop", stop
                ).build()
            )
        }

        val notification = builder.build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed: $e")
        }
    }

    private fun stopForegroundCompat() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(Service.STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (e: Exception) {
        }
    }

    /**
     * The channel is created with the alarm usage and IMPORTANCE_HIGH, but
     * with its own sound disabled — the service owns playback, and letting the
     * channel play a sound too would double the adhan.
     */
    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Adhan",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "The call to prayer at each prayer time"
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    /** Kept for reference: the stream the adhan is routed to. */
    @Suppress("unused")
    private fun alarmStream(): Int = AudioManager.STREAM_ALARM
}
