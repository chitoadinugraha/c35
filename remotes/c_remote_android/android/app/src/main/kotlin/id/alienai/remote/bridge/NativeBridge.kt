package id.alienai.remote.bridge

import android.content.Context
import java.io.File

interface RustCallback {
    fun onRemoteInput(
        eventType: String,
        x: Double,
        y: Double,
        text: String,
        button: Int,
        keyCode: Int
    )

    fun onStatusChanged(statusJson: String)
}

data class AgentStatus(
    val paired: Boolean = false,
    val online: Boolean = false,
    val status: String = "Connecting…",
    val pairing_code: String = "",
    val pairing_seconds_remaining: Long = 0,
    val owner_label: String = "",
    val device_name: String = "",
    val package_name: String = "",
    val active_viewers: Int = 0
)

object NativeBridge {
    @Volatile
    var appContext: Context? = null

    @JvmStatic
    fun installApkFromRust(apkPath: String): Boolean {
        val ctx = appContext ?: return false
        return UpdateInstaller.install(ctx, File(apkPath))
    }

    init {
        try {
            System.loadLibrary("rust_remote_android")
        } catch (e: UnsatisfiedLinkError) {
            System.err.println("Warning: rust_remote_android library not found in APK: ${e.message}")
        }
    }

    external fun nativeInit(
        serverUrl: String,
        dataDir: String,
        deviceName: String,
        callback: RustCallback
    ): Boolean

    external fun nativeGetStatusJson(): String

    external fun nativeGetLogTail(maxLines: Int): Array<String>

    external fun nativePushFrameRgba(
        width: Int,
        height: Int,
        rgbaBytes: ByteArray
    )

    external fun nativePushFrameH264(
        nalBytes: ByteArray,
        durationMs: Int
    )

    external fun nativeUpdateMarks(marksJson: String)

    external fun nativeSetControlAllowed(allowed: Boolean)

    external fun nativeIsControlAllowed(): Boolean

    external fun nativeIsPaired(): Boolean

    external fun nativeUnpair()
}
