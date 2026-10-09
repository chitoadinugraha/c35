package id.alienai

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                    pinPos(uri, label, id, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pinPos(uri: String, label: String, id: String, result: MethodChannel.Result) {
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
        val shortcut = ShortcutInfo.Builder(this, id)
            .setShortLabel(label)
            .setLongLabel(label)
            .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(intent)
            .build()
        sm.requestPinShortcut(shortcut, null)
        result.success(mapOf("ok" to true))
    }

    companion object {
        private const val CHANNEL = "id.alienai/pos_shortcut"
    }
}
