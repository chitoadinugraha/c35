package id.alienai.remote.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import id.alienai.remote.bridge.NativeBridge
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicBoolean

class AccessControlService : AccessibilityService() {

    companion object {
        private const val TAG = "AccessControlService"
        var instance: AccessControlService? = null
            private set
        val isServiceRunning = AtomicBoolean(false)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isServiceRunning.set(true)
        Log.i(TAG, "AccessControlService connected and ready for input dispatch")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Trigger periodic UI hierarchy refresh on window changes
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            scanAccessibilityTree()
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "AccessControlService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning.set(false)
        if (instance == this) {
            instance = null
        }
    }

    /**
     * Dispatches a single tap gesture at absolute pixel coordinates (x, y).
     */
    fun dispatchTap(x: Float, y: Float, onComplete: (() -> Unit)? = null): Boolean {
        val path = Path().apply {
            moveTo(x, y)
            lineTo(x, y)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0, 50)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                onComplete?.invoke()
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                Log.w(TAG, "Tap gesture cancelled at ($x, $y)")
            }
        }, null)
    }

    /**
     * Dispatches a drag or swipe gesture from (startX, startY) to (endX, endY).
     */
    fun dispatchDrag(
        startX: Float,
        startY: Float,
        endX: Float,
        endY: Float,
        durationMs: Long = 300
    ): Boolean {
        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(100))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return dispatchGesture(gesture, null, null)
    }

    /**
     * Performs a global system navigation action (Back, Home, Recents, Notifications).
     */
    fun performGlobal(action: Int): Boolean {
        return performGlobalAction(action)
    }

    /**
     * Types text into the currently focused editable node.
     */
    fun typeText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val focused = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT) ?: return false

        val arguments = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    /**
     * Traverses the active window accessibility tree, extracts interactive controls,
     * calculates bounding boxes, and submits them to NativeBridge for Set-of-Marks (SoM).
     */
    fun scanAccessibilityTree() {
        val root = rootInActiveWindow ?: return
        val marks = JSONArray()
        var markIndex = 1

        fun walk(node: AccessibilityNodeInfo) {
            val isClickable = node.isClickable || node.isCheckable
            val isEditable = node.isEditable
            val isInteractive = isClickable || isEditable

            if (isInteractive && node.isVisibleToUser) {
                val rect = Rect()
                node.getBoundsInScreen(rect)

                if (rect.width() > 10 && rect.height() > 10) {
                    val label = node.text?.toString()
                        ?: node.contentDescription?.toString()
                        ?: node.viewIdResourceName?.substringAfterLast('/')
                        ?: ""

                    val obj = JSONObject().apply {
                        put("id", "@$markIndex")
                        put("control_type", node.className?.toString()?.substringAfterLast('.') ?: "View")
                        put("name", label)
                        put("auto_id", node.viewIdResourceName ?: "")
                        put("center_x", rect.centerX())
                        put("center_y", rect.centerY())
                        put("bbox", JSONArray().apply {
                            put(rect.left)
                            put(rect.top)
                            put(rect.width())
                            put(rect.height())
                        })
                    }
                    marks.put(obj)
                    markIndex++
                }
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { child ->
                    walk(child)
                }
            }
        }

        try {
            walk(root)
            NativeBridge.nativeUpdateMarks(marks.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning accessibility tree: ${e.message}")
        }
    }
}
