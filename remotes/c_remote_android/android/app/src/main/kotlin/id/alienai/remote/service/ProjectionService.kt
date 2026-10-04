package id.alienai.remote.service

import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import id.alienai.remote.bridge.NativeBridge
import java.nio.ByteBuffer

class ProjectionService(
    private val mediaProjection: MediaProjection,
    private val width: Int,
    private val height: Int,
    private val densityDpi: Int
) {
    companion object {
        private const val TAG = "ProjectionService"
    }

    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null

    @Volatile
    private var isStreaming = false

    fun start() {
        if (isStreaming) return

        handlerThread = HandlerThread("ProjectionThread").apply { start() }
        handler = Handler(handlerThread!!.looper)

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            try {
                val planes = image.planes
                val buffer: ByteBuffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride

                // If rowStride matches width * pixelStride, copy directly
                val rowPadding = rowStride - pixelStride * width
                val data = ByteArray(width * height * 4)

                if (rowPadding == 0) {
                    buffer.get(data)
                } else {
                    // Copy row by row removing padding
                    val rowBuffer = ByteArray(rowStride)
                    for (row in 0 until height) {
                        buffer.position(row * rowStride)
                        buffer.get(rowBuffer, 0, width * 4)
                        System.arraycopy(rowBuffer, 0, data, row * width * 4, width * 4)
                    }
                }

                NativeBridge.nativePushFrameRgba(width, height, data)
            } catch (e: Exception) {
                Log.e(TAG, "Error acquiring projection image: ${e.message}")
            } finally {
                image.close()
            }
        }, handler)

        virtualDisplay = mediaProjection.createVirtualDisplay(
            "AlienRemoteDisplay",
            width,
            height,
            densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface,
            null,
            handler
        )

        isStreaming = true
        Log.i(TAG, "Screen projection started: ${width}x${height} @ ${densityDpi}dpi")
    }

    fun stop() {
        if (!isStreaming) return
        isStreaming = false

        virtualDisplay?.release()
        virtualDisplay = null

        imageReader?.close()
        imageReader = null

        handlerThread?.quitSafely()
        handlerThread = null
        handler = null

        mediaProjection.stop()
        Log.i(TAG, "Screen projection stopped")
    }
}
