package id.alienai.remote.ui

import id.alienai.remote.R
import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import id.alienai.remote.bridge.AgentStatus
import id.alienai.remote.bridge.NativeBridge
import id.alienai.remote.bridge.RemoteStorageBridge
import id.alienai.remote.service.AccessControlService
import id.alienai.remote.service.OverlayMarkerService
import id.alienai.remote.service.RemoteAgentService
import org.json.JSONObject

class MainActivity : AppCompatActivity() {

    private val handler = Handler(Looper.getMainLooper())

    // Tabs
    private var activeTab = 0 // 0 = Status, 1 = Logs
    private lateinit var tabStatusBtn: TextView
    private lateinit var tabLogsBtn: TextView
    private lateinit var tabStatusIndicator: View
    private lateinit var tabLogsIndicator: View
    private lateinit var statusContainer: LinearLayout
    private lateinit var logsContainer: LinearLayout

    // Unpaired UI Elements
    private lateinit var pairingCardLayout: LinearLayout
    private lateinit var pinContainer: LinearLayout
    private lateinit var copyPinBtn: Button
    private lateinit var refreshTimerText: TextView
    private lateinit var refreshProgressBar: ProgressBar

    // Paired UI Elements
    private lateinit var pairedCardLayout: LinearLayout
    private lateinit var cloudStatusDot: TextView
    private lateinit var cloudStatusText: TextView
    private lateinit var deviceNameLabel: TextView
    private lateinit var ownerHandleLabel: TextView
    private lateinit var viewerBadgeText: TextView
    private lateinit var controlSwitch: SwitchCompat
    private lateinit var driveSwitch: SwitchCompat
    private lateinit var unpairHeaderBtn: TextView

    // Permissions Checklist
    private lateinit var a11yStatusChip: TextView
    private lateinit var projectionStatusChip: TextView
    private lateinit var batteryStatusChip: TextView
    private lateinit var overlayStatusChip: TextView

    // Logs UI Elements
    private lateinit var logsConsoleView: TextView
    private lateinit var copyLogsBtn: Button

