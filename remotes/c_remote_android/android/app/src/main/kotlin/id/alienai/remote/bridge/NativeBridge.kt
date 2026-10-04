package id.alienai.remote.bridge

interface RustCallback {
    fun onRemoteInput(
        eventType: String,
        x: Double,
        y: Double,
        text: String,
        button: Int,
        keyCode: Int
    )
}

object NativeBridge {
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
