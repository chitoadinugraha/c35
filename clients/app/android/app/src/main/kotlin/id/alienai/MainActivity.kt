package id.alienai

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THERMAL_BT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bluetoothEnabled" -> result.success(ThermalBluetoothPrint.bluetoothEnabled())
                "pairedDevices" -> result.success(ThermalBluetoothPrint.pairedDevices())
                "printBytes" -> {
                    val mac = call.argument<String>("mac") ?: ""
                    @Suppress("UNCHECKED_CAST")
                    val raw = call.argument<ByteArray>("bytes")
                        ?: (call.argument<List<Int>>("bytes")?.map { (it and 0xFF).toByte() }?.toByteArray())
                    if (raw == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val ok = ThermalBluetoothPrint.printBytes(applicationContext, mac, raw)
                        runOnUiThread { result.success(ok) }
                    }.start()
                }
                "disconnect" -> {
                    ThermalBluetoothPrint.disconnect()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canInstallApk" -> result.success(ApkUpdateInstaller.canInstall(applicationContext))
                "openInstallPermissionSettings" -> {
                    ApkUpdateInstaller.openInstallPermissionSettings(this)
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path") ?: ""
                    val ok = ApkUpdateInstaller.install(this, File(path))
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pinPos" -> {
                    val uri = call.argument<String>("uri")
                    val label = call.argument<String>("label")
                    val id = call.argument<String>("id")
                    if (uri == null || label == null || id == null) {
                        result.error("arg", "missing", null)
                        return@setMethodCallHandler
                    }
                    val iconPath = call.argument<String>("iconPath")
                    val iconPng = byteArrayArg(call, "iconPng")
                    pinPos(uri, label, id, iconPath, iconPng, result)
                }
                "updatePosShortcut" -> {
                    val uri = call.argument<String>("uri")
                    val label = call.argument<String>("label")
                    val id = call.argument<String>("id")
                    if (uri == null || label == null || id == null) {
                        result.error("arg", "missing", null)
                        return@setMethodCallHandler
                    }
                    val iconPath = call.argument<String>("iconPath")
                    val iconPng = byteArrayArg(call, "iconPng")
                    updatePosShortcut(uri, label, id, iconPath, iconPng, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pinPos(
        uri: String,
        label: String,
        id: String,
        iconPath: String?,
        iconPng: ByteArray?,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(mapOf("ok" to false))
            return
        }
        val sm = getSystemService(ShortcutManager::class.java)
        if (sm == null || !sm.isRequestPinShortcutSupported) {
            result.success(mapOf("ok" to false))
            return
        }
        if (sm.pinnedShortcuts.any { it.id == id }) {
            result.success(mapOf("ok" to true, "already_pinned" to true))
            return
        }
        val shortcut = buildPosShortcut(uri, label, id, iconPath, iconPng)
        try {
            sm.updateShortcuts(listOf(shortcut))
        } catch (_: Exception) {
        }
        sm.requestPinShortcut(shortcut, null)
        result.success(mapOf("ok" to true))
    }

    private fun updatePosShortcut(
        uri: String,
        label: String,
        id: String,
        iconPath: String?,
        iconPng: ByteArray?,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(mapOf("ok" to false))
            return
        }
        val sm = getSystemService(ShortcutManager::class.java) ?: run {
            result.success(mapOf("ok" to false))
            return
        }
        val pinned = sm.pinnedShortcuts.any { it.id == id }
        if (!pinned) {
            result.success(mapOf("ok" to false, "reason" to "not_pinned"))
            return
        }
        val shortcut = buildPosShortcut(uri, label, id, iconPath, iconPng)
        sm.updateShortcuts(listOf(shortcut))
        result.success(mapOf("ok" to true))
    }

    private fun buildPosShortcut(
        uri: String,
        label: String,
        id: String,
        iconPath: String?,
        iconPng: ByteArray?,
    ): ShortcutInfo {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).setPackage(packageName)
        val shortcutIcon = shortcutIcon(iconPath, iconPng)
        return ShortcutInfo.Builder(this, id)
            .setShortLabel(label)
            .setLongLabel(label)
            .setIcon(shortcutIcon)
            .setIntent(intent)
            .build()
    }

    private fun shortcutIcon(iconPath: String?, iconPng: ByteArray?): Icon {
        val maxPx = maxShortcutIconPx()
        if (!iconPath.isNullOrEmpty()) {
            val fromFile = decodeSampledBitmapFile(iconPath, maxPx)
            if (fromFile != null) {
                return Icon.createWithBitmap(fromFile)
            }
        }
        if (iconPng != null && iconPng.isNotEmpty()) {
            val bmp = decodeSampledBitmap(iconPng, maxPx)
            if (bmp != null) {
                return Icon.createWithBitmap(bmp)
            }
        }
        return Icon.createWithResource(this, R.mipmap.ic_launcher)
    }

    private fun maxShortcutIconPx(): Int {
        val dm = resources.displayMetrics
        return (108f * dm.density).toInt().coerceAtLeast(96)
    }

    private fun decodeSampledBitmap(bytes: ByteArray, maxPx: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val opts = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds, maxPx, maxPx)
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)?.let {
            scaleDownIfNeeded(it, maxPx)
        }
    }

    private fun decodeSampledBitmapFile(path: String, maxPx: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val opts = BitmapFactory.Options().apply {
            inSampleSize = calculateInSampleSize(bounds, maxPx, maxPx)
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(path, opts)?.let { scaleDownIfNeeded(it, maxPx) }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int,
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            var halfHeight = height / 2
            var halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize.coerceAtLeast(1)
    }

    private fun scaleDownIfNeeded(source: Bitmap, maxPx: Int): Bitmap {
        val maxEdge = maxOf(source.width, source.height)
        if (maxEdge <= maxPx) return source
        val scale = maxPx.toFloat() / maxEdge
        val w = (source.width * scale).toInt().coerceAtLeast(1)
        val h = (source.height * scale).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(source, w, h, true)
        if (scaled != source) source.recycle()
        return scaled
    }

    /** Flutter may send [Uint8List] as [ByteArray] or as [List] of ints (0-255). */
    private fun byteArrayArg(call: MethodCall, key: String): ByteArray? {
        when (val raw = call.argument<Any>(key)) {
            is ByteArray -> if (raw.isNotEmpty()) return raw
            is List<*> -> {
                if (raw.isEmpty()) return null
                return raw.map { ((it as Number).toInt() and 0xFF).toByte() }.toByteArray()
            }
        }
        return null
    }

    companion object {
        private const val CHANNEL = "id.alienai/pos_shortcut"
        private const val THERMAL_BT_CHANNEL = "id.alienai/thermal_bluetooth"
        private const val APP_UPDATE_CHANNEL = "id.alienai/app_update"
    }
}