    private val storageTreeLauncher = registerForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { uri ->
        if (uri != null) {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try {
                contentResolver.takePersistableUriPermission(uri, flags)
            } catch (_: SecurityException) {
            }
            val name = uri.lastPathSegment ?: "Folder"
            RemoteStorageBridge.addTreeGrant(uri, name)
            Toast.makeText(this, "Storage folder added for remote Files", Toast.LENGTH_SHORT).show()
            refreshStatusFromNative()
        }
    }

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
            updatePermissionsState()
        }
    }

    private val logRefreshRunnable = object : Runnable {
        override fun run() {
            if (!isFinishing) {
                refreshStatusFromNative()
                if (activeTab == 1) {
                    refreshLogs()
                }
            }
            handler.postDelayed(this, 2000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NativeBridge.appContext = applicationContext

        // Root View
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFF020617.toInt()) // Slate-950
        }
        setContentView(root)

        // 1. App Header (Title, Subtitle, Unpair)
        setupHeader(root)

        // 2. Tab Bar ([ Status ] | [ Logs ])
        setupTabBar(root)

        // 3. Tab Content Container (ScrollView)
        val contentScroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            isFillViewport = true
        }
        root.addView(contentScroll)

        val mainContent = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(40, 32, 40, 48)
        }
        contentScroll.addView(mainContent)

        // Status Tab Content
        statusContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        mainContent.addView(statusContainer)

        setupUnpairedView(statusContainer)
        setupPairedView(statusContainer)
        setupPermissionsChecklist(statusContainer)

        // Logs Tab Content
        logsContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
        }
        mainContent.addView(logsContainer)
        setupLogsView(logsContainer)

        // Start agent background service & overlay
        RemoteAgentService.start(this)
        if (Settings.canDrawOverlays(this)) {
            startService(Intent(this, OverlayMarkerService::class.java))
        }

        // Connect status update listener
        RemoteAgentService.onStatusUpdateListener = { status ->
            runOnUiThread { applyStatusToUi(status) }
        }
    }

    override fun onResume() {
        super.onResume()
        updatePermissionsState()
        refreshStatusFromNative()
        handler.post(logRefreshRunnable)
    }

    override fun onPause() {
        super.onPause()
        handler.removeCallbacks(logRefreshRunnable)
    }

    // -------------------------------------------------------------------------
    // Header & Tabs
    // -------------------------------------------------------------------------

    private fun setupHeader(parent: LinearLayout) {
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(0xFF0F172A.toInt()) // Slate-900
            setPadding(40, 36, 40, 36)
        }

        val appIcon = android.widget.ImageView(this).apply {
            setImageResource(R.drawable.ic_alien_remote)
            layoutParams = LinearLayout.LayoutParams(96, 96).apply {
                setMargins(0, 0, 24, 0)
            }
        }
        header.addView(appIcon)

        val titleCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }

        val title = TextView(this).apply {
            text = getString(R.string.app_name)
            textSize = 20f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
        }
        val subtitle = TextView(this).apply {
            text = "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE}"
            textSize = 12f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 4, 0, 0)
        }
        titleCol.addView(title)
        titleCol.addView(subtitle)
        header.addView(titleCol)

        unpairHeaderBtn = TextView(this).apply {
            text = "Unpair"
            textSize = 13f
            setTextColor(0xFFEF4444.toInt())
            background = createCardDrawable(0xFF1E293B.toInt(), 16f)
            setPadding(28, 14, 28, 14)
            visibility = View.GONE
            setOnClickListener {
                NativeBridge.nativeUnpair()
                Toast.makeText(this@MainActivity, "Unpairing device…", Toast.LENGTH_SHORT).show()
            }
        }
        header.addView(unpairHeaderBtn)
        parent.addView(header)
    }

    private fun setupTabBar(parent: LinearLayout) {
        val tabRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(0xFF0F172A.toInt())
        }

        // Status Tab Button
        val statusTabFrame = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            gravity = Gravity.CENTER
            setOnClickListener { selectTab(0) }
        }
        tabStatusBtn = TextView(this).apply {
            text = "Status"
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 24, 0, 20)
        }
        tabStatusIndicator = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 6)
            setBackgroundColor(0xFF10B981.toInt()) // Emerald
        }
        statusTabFrame.addView(tabStatusBtn)
        statusTabFrame.addView(tabStatusIndicator)

        // Logs Tab Button
        val logsTabFrame = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            gravity = Gravity.CENTER
            setOnClickListener { selectTab(1) }
        }
        tabLogsBtn = TextView(this).apply {
            text = "Logs"
            textSize = 14f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 24, 0, 20)
        }
        tabLogsIndicator = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 6)
            setBackgroundColor(Color.TRANSPARENT)
        }
        logsTabFrame.addView(tabLogsBtn)
        logsTabFrame.addView(tabLogsIndicator)

        tabRow.addView(statusTabFrame)
        tabRow.addView(logsTabFrame)
        parent.addView(tabRow)
    }

    private fun selectTab(tab: Int) {
        activeTab = tab
        if (tab == 0) {
            tabStatusBtn.setTextColor(Color.WHITE)
            tabStatusBtn.typeface = Typeface.DEFAULT_BOLD
            tabStatusIndicator.setBackgroundColor(0xFF10B981.toInt())

            tabLogsBtn.setTextColor(0xFF94A3B8.toInt())
            tabLogsBtn.typeface = Typeface.DEFAULT
            tabLogsIndicator.setBackgroundColor(Color.TRANSPARENT)

            statusContainer.visibility = View.VISIBLE
            logsContainer.visibility = View.GONE
        } else {
            tabStatusBtn.setTextColor(0xFF94A3B8.toInt())
            tabStatusBtn.typeface = Typeface.DEFAULT
            tabStatusIndicator.setBackgroundColor(Color.TRANSPARENT)

            tabLogsBtn.setTextColor(Color.WHITE)
            tabLogsBtn.typeface = Typeface.DEFAULT_BOLD
            tabLogsIndicator.setBackgroundColor(0xFF10B981.toInt())

            statusContainer.visibility = View.GONE
            logsContainer.visibility = View.VISIBLE
            refreshLogs()
        }
    }

    // -------------------------------------------------------------------------
    // Unpaired View (Segmented PIN Card matching Windows pair_window.rs)
    // -------------------------------------------------------------------------

    private fun setupUnpairedView(parent: LinearLayout) {
        pairingCardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 24f)
            setPadding(40, 48, 40, 48)
            gravity = Gravity.CENTER_HORIZONTAL
        }

        val hint = TextView(this).apply {
            text = "Enter this code in Alien AI app\nDevice → Pair with Code"
            textSize = 14f
            setTextColor(0xFFCBD5E1.toInt())
            gravity = Gravity.CENTER
            setLineSpacing(6f, 1f)
        }
        pairingCardLayout.addView(hint)

        // PIN Blocks Row
        pinContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, 36, 0, 36)
        }
        pairingCardLayout.addView(pinContainer)

        // Copy Button
        copyPinBtn = Button(this).apply {
            text = "Copy Code"
            textSize = 13f
            setTextColor(Color.WHITE)
            background = createCardDrawable(0xFF334155.toInt(), 16f)
            setPadding(48, 16, 48, 16)
            setOnClickListener {
                val code = RemoteAgentService.instance?.latestStatus?.pairing_code ?: ""
                if (code.isNotEmpty()) {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("Pairing Code", code))
                    copyPinBtn.text = "Copied!"
                    copyPinBtn.setTextColor(0xFF10B981.toInt())
                    handler.postDelayed({
                        copyPinBtn.text = "Copy Code"
                        copyPinBtn.setTextColor(Color.WHITE)
                    }, 2000)
                }
            }
        }
        pairingCardLayout.addView(copyPinBtn)

        // Countdown Timer
        refreshTimerText = TextView(this).apply {
            text = "Code Refresh in 5:00"
            textSize = 12f
            setTextColor(0xFF64748B.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 8)
        }
        pairingCardLayout.addView(refreshTimerText)

        refreshProgressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            layoutParams = LinearLayout.LayoutParams(400, 8).apply { gravity = Gravity.CENTER }
            max = 300
            progress = 300
        }
        pairingCardLayout.addView(refreshProgressBar)

        parent.addView(pairingCardLayout)
    }

    private fun renderPinBlocks(code: String) {
        pinContainer.removeAllViews()
        val cleanCode = code.ifEmpty { "------" }

        for (c in cleanCode) {
            val tv = TextView(this).apply {
                text = c.toString()
                textSize = 22f
                typeface = Typeface.MONOSPACE
                setTextColor(if (c == '-') 0xFF64748B.toInt() else 0xFF10B981.toInt())
                gravity = Gravity.CENTER
                if (c != '-') {
                    background = createCardDrawable(0xFF0F172A.toInt(), 12f)
                    layoutParams = LinearLayout.LayoutParams(68, 88).apply {
                        setMargins(6, 0, 6, 0)
                    }
                } else {
                    layoutParams = LinearLayout.LayoutParams(32, 88).apply {
                        setMargins(4, 0, 4, 0)
                    }
                }
            }
            pinContainer.addView(tv)
        }
    }

    // -------------------------------------------------------------------------
    // Paired View (Status cards matching agent_status_window.rs)
    // -------------------------------------------------------------------------

    private fun setupPairedView(parent: LinearLayout) {
        pairedCardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            visibility = View.GONE
        }

        // Cloud Connection Status Row
        val statusHeaderRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(8, 0, 8, 24)
        }
        cloudStatusDot = TextView(this).apply {
            text = "●"
            textSize = 16f
            setTextColor(0xFF10B981.toInt()) // Emerald
            setPadding(0, 0, 12, 0)
        }
        cloudStatusText = TextView(this).apply {
            text = "Online (Connected to Alien AI Cloud)"
            textSize = 14f
            setTextColor(0xFFF1F5F9.toInt())
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        viewerBadgeText = TextView(this).apply {
            text = "0 viewers"
            textSize = 12f
            setTextColor(0xFF94A3B8.toInt())
            background = createCardDrawable(0xFF1E293B.toInt(), 12f)
            setPadding(20, 8, 20, 8)
        }
        statusHeaderRow.addView(cloudStatusDot)
        statusHeaderRow.addView(cloudStatusText)
        statusHeaderRow.addView(viewerBadgeText)
        pairedCardLayout.addView(statusHeaderRow)

        // Two Grid Cards: Device Card & Account Card
        val cardsRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 0, 0, 24)
        }

        // Card 1: Device
        val cardDevice = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 20f)
            setPadding(28, 24, 28, 24)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                setMargins(0, 0, 12, 0)
            }
        }
        val devTitle = TextView(this).apply {
            text = "DEVICE"
            textSize = 11f
            setTextColor(0xFF64748B.toInt())
            typeface = Typeface.DEFAULT_BOLD
        }
        deviceNameLabel = TextView(this).apply {
            text = Build.MODEL
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 8, 0, 0)
        }
        cardDevice.addView(devTitle)
        cardDevice.addView(deviceNameLabel)

        // Card 2: Account
        val cardAccount = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 20f)
            setPadding(28, 24, 28, 24)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                setMargins(12, 0, 0, 0)
            }
        }
        val accTitle = TextView(this).apply {
            text = "ACCOUNT"
            textSize = 11f
            setTextColor(0xFF64748B.toInt())
            typeface = Typeface.DEFAULT_BOLD
        }
        ownerHandleLabel = TextView(this).apply {
            text = "@owner"
            textSize = 14f
            setTextColor(0xFF10B981.toInt())
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, 8, 0, 0)
        }
        cardAccount.addView(accTitle)
        cardAccount.addView(ownerHandleLabel)

        cardsRow.addView(cardDevice)
        cardsRow.addView(cardAccount)
        pairedCardLayout.addView(cardsRow)

        // Remote Control Toggle Card
        val controlCard = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 20f)
            setPadding(32, 28, 32, 28)
        }
        val controlLabel = TextView(this).apply {
            text = "Allow Remote Control"
            textSize = 15f
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        controlSwitch = SwitchCompat(this).apply {
            isChecked = NativeBridge.nativeIsControlAllowed()
            setOnCheckedChangeListener { _, isChecked ->
                NativeBridge.nativeSetControlAllowed(isChecked)
            }
        }
        controlCard.addView(controlLabel)
        controlCard.addView(controlSwitch)
        pairedCardLayout.addView(controlCard)

        val driveCard = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 20f)
            setPadding(32, 28, 32, 28)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 16, 0, 0) }
        }
        val driveLabel = TextView(this).apply {
            text = "Alien AI Drive"
            textSize = 15f
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        val driveHint = TextView(this).apply {
            text = "Sync cloud files to this device (Files app: Alien AI)."
            textSize = 11f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 4, 0, 0)
        }
        val driveTextCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        driveTextCol.addView(driveLabel)
        driveTextCol.addView(driveHint)
        driveSwitch = SwitchCompat(this).apply {
            isChecked = NativeBridge.nativeIsDriveEnabled()
            setOnCheckedChangeListener { _, isChecked ->
                NativeBridge.nativeSetDriveEnabled(isChecked)
            }
        }
        driveCard.addView(driveTextCol)
        driveCard.addView(driveSwitch)
        pairedCardLayout.addView(driveCard)

        val storageCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 20f)
            setPadding(32, 24, 32, 24)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 16, 0, 0) }
        }
        val storageTitle = TextView(this).apply {
            text = "Remote Files access"
            textSize = 15f
            setTextColor(Color.WHITE)
        }
        val storageHint = TextView(this).apply {
            text = "Grant folders for Alien AI Files tab and device.fs tools."
            textSize = 12f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 8, 0, 16)
        }
        val addFolderBtn = Button(this).apply {
            text = "Add storage folder"
            setOnClickListener { storageTreeLauncher.launch(null) }
        }
        storageCard.addView(storageTitle)
        storageCard.addView(storageHint)
        storageCard.addView(addFolderBtn)
        pairedCardLayout.addView(storageCard)

        parent.addView(pairedCardLayout)
    }

    // -------------------------------------------------------------------------
    // Permissions Checklist
    // -------------------------------------------------------------------------

    private fun setupPermissionsChecklist(parent: LinearLayout) {
        val permSection = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, 32, 0, 0)
        }

        val sectionTitle = TextView(this).apply {
            text = "SYSTEM PERMISSIONS"
            textSize = 11f
            setTextColor(0xFF64748B.toInt())
            typeface = Typeface.DEFAULT_BOLD
            setPadding(8, 0, 0, 16)
        }
        permSection.addView(sectionTitle)

        // 1. Accessibility
        a11yStatusChip = createChecklistRow(permSection, "Accessibility Service", "Gestures & UI tree") {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        // 2. Screen Capture
        projectionStatusChip = createChecklistRow(permSection, "Screen Capture", "MediaProjection stream") {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            projectionLauncher.launch(projectionManager.createScreenCaptureIntent())
        }

        // 3. Battery Exemption
        batteryStatusChip = createChecklistRow(permSection, "Battery Optimization", "Ignore Doze standby") {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }

        // 4. Overlay Marker
        overlayStatusChip = createChecklistRow(permSection, "Display Over Other Apps", "Visual tap marker") {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }

        parent.addView(permSection)
    }

    private fun createChecklistRow(
        parent: LinearLayout,
        title: String,
        subtitle: String,
        onClick: () -> Unit
    ): TextView {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = createCardDrawable(0xFF1E293B.toInt(), 16f)
            setPadding(28, 20, 28, 20)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(0, 0, 0, 12) }
            setOnClickListener { onClick() }
        }

        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        val t = TextView(this).apply {
            text = title
            textSize = 14f
            setTextColor(Color.WHITE)
        }
        val sub = TextView(this).apply {
            text = subtitle
            textSize = 11f
            setTextColor(0xFF94A3B8.toInt())
            setPadding(0, 2, 0, 0)
        }
        col.addView(t)
        col.addView(sub)
        row.addView(col)

        val badge = TextView(this).apply {
            text = "Grant >"
            textSize = 12f
            setTextColor(0xFFF59E0B.toInt())
            setPadding(16, 8, 16, 8)
        }
        row.addView(badge)
        parent.addView(row)
        return badge
    }

    // -------------------------------------------------------------------------
    // Logs Tab (Monospace Dark Console matching Windows agent)
    // -------------------------------------------------------------------------

    private fun setupLogsView(parent: LinearLayout) {
        val btnRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            setPadding(0, 0, 0, 16)
        }

        val refreshBtn = Button(this).apply {
            text = "Refresh"
            textSize = 12f
            setTextColor(Color.WHITE)
            background = createCardDrawable(0xFF1E293B.toInt(), 12f)
            setOnClickListener { refreshLogs() }
        }
        copyLogsBtn = Button(this).apply {
            text = "Copy Logs"
            textSize = 12f
            setTextColor(0xFF10B981.toInt())
            background = createCardDrawable(0xFF1E293B.toInt(), 12f)
            setOnClickListener {
                val text = logsConsoleView.text.toString()
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("Agent Logs", text))
                Toast.makeText(this@MainActivity, "Logs copied to clipboard", Toast.LENGTH_SHORT).show()
            }
        }
        btnRow.addView(refreshBtn)
        btnRow.addView(copyLogsBtn)
        parent.addView(btnRow)

        val consoleScroll = HorizontalScrollView(this)
        logsConsoleView = TextView(this).apply {
            text = "Loading logs…"
            textSize = 11f
            typeface = Typeface.MONOSPACE
            setTextColor(0xFFE2E8F0.toInt())
            setBackgroundColor(0xFF0F172A.toInt())
            setPadding(28, 28, 28, 28)
            setLineSpacing(4f, 1f)
            background = createCardDrawable(0xFF0F172A.toInt(), 16f)
        }
        consoleScroll.addView(logsConsoleView)
        parent.addView(consoleScroll)
    }

    private fun refreshLogs() {
        val lines = NativeBridge.nativeGetLogTail(60)
        if (lines.isNotEmpty()) {
            logsConsoleView.text = lines.joinToString("\n")
        } else {
            logsConsoleView.text = "No log records available yet."
        }
    }

    private fun refreshStatusFromNative() {
        try {
            val json = JSONObject(NativeBridge.nativeGetStatusJson())
            applyStatusToUi(
                AgentStatus(
                    paired = json.optBoolean("paired", false),
                    online = json.optBoolean("online", false),
                    status = json.optString("status", ""),
                    pairing_code = json.optString("pairing_code", ""),
                    pairing_seconds_remaining = json.optLong("pairing_seconds_remaining", 0),
                    owner_label = json.optString("owner_label", ""),
                    device_name = json.optString("device_name", ""),
                    package_name = json.optString("package_name", ""),
                    active_viewers = json.optInt("active_viewers", 0),
                )
            )
        } catch (_: Exception) {
        }
    }

    // -------------------------------------------------------------------------
    // Status & Permissions Binding
    // -------------------------------------------------------------------------

    private fun applyStatusToUi(status: AgentStatus) {
        if (!status.paired) {
            pairingCardLayout.visibility = View.VISIBLE
            pairedCardLayout.visibility = View.GONE
            unpairHeaderBtn.visibility = View.GONE

            renderPinBlocks(status.pairing_code)
            val sec = status.pairing_seconds_remaining
            refreshTimerText.text = "Code Refresh in ${sec / 60}:${String.format("%02d", sec % 60)}"
            refreshProgressBar.progress = sec.toInt().coerceIn(0, 300)
        } else {
            pairingCardLayout.visibility = View.GONE
            pairedCardLayout.visibility = View.VISIBLE
            unpairHeaderBtn.visibility = View.VISIBLE

            deviceNameLabel.text = status.device_name.ifEmpty { Build.MODEL }
            ownerHandleLabel.text = status.owner_label.ifEmpty { "@owner" }
            viewerBadgeText.text = "${status.active_viewers} viewers"

            if (status.online) {
                cloudStatusDot.setTextColor(0xFF10B981.toInt())
                cloudStatusText.text = "Online (Connected to Alien AI Cloud)"
            } else {
                cloudStatusDot.setTextColor(0xFFF59E0B.toInt())
                cloudStatusText.text = status.status.ifEmpty { "Reconnecting…" }
            }
        }
    }

    private fun updatePermissionsState() {
        // 1. Accessibility
        val isA11y = AccessControlService.isServiceRunning.get()
        a11yStatusChip.text = if (isA11y) "Active ✓" else "Enable >"
        a11yStatusChip.setTextColor(if (isA11y) 0xFF10B981.toInt() else 0xFFEF4444.toInt())

        // 2. Battery
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val isBatteryExempt = pm.isIgnoringBatteryOptimizations(packageName)
        batteryStatusChip.text = if (isBatteryExempt) "Exempt ✓" else "Grant >"
        batteryStatusChip.setTextColor(if (isBatteryExempt) 0xFF10B981.toInt() else 0xFFF59E0B.toInt())

        // 3. Overlay
        val canOverlay = Settings.canDrawOverlays(this)
        overlayStatusChip.text = if (canOverlay) "Granted ✓" else "Grant >"
        overlayStatusChip.setTextColor(if (canOverlay) 0xFF10B981.toInt() else 0xFFF59E0B.toInt())
    }

    private fun createCardDrawable(color: Int, radius: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
        }
    }
}
