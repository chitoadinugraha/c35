# Play Console: DEX optimization + bitmap downsampling

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox tasks (`- [ ]`) are the source of truth.
>
> **For Chito:** Review after **DEX-W2** (release soak) before promoting the AAB that clears Play’s deadline.

**Goal:** Raise **DEX code optimization — Obfuscation** above Play’s 25% threshold and clear the **bitmap downsampling** finding so publishing/visibility warnings go away.

**Architecture:** Turn on **R8 minify + resource shrink** for `release` with Flutter-safe ProGuard rules and upload **deobfuscation mapping** on each Play upload. Fix the only first-party `BitmapFactory` usage (POS shortcut icons in `MainActivity`) with a bounds pass + `inSampleSize`, then scale to shortcut icon size before `Icon.createWithBitmap`. Optional follow-up: tighten Flutter `Image` decode size on Android where large files are shown small.

**Tech stack:** Gradle Kotlin DSL (`clients/app/android/app/build.gradle.kts`), R8/ProGuard, Kotlin (`MainActivity.kt`), Flutter release AAB (`deploy_app_release.dart` / `play_store_upload_*.dart`).

| Reference | Use |
|-----------|-----|
| [`build.gradle.kts`](../../clients/app/android/app/build.gradle.kts) | Today `isMinifyEnabled = false` — root cause of ~1% obfuscation |
| [`MainActivity.kt`](../../clients/app/android/app/src/main/kotlin/id/alienai/MainActivity.kt) | `BitmapFactory.decodeFile` / `decodeByteArray` without downsampling |
| [`app-release.md`](../app-release.md) | Play upload flow; add mapping + release QA notes |
| [Flutter shrink / obfuscate](https://docs.flutter.dev/deployment/android#enabling-multidex-support) | Official ProGuard snippets |

**Out of scope (v1):** Fixing third-party AARs that use raw `BitmapFactory` (only address if Play still flags after v1 + new AAB). Replacing all `Image.network` with a new dependency. Changing package id or signing.

---

## Root cause (confirmed in repo)

| Play finding | Cause in c35 |
|--------------|----------------|
| Obfuscation **1%** | `release { isMinifyEnabled = false; isShrinkResources = false }` — R8 does not rename/shrink app code. |
| Bitmap downsampling | `shortcutIcon()` decodes full-resolution file/bytes for launcher shortcuts (lines ~163–175). No other `BitmapFactory` under `clients/app/android/`. |

---

## Locked decisions

1. **Enable minify for `release` only** — debug builds stay unobfuscated for faster iteration.
2. **Keep `id.alienai` upload keystore** — no new flavors unless minify breaks a required debug-only path.
3. **Mapping file:** Every Play AAB upload must include `mapping.txt` from `build/app/outputs/mapping/release/` (document path in `app-release.md`).
4. **Shortcut icons:** Target max edge **108 px** (shortcut/adaptive icon safe size); use `inSampleSize` then `Bitmap.createScaledBitmap` only if still larger than target.
5. **Verification:** Internal/testing track upload + Play **Pre-launch report** / App bundle explorer **DEX optimization** before production promote.

---

## Master wave map

| Wave | Name | Parallel tracks | Depends on | Ship criterion |
|------|------|-----------------|------------|----------------|
| **DEX-W0** | Baseline | — | — | Document current version + reproduce release AAB locally |
| **DEX-W1** | Fixes | **A** = R8 + ProGuard, **B** = bitmap downsampling | W0 | Release AAB builds; shortcut icons still work |
| **DEX-W2** | Soak + Play | **C** = manual QA matrix, **D** = internal upload + Console check | W1 | Obfuscation category ≥ 25%; bitmap issue cleared or reduced |
| **DEX-W3** | Docs | **E** = `app-release.md` + plan link in `spec.md` | W2 | Next release operator knows mapping + minify |

```text
DEX-W0
  → DEX-W1 (A + B in parallel)
  → DEX-W2 (C + D; D after A completes)
  → DEX-W3 (E)
```

**Subagent dispatch (first parallel wave after W0):**

- DEX-W1: **Track A** (Gradle + ProGuard) + **Track B** (Kotlin bitmap helper) — independent; merge before W2.

---

## Track A — R8 minify, shrink, ProGuard (DEX obfuscation)

**Owner files:**

- Modify: `clients/app/android/app/build.gradle.kts`
- Create: `clients/app/android/app/proguard-rules.pro`
- Optional modify: `clients/app/android/gradle.properties` (only if needed for R8 full mode — default off until soak passes)

### Task A1: Enable release shrinking

**Files:** `clients/app/android/app/build.gradle.kts`

- [ ] Set `release` `isMinifyEnabled = true`, `isShrinkResources = true`.
- [ ] Add:

```kotlin
proguardFiles(
    getDefaultProguardFile("proguard-android-optimize.txt"),
    "proguard-rules.pro",
)
```

inside `buildTypes { release { ... } }`.

### Task A2: Flutter + plugin ProGuard rules

**Files:** `clients/app/android/app/proguard-rules.pro`

- [ ] Add Flutter baseline (keep `FlutterMain`, embedding, plugins):

```proguard
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
```

- [ ] Add keeps for high-risk plugins in this app (adjust after first R8 failure log):
  - **Firebase** (`com.google.firebase.**`, `FirebaseMessaging`)
  - **Gson / JSON** used by Play Services transitive deps (`-keepattributes Signature,*Annotation*`)
  - **Protobuf** generated (`clients/app/lib/c/pb/**` → Java may be minimal; watch for `GeneratedMessageLite`)
  - **WebRTC** (`org.webrtc.**` — often needs `-keep class org.webrtc.** { *; }`)
  - **Kotlin coroutines / metadata** (`-keepattributes InnerClasses,EnclosingMethod`)

- [ ] Keep application entry:

```proguard
-keep class id.alienai.** { *; }
```

(narrow later if obfuscation % is satisfied and mapping proves safe — v1 prefer stability over max %).

### Task A3: Release build + mapping artifact

- [ ] From repo root:

```powershell
cd clients/app
flutter build appbundle --release
```

- [ ] Confirm exists: `clients/app/build/app/outputs/mapping/release/mapping.txt`
- [ ] Install release APK on device (or `flutter build apk --release` + sideload) — app launches to Home, login, one chat turn.

### Task A4: Fix R8 regressions (iterative)

- [ ] Run release app; exercise: **login**, **push notification** (FCM), **WebRTC/live**, **in-app purchase** screen open, **file picker**, **POS shortcut** create (needs Track B), **APK update** path if enabled.
- [ ] On crash, collect `adb logcat` → add targeted `-keep` for missing class → rebuild until smoke passes.
- [ ] Do **not** disable minify to “fix” — fix rules.

**Interfaces (for Track D):**

- Produces: release AAB with non-trivial mapping file size; Play should report higher **Obfuscation** % on next upload.

---

## Track B — Bitmap downsampling (POS shortcuts)

**Owner files:**

- Modify: `clients/app/android/app/src/main/kotlin/id/alienai/MainActivity.kt`
- Optional test: small JVM/robolectric not required — manual + existing Flutter tests unchanged.

### Task B1: Shared decode helper

Add private functions in `MainActivity.kt`:

```kotlin
private fun maxShortcutIconPx(): Int {
    val dm = resources.displayMetrics
    return (108f * dm.density).toInt().coerceAtLeast(96)
}

private fun decodeSampledBitmap(bytes: ByteArray, maxPx: Int): Bitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    val sample = calculateInSampleSize(bounds, maxPx, maxPx)
    val opts = BitmapFactory.Options().apply {
        inSampleSize = sample
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
    val sample = calculateInSampleSize(bounds, maxPx, maxPx)
    val opts = BitmapFactory.Options().apply {
        inSampleSize = sample
        inPreferredConfig = Bitmap.Config.ARGB_8888
    }
    return BitmapFactory.decodeFile(path, opts)?.let { scaleDownIfNeeded(it, maxPx) }
}

private fun calculateInSampleSize(
    options: BitmapFactory.Options,
    reqWidth: Int,
    reqHeight: Int,
): Int {
    val (height, width) = options.outHeight to options.outWidth
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
    return Bitmap.createScaledBitmap(source, w, h, true).also {
        if (it != source) source.recycle()
    }
}
```

(Use `android.graphics.Bitmap` import; add `recycle()` only when creating a new bitmap.)

### Task B2: Wire `shortcutIcon()`

- [ ] Replace raw `decodeFile` / `decodeByteArray` with `decodeSampledBitmapFile` / `decodeSampledBitmap` using `maxShortcutIconPx()`.
- [ ] Manual test: create/update a POS shortcut with a **large** product image URL cached to disk — shortcut appears, no OOM in logcat.

### Task B3 (optional, only if Play still flags bitmap after W2)

Play static analysis may also count **dependencies**. If warning persists:

- [ ] Audit `Image.file` / `Image.network` without `cacheWidth`/`cacheHeight` on Android for thumbnails (e.g. `guest_site_blocks.dart` 48×48) — add `cacheWidth`/`cacheHeight` rounded to device pixel ratio.
- [ ] Prefer extending `UiImgCached` to pass cache dimensions from `width`/`height` when set.

**Defer B3** until internal-track Console report after W2.

---

## Track C — Release QA matrix (DEX-W2)

- [ ] Cold start, background resume
- [ ] Sign in / token refresh
- [ ] Send chat message with image attachment
- [ ] Open site guest catalog (network images)
- [ ] Pair device / remote (if available)
- [ ] Create POS home-screen shortcut (large icon)
- [ ] Trigger Play in-app update check OR APK channel check (no crash)
- [ ] Receive FCM (or log token fetch)

Run: `.\_\scripts\dev\verify_flutter_app.ps1` before upload.

---

## Track D — Play internal upload + Console verification

- [ ] Bump version per [`app-release.md`](../app-release.md) (or tester script if internal only).
- [ ] Upload AAB to **internal** track with **mapping file** attached (Play Console → App bundle explorer → uploads).
- [ ] Wait for processing; open **Policy / Quality** (or App quality → Android vitals / recommendations) and confirm:
  - **DEX code optimization — Obfuscation** ≥ **25%**
  - Bitmap downsampling recommendation **cleared** (or note remaining stack trace if plugin)
- [ ] If obfuscation still low: confirm upload is **release** minified AAB (not debug); confirm mapping uploaded to same version code.

---

## Track E — Documentation

- [ ] `app-release.md`: subsection **Android R8** — minify on, mapping path, “do not turn off minify for Play warnings”.
- [ ] `spec.md` plans index: link this file.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| R8 strips WebRTC / Firebase / IAP | Iterative `-keep` from logcat; test matrix C |
| ShrinkResources removes needed raw asset | Watch first launch UI; add `res/raw` keeps if broken |
| Obfuscation % still low | Ensure no duplicate unstripped artifact; verify correct variant; check Play docs for metric definition on Flutter apps |
| Bitmap warning from dependency | B3 optional; file Play feedback with class path from bundle explorer |

---

## Review gates

| Gate | Who | Condition |
|------|-----|-----------|
| **G1** | Chito | DEX-W1 merged; local `flutter build appbundle --release` green |
| **G2** | Chito | Track C smoke pass on physical Android device |
| **G3** | Chito | Track D Console metrics meet thresholds on **internal** version before prod promote |

---

## Execution handoff (multitask)

**Wave 1 (parallel):** Dispatch subagent **Track A** + subagent **Track B** after **DEX-W0** baseline build is recorded.

**Wave 2:** Subagent **Track C** then **Track D** (same session or sequential).

**Wave 3:** Subagent **Track E**.
