package id.alienai.remote.service

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator

class OverlayMarkerService : Service() {

    companion object {
        var instance: OverlayMarkerService? = null
            private set
    }

    private var windowManager: WindowManager? = null
    private var markerView: MarkerView? = null

    inner class LocalBinder : Binder() {
        fun getService(): OverlayMarkerService = this@OverlayMarkerService
    }

    override fun onBind(intent: Intent?): IBinder = LocalBinder()

    override fun onCreate() {
        super.onCreate()
        instance = this
        if (Settings.canDrawOverlays(this)) {
            setupOverlay()
        }
    }

    private fun setupOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        markerView = MarkerView(this)

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )

        windowManager?.addView(markerView, layoutParams)
    }

    fun showTap(x: Float, y: Float) {
        markerView?.animateTap(x, y)
    }

    override fun onDestroy() {
        super.onDestroy()
        markerView?.let { windowManager?.removeView(it) }
        markerView = null
        if (instance == this) {
            instance = null
        }
    }

    /**
     * Custom full-screen transparent view that animates a red circle with white ring
     * at the tap point.
     */
    private class MarkerView(context: Context) : View(context) {
        private var tapX = -1f
        private var tapY = -1f
        private var radius = 0f
        private var alpha = 255

        private val redPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(255, 0, 0)
            style = Paint.Style.FILL
        }

        private val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 4f
        }

        fun animateTap(x: Float, y: Float) {
            post {
                tapX = x
                tapY = y
                radius = 10f
                alpha = 255

                val animator = ValueAnimator.ofFloat(0f, 1f).apply {
                    duration = 350
                    interpolator = DecelerateInterpolator()
                    addUpdateListener { anim ->
                        val fraction = anim.animatedFraction
                        radius = 12f + fraction * 24f
                        alpha = ((1f - fraction) * 255).toInt()
                        redPaint.alpha = alpha
                        ringPaint.alpha = alpha
                        invalidate()
                    }
                    addListener(object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            tapX = -1f
                            tapY = -1f
                            invalidate()
                        }
                    })
                }
                animator.start()
            }
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            if (tapX >= 0 && tapY >= 0) {
                // High-contrast red circle with white ring
                canvas.drawCircle(tapX, tapY, radius, redPaint)
                canvas.drawCircle(tapX, tapY, radius + 4f, ringPaint)
            }
        }
    }
}
