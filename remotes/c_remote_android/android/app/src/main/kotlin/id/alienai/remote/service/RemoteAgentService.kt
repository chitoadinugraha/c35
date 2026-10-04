package id.alienai.remote.service

import android.accessibilityservice.AccessibilityService
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import id.alienai.remote.R
import id.alienai.remote.bridge.NativeBridge
import id.alienai.remote.bridge.RustCallback
import id.alienai.remote.ui.MainActivity
import java.io.File

class RemoteAgentService : Service(), RustCallback {

    companion object {
        private const val TAG = "RemoteAgentService"
        private const val NOTIFICATION_ID = 3501
        private const val CHANNEL_ID = "alien_remote_agent_channel"

        var instance: RemoteAgentService? = null
            private set

        fun start(context: Context) {
            val intent = Intent(context, RemoteAgentService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var projectionService: ProjectionService? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        startForeground(NOTIFICATION_ID, createNotification())
        acquireWakeLock()
        initRustCore()
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_desc)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AlienRemote:AgentWakeLock"
        ).apply {
            acquire(24 * 60 * 60 * 1000L) // 24 hours max
        }
    }

    private fun initRustCore() {
        val dataDir = File(filesDir, "alien_remote").apply { mkdirs() }.absolutePath
        val deviceName = "${Build.MANUFACTURER} ${Build.MODEL}"
        val serverUrl = "https://alienai.id"

        NativeBridge.nativeInit(
            serverUrl = serverUrl,
            dataDir = dataDir,
            deviceName = deviceName,
            callback = this
        )
        Log.i(TAG, "Rust core initialized for device '$deviceName'")
    }

    fun attachMediaProjection(projection: MediaProjection, width: Int, height: Int, dpi: Int) {
        projectionService?.stop()
        projectionService = ProjectionService(projection, width, height, dpi).apply {
            start()
        }
    }

    override fun onRemoteInput(
        eventType: String,
        x: Double,
        y: Double,
        text: String,
        button: Int,
        keyCode: Int
    ) {
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(metrics)

        val px = (x.coerceIn(0.0, 1.0) * metrics.widthPixels).toFloat()
        val py = (y.coerceIn(0.0, 1.0) * metrics.heightPixels).toFloat()

        when (eventType) {
            "mouse_down", "click", "tap" -> {
                AccessControlService.instance?.dispatchTap(px, py)
                OverlayMarkerService.instance?.showTap(px, py)
            }
            "type_text" -> {
                AccessControlService.instance?.typeText(text)
            }
            "back" -> {
                AccessControlService.instance?.performGlobal(AccessibilityService.GLOBAL_ACTION_BACK)
            }
            "home" -> {
                AccessControlService.instance?.performGlobal(AccessibilityService.GLOBAL_ACTION_HOME)
            }
            "recents" -> {
                AccessControlService.instance?.performGlobal(AccessibilityService.GLOBAL_ACTION_RECENTS)
            }
            "notifications" -> {
                AccessControlService.instance?.performGlobal(AccessibilityService.GLOBAL_ACTION_NOTIFICATIONS)
            }
            else -> {
                Log.d(TAG, "Unhandled input event type: $eventType")
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        projectionService?.stop()
        projectionService = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        if (instance == this) {
            instance = null
        }
    }
}
