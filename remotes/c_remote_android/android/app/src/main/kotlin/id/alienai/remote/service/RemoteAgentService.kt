package id.alienai.remote.service

import android.accessibilityservice.AccessibilityService
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.media.projection.MediaProjection
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.Display
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import id.alienai.remote.R
import id.alienai.remote.bridge.AgentStatus
import id.alienai.remote.bridge.NativeBridge
import id.alienai.remote.bridge.RustCallback
import id.alienai.remote.ui.MainActivity
import org.json.JSONObject
import java.io.File

class RemoteAgentService : Service(), RustCallback {

    companion object {
        private const val TAG = "RemoteAgentService"
        private const val NOTIFICATION_ID = 3501
        private const val CHANNEL_ID = "alien_remote_agent_channel"

        var instance: RemoteAgentService? = null
            private set

        var onStatusUpdateListener: ((AgentStatus) -> Unit)? = null

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
    private var activeMediaProjection: MediaProjection? = null
    private var displayManager: DisplayManager? = null

    var latestStatus = AgentStatus()
        private set

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
        override fun onDisplayChanged(displayId: Int) {
            if (displayId == Display.DEFAULT_DISPLAY) {
                handleOrientationChange()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        NativeBridge.appContext = applicationContext
        instance = this
        startForeground(NOTIFICATION_ID, createNotification())
        acquireWakeLock()
        initRustCore()

        displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayManager?.registerDisplayListener(displayListener, null)
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
        activeMediaProjection = projection
        projectionService?.stop()
        projectionService = ProjectionService(projection, width, height, dpi).apply {
            start()
        }
    }

    private fun handleOrientationChange() {
        val projection = activeMediaProjection ?: return
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        wm.defaultDisplay.getRealMetrics(metrics)

        Log.i(TAG, "Display rotated: re-anchoring projection to ${metrics.widthPixels}x${metrics.heightPixels}")
        projectionService?.stop()
        projectionService = ProjectionService(
            projection,
            metrics.widthPixels,
            metrics.heightPixels,
            metrics.densityDpi
        ).apply {
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
                Log.d(TAG, "Unhandled input event: $eventType")
            }
        }
    }

    override fun onStatusChanged(statusJson: String) {
        try {
            val json = JSONObject(statusJson)
            latestStatus = AgentStatus(
                paired = json.optBoolean("paired", false),
                online = json.optBoolean("online", false),
                status = json.optString("status", ""),
                pairing_code = json.optString("pairing_code", ""),
                pairing_seconds_remaining = json.optLong("pairing_seconds_remaining", 0),
                owner_label = json.optString("owner_label", ""),
                device_name = json.optString("device_name", ""),
                package_name = json.optString("package_name", ""),
                active_viewers = json.optInt("active_viewers", 0)
            )
            onStatusUpdateListener?.invoke(latestStatus)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse status JSON: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        displayManager?.unregisterDisplayListener(displayListener)
        projectionService?.stop()
        projectionService = null
        activeMediaProjection = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        if (instance == this) {
            instance = null
        }
    }
}
