package id.alienai.remote.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import id.alienai.remote.bridge.NativeBridge
import id.alienai.remote.service.AccessControlService
import id.alienai.remote.service.OverlayMarkerService
import id.alienai.remote.service.RemoteAgentService

class MainActivity : AppCompatActivity() {

    private lateinit var statusText: TextView
    private lateinit var accessibilityStatus: TextView
    private lateinit var projectionStatus: TextView
    private lateinit var batteryStatus: TextView
    private lateinit var overlayStatus: TextView
    private lateinit var controlSwitch: SwitchCompat

    private val projectionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK && result.data != null) {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val projection = projectionManager.getMediaProjection(result.resultCode, result.data!!)

            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(metrics)

            RemoteAgentService.instance?.attachMediaProjection(
                projection,
                metrics.widthPixels,
                metrics.heightPixels,
                metrics.densityDpi
            )
            updateUiState()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Build clean programmatic UI without XML dependencies
        val root = ScrollView(this).apply {
            setBackgroundColor(0xFF0F172A.toInt())
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 64, 48, 64)
        }
        root.addView(container)
        setContentView(root)

        // Header Title
        val title = TextView(this).apply {
            text = "Alien Remote Agent"
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            paint.isFakeBoldText = true
        }
        container.addView(title)

        val deviceLabel = TextView(this).apply {
            text = "Device: ${Build.MANUFACTURER} ${Build.MODEL} (Android ${Build.VERSION.RELEASE})"
            textSize = 14f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 8, 0, 32)
        }
        container.addView(deviceLabel)

        // Status Card
        statusText = TextView(this).apply {
            text = "● Service: Checking..."
            textSize = 16f
            setTextColor(0xFF10B981.toInt())
            setPadding(0, 0, 0, 32)
        }
        container.addView(statusText)

        // Remote Control Toggle
        val controlRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 16, 0, 32)
        }
        val controlLabel = TextView(this).apply {
            text = "Allow Remote Control"
            textSize = 16f
            setTextColor(0xFFFFFFFF.toInt())
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        controlSwitch = SwitchCompat(this).apply {
            isChecked = NativeBridge.nativeIsControlAllowed()
            setOnCheckedChangeListener { _, isChecked ->
                NativeBridge.nativeSetControlAllowed(isChecked)
            }
        }
        controlRow.addView(controlLabel)
        controlRow.addView(controlSwitch)
        container.addView(controlRow)

        // Section: Permissions Checklist
        val permTitle = TextView(this).apply {
            text = "Permissions & Services"
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            paint.isFakeBoldText = true
            setPadding(0, 16, 0, 16)
        }
        container.addView(permTitle)

        // 1. Accessibility Service
        accessibilityStatus = createStatusRow(container, "Accessibility (Gestures & SoM)") {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        // 2. Screen Capture (MediaProjection)
        projectionStatus = createStatusRow(container, "Screen Capture (MediaProjection)") {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            projectionLauncher.launch(projectionManager.createScreenCaptureIntent())
        }

        // 3. Battery Optimization
        batteryStatus = createStatusRow(container, "Ignore Battery Optimizations") {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }

        // 4. Draw Over Apps (Visual Red Marker Overlay)
        overlayStatus = createStatusRow(container, "Visual Red Marker Overlay") {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }

        // Actions: Start Service Button
        val startBtn = Button(this).apply {
            text = "Start Agent Service"
            setBackgroundColor(0xFF10B981.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                RemoteAgentService.start(this@MainActivity)
                startService(Intent(this@MainActivity, OverlayMarkerService::class.java))
                updateUiState()
            }
        }
        container.addView(startBtn)

        // Unpair Button
        val unpairBtn = Button(this).apply {
            text = "Unpair Device"
            setBackgroundColor(0xFFEF4444.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                NativeBridge.nativeUnpair()
                updateUiState()
            }
        }
        container.addView(unpairBtn)

        // Auto-start remote agent service
        RemoteAgentService.start(this)
        if (Settings.canDrawOverlays(this)) {
            startService(Intent(this, OverlayMarkerService::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        updateUiState()
    }

    private fun createStatusRow(
        parent: LinearLayout,
        title: String,
        onClick: () -> Unit
    ): TextView {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 12, 0, 12)
        }
        val label = TextView(this).apply {
            text = title
            textSize = 14f
            setTextColor(0xFFCBD5E1.toInt())
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        val status = TextView(this).apply {
            text = "Check"
            textSize = 14f
            setPadding(16, 8, 16, 8)
            setOnClickListener { onClick() }
        }
        row.addView(label)
        row.addView(status)
        parent.addView(row)
        return status
    }

    private fun updateUiState() {
        // Accessibility status
        val isA11yOn = AccessControlService.isServiceRunning.get()
        accessibilityStatus.text = if (isA11yOn) "Granted ✓" else "Enable >"
        accessibilityStatus.setTextColor(if (isA11yOn) 0xFF10B981.toInt() else 0xFFEF4444.toInt())

        // Battery optimization
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val isBatteryExempt = powerManager.isIgnoringBatteryOptimizations(packageName)
        batteryStatus.text = if (isBatteryExempt) "Exempt ✓" else "Exempt >"
        batteryStatus.setTextColor(if (isBatteryExempt) 0xFF10B981.toInt() else 0xFFF59E0B.toInt())

        // Overlay status
        val canOverlay = Settings.canDrawOverlays(this)
        overlayStatus.text = if (canOverlay) "Granted ✓" else "Grant >"
        overlayStatus.setTextColor(if (canOverlay) 0xFF10B981.toInt() else 0xFFF59E0B.toInt())

        // Agent Service status
        val isServiceRunning = RemoteAgentService.instance != null
        statusText.text = if (isServiceRunning) "● Service Active" else "○ Service Stopped"
        statusText.setTextColor(if (isServiceRunning) 0xFF10B981.toInt() else 0xFF94A3B8.toInt())
    }
}
