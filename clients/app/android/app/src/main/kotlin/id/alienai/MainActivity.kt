package id.alienai

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
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
                    val iconPng = byteArrayArg(call, "iconPng")
                    pinPos(uri, label, id, iconPng, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pinPos(uri: String, label: String, id: String, iconPng: ByteArray?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(mapOf("ok" to false))
            return
        }
        val sm = getSystemService(ShortcutManager::class.java)
        if (sm == null || !sm.isRequestPinShortcutSupported) {
            result.success(mapOf("ok" to false))
            return
        }
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).setPackage(packageName)
        val shortcutIcon = shortcutIcon(iconPng)
        val shortcut = ShortcutInfo.Builder(this, id)
            .setShortLabel(label)
            .setLongLabel(label)
            .setIcon(shortcutIcon)
            .setIntent(intent)
            .build()
        sm.requestPinShortcut(shortcut, null)
        result.success(mapOf("ok" to true))
    }

    private fun shortcutIcon(iconPng: ByteArray?): Icon {
        if (iconPng != null && iconPng.isNotEmpty()) {
            val bmp = BitmapFactory.decodeByteArray(iconPng, 0, iconPng.size)
            if (bmp != null) {
                // Pinned shortcut: use the composite bitmap as-is (site + badge), not adaptive launcher art.
                return Icon.createWithBitmap(bmp)
            }
        }
        return Icon.createWithResource(this, R.mipmap.ic_launcher)
    }

    /** Flutter may send [Uint8List] as [ByteArray] or as [List] of ints (0-255). */
    private fun byteArrayArg(call: MethodCall, key: String): ByteArray? {
        val direct = call.argument<ByteArray>(key)
        if (direct != null && direct.isNotEmpty()) return direct
        val asList = call.argument<List<Int>>(key)
        if (asList != null && asList.isNotEmpty()) {
            return asList.map { (it and 0xFF).toByte() }.toByteArray()
        }
        return null
    }

    companion object {
        private const val CHANNEL = "id.alienai/pos_shortcut"
        private const val THERMAL_BT_CHANNEL = "id.alienai/thermal_bluetooth"
    }
}
