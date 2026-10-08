# Android Remote Agent Architecture (`id.alienai.remote`)

Status: **Locked architectural specification**  
Package ID: `id.alienai.remote`  
Platform Target: Android 10+ (API 29+), optimal on Android 14/15+ (API 34/35)

---

## 1. Architectural Motivation & Dual-App Model

The Alien AI platform separates the **Consumer Client** from the **Remote Agent**:

1. **Consumer Client (`id.alienai.app`)**:
   - Google Play Store compliant chat, viewer, and account management app.
   - Contains **no** Accessibility or background screen recording permissions to avoid Play Store restrictions and review friction.
2. **Remote Agent (`id.alienai.remote`)**:
   - Standalone companion service package (distributed via in-app direct download, OTA, GitHub release, or enterprise MDM).
   - Holds necessary system permissions (`BIND_ACCESSIBILITY_SERVICE`, `MediaProjection`, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`).
   - Runs headless or with minimal UI, identical in philosophy to `c_remote_windows` (`alienai_remote_windows.exe`).

---

## 2. Core Reuse & WebRTC Transport

The Android executor (`remotes/c_remote_android`) reuses **`c_remote_core`** via Android NDK (`cargo ndk`):

```
┌─────────────────────────────────────────────────────────────┐
│                   id.alienai.remote                         │
│                                                             │
│  Kotlin Host Layer:                                         │
│  - RemoteAgentService (Foreground Service + WakeLock)        │
│  - ProjectionService  (MediaProjection -> Video frames)      │
│  - RemoteAccessService(AccessibilityService -> Inputs & SoM)│
│  - OverlayMarkerService (TYPE_APPLICATION_OVERLAY indicator)│
│  - MainActivity       (Minimal Status & Pairing UI)         │
│                              │                              │
│                             JNI                             │
│                              ▼                              │
│  Rust Native Bridge (librust_remote.so):                    │
│  - c_remote_core::conn_ws   (Server WS & NATS control)      │
│  - c_remote_core::webrtc    (Pure-Rust WebRTC data plane)   │
│  - c_remote_core::pair      (Pairing token registration)    │
│  - c_remote_core::update    (OTA APK download & staging)    │
└─────────────────────────────────────────────────────────────┘
```

### WebRTC Channels (100% Shared Protocol)
The data plane runs over the exact same WebRTC implementation (`webrtc-rs` in `c_remote_core`) used on Windows:

| Channel / Track | Protocol | Role |
| :--- | :--- | :--- |
| **`remote-input`** | SCTP Data Channel | Receives Protobuf `RemoteInputEvent` from Flutter viewer. |
| **`remote-screen`** | SCTP Data Channel | Pushes JPEG screen frames to viewer (standard fallback). |
| **RTP Video Track** | WebRTC Media Track | Streams hardware H.264 NAL units from `MediaCodec` via `TrackLocalStaticSample`. |
| **`remote-fs`** | SCTP Data Channel | Device storage browsing via standard SAF / app storage. |

---

## 3. Screen Capture & Input Injection

### A. Screen Capture (`MediaProjection`)
- Screen capture is handled via Android's `MediaProjectionManager`.
- Runs inside a Foreground Service with `android:foregroundServiceType="mediaProjection"`.
- Feeds into:
  1. **`ImageReader`**: Extracts RGBA/JPEG frames for screenshots and SCTP `remote-screen` streaming.
  2. **`MediaCodec` Surface**: Encodes hardware H.264 NAL units for 60fps low-latency WebRTC RTP video tracks.

### B. Input Injection (`AccessibilityService`)
- Uses `AccessibilityService.dispatchGesture`:
  - **Single Tap**: `GestureDescription` with a 1px `Path` and 50ms duration.
  - **Drag / Swipe**: `GestureDescription` with stroke from `(x1, y1)` to `(x2, y2)`.
  - **Double Tap**: Sequential gestures with 100ms spacing.
- System Actions:
  - Back: `performGlobalAction(GLOBAL_ACTION_BACK)`
  - Home: `performGlobalAction(GLOBAL_ACTION_HOME)`
  - App Switcher: `performGlobalAction(GLOBAL_ACTION_RECENTS)`
  - Notification Shade: `performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)`
- Text Entry:
  - Primary: Focused `AccessibilityNodeInfo.performAction(ACTION_SET_TEXT, bundle)`.
  - Secondary/Fallback: Virtual IME soft-keyboard or clipboard paste.

---

## 4. Red Markers & Set-of-Marks (SoM)

### A. Action Feedback Red Marker
- **Purpose**: Mark exact click/action landing points directly in screenshots for multimodal AI models (Gemini / Claude).
- **Format**: High-contrast red circle ($r=4\text{px}$) with an outer white ring ($r=7\text{px}$) at normalized coordinates $(x, y)$.
- **Implementation**: Rasterized directly onto the frame buffer before encoding, sharing the logic from `c_remote_windows::screen_capture::draw_red_marker`.

### B. Set-of-Marks (SoM) via Android Accessibility
- **Method**: The Android `AccessibilityService` queries the live UI tree via `rootInActiveWindow`.
- **Filtering**:
  Recursively collects nodes where `isClickable || isEditable || isCheckable || isScrollable`.
- **Bounding Boxes & Numbering**:
  - `node.getBoundsInScreen(rect)` retrieves exact device screen coordinates.
  - Elements receive `@1`, `@2`, `@3` badges.
  - Draws coral/orange-red hollow bounding boxes and crimson number badges onto the screenshot.
  - Generates structured `axtree_text` prompt strings for LLMs.

### C. Physical Screen Visual Tap Indicator
- Uses `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY` (`SYSTEM_ALERT_WINDOW`).
- Renders an ephemeral expanding red ripple on the physical device screen whenever an input gesture is executed, providing clear visual feedback to human observers.

---

## 5. Minimal Native UI Layout

Matching `c_remote_windows`:
1. **Unpaired State**:
   - Device Name & 10-character Pairing Code (`XXXXX-XXXXX`) + QR Code.
   - Permission Checklist cards:
     - Accessibility Service (Click to open Accessibility settings)
     - MediaProjection (Click to request capture permission)
     - Battery Optimization Exemption (Click to exempt from Doze)
     - Floating Overlay (Click to grant draw-over-apps)
2. **Paired State**:
   - Status header: Cloud WebSocket indicator dot, paired owner handle (`@username`), active viewers count.
   - Master toggle: **Allow Remote Control** (`is_control_allowed`).
   - Compact log ring viewer tail (last 40 log lines).
   - "Check for Update" / OTA button.

---

## 6. Distribution & publish

| Channel | URL / command |
|---------|----------------|
| Website | `GET https://alienai.id/download/remote.apk` (alias `/download/agent.apk`) |
| Main app | Devices → **Install Remote Agent** (Android only; sideload `id.alienai.remote`) |
| OTA | `GET /version/remote-android` + NATS `c35.release.remote-android` |
| Publish | `.\_\scripts\deploy\publish_remote_android.ps1` |

Config: `ai.config` → `app.release.c35.remote-android` (`apkHash`, `apkSize`, mirrored `hash`/`size` for agent OTA).

---

## 7. Background Lifecycle & Autostart

- **Foreground Service**: Persistent ongoing notification prevents OS task-killing.
- **WakeLock**: Holds `PARTIAL_WAKE_LOCK` during active WebRTC or automation tasks.
- **Doze Exemption**: Requests `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- **Boot Autostart**: Listens for `android.intent.action.BOOT_COMPLETED` in a `BroadcastReceiver`.
