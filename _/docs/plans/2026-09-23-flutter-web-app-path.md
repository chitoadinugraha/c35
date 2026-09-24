# Flutter Web at `alienai.id/app` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Flutter web client at `https://alienai.id/app/` with static assets in OCI S3 (not in the server Docker image), integrated into the existing release pipeline.

**Architecture:** `flutter build web --base-href /app/` produces `clients/app/build/web/`. Deploy script syncs to S3 keys `app/web/{N}/` (immutable) and `app/web/current/` (live). `c35-server` serves `GET /app/*` by reading from S3 prefix `app/web/current/` with SPA fallback to `index.html`. Version row `app.release.c35.web` points to `https://alienai.id/app/`. No `app.alienai.id` host.

**Tech Stack:** Flutter web, Dart deploy scripts, Rust/axum (`wire_http`), existing `mod_file` S3 client (`S3_*` env), Yugabyte `ai.config`.

## Global Constraints

- Web URL: **`https://alienai.id/app/`** — not `app.alienai.id`.
- Static assets **not** baked into `_/deployments/Dockerfile` — S3 only.
- S3 prefix: `app/web/{build}/` + `app/web/current/` (same bucket as CAS via `S3_*`).
- Build number compare uses **build number** (`234`), not full semver — per `_/docs/auto-update.md`.
- Config key: `app.release.c35.web`.
- API base for web build: `C35_SERVER=https://api.alienai.id` (`--dart-define`).
- Do **not** use CAS per-file upload for the web tree — use directory sync to S3.
- Verify after edit: `dart analyze` (deploy), `cargo test -p c35_wire_http`, `cargo build -p server_ai`, `flutter analyze` (client).
- CORS: already permissive in `server_ai/src/boot.rs` — no change required for same-brand cross-origin to `api.alienai.id`.

---

## Locked decisions

| Topic | Decision |
|-------|----------|
| Public URL | `https://alienai.id/app/` |
| Storage | OCI S3 `app/web/current/` (+ versioned `app/web/{N}/`) |
| Server image | Rust binary only — no `build/web` COPY |
| Marketing site | Stays at `alienai.id/` from `clients/web` (unchanged) |
| `/download/web` | Redirect → `https://alienai.id/app/` |
| Legacy `app.alienai.id` | Out of scope — optional 301 later |
| Versioned URL | Optional `alienai.id/v/{N}/` for rollback QA (port from csa if time permits) |

---

## File map (target state)

| File | Responsibility |
|------|----------------|
| `_/scripts/deploy/deploy_app/build_web.dart` | `buildWebRelease()` — flutter build web |
| `_/scripts/deploy/deploy_app/s3_upload.dart` | `s3SyncDir`, `s3UploadWebBuild` — OCI directory sync |
| `_/scripts/deploy/deploy_app/publish_app_version.dart` | `publishWebAppVersion`, extend `publishAppReleaseProd` |
| `_/scripts/deploy/deploy_app/deploy_app_release.dart` | Add web build + upload + publish in prod wave |
| `_/scripts/deploy/deploy_app/push_web.dart` | Standalone web-only publish script |
| `_/scripts/deploy/pubspec.yaml` | Add `minio` or use raw HTTP S3 API (see Task 2) |
| `servers/crates/wire_http/src/app_web.rs` | S3 static handler for `/app/*` |
| `servers/crates/wire_http/src/lib.rs` | Mount `app_web` routes |
| `servers/crates/wire_http/src/web.rs` | Fix `/download/web` redirect target |
| `_/docs/app-release.md` | Web publish section |
| `_/docs/auto-update.md` | Web platform row |
| `clients/web/index.html` | `/download/web` already relative — no change if redirect fixed server-side |

---

## Multitask execution waves

| Wave | Tracks (parallel) | Depends on |
|------|-------------------|------------|
| **1** | Task 1 (S3 upload lib), Task 3 (build web) | — |
| **2** | Task 2 (server `/app` handler), Task 4 (publish helpers) | Wave 1 interfaces |
| **3** | Task 5 (orchestrator), Task 6 (standalone push_web) | Wave 1–2 |
| **4** | Task 7 (docs), Task 8 (k8s S3 env note) | Wave 3 |
| **5** | Task 9 (E2E smoke) | All |

---

### Task 1: S3 directory upload (deploy)

**Files:**
- Create: `_/scripts/deploy/deploy_app/s3_upload.dart`
- Modify: `_/scripts/deploy/pubspec.yaml` (if adding dependency)

**Reference:** Port patterns from `csa_site_published/_/scripts/deploy/deploy_app/oci_upload.dart` (`ociSyncDir`, `ociPutFile`).

**Interfaces:**
- `class S3UploadConfig` — from env: `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION`, `S3_SECURE`
- `Future<int> s3SyncDir({required S3UploadConfig cfg, required String localDir, required String prefix})` → file count
- `Future<void> s3UploadWebBuild({required int versionCode, required String webBuildDir})` — sync to `app/web/{N}/` then `app/web/current/`

**Implementation notes:**
- Use AWS S3-compatible PUT per file; preserve relative paths under prefix.
- Set `Content-Type` from extension (`.js` → `text/javascript`, `.wasm` → `application/wasm`, etc.).
- Cache-Control: `public, max-age=31536000, immutable` for hashed assets; `max-age=60` for `index.html` and `flutter_service_worker.js`.
- Fail fast if any `S3_*` missing (same keys as `mod_file`).

- [ ] **Step 1: Implement `S3UploadConfig.fromEnv()`**

```dart
class S3UploadConfig {
  const S3UploadConfig({required this.endpoint, required this.bucket, required this.accessKey, required this.secretKey, required this.region, required this.secure});
  // ...
  static S3UploadConfig fromEnv() {
    final endpoint = deployEnv('S3_ENDPOINT');
    final bucket = deployEnv('S3_BUCKET');
    if (endpoint.isEmpty || bucket.isEmpty) {
      throw StateError('S3_ENDPOINT and S3_BUCKET required for web upload');
    }
    // ...
  }
}
```

- [ ] **Step 2: Implement `s3SyncDir` with recursive directory walk**

- [ ] **Step 3: Implement `s3UploadWebBuild`**

- [ ] **Step 4: Verify**

```powershell
cd D:\c35\_\scripts\deploy
dart pub get
dart analyze deploy_app/s3_upload.dart
```

---

### Task 2: Server — serve `/app/*` from S3

**Files:**
- Create: `servers/crates/wire_http/src/app_web.rs`
- Modify: `servers/crates/wire_http/src/lib.rs`
- Modify: `servers/crates/wire_http/Cargo.toml` (if need extra deps — prefer reusing `c35_mod_file` S3)

**Interfaces:**
- `pub const WEB_S3_PREFIX: &str = "app/web/current"`
- `pub fn app_web_router() -> Router<AppState>`
- `async fn app_web_get(Path(path): Path<String>, State(st): State<AppState>) -> Response`

**Behavior:**
- `GET /app` → redirect 308 to `/app/`
- `GET /app/` → S3 `app/web/current/index.html`
- `GET /app/{path}` → S3 `app/web/current/{path}`; if missing and path has no `.`, SPA fallback `index.html`
- `GET /app/assets/...` → direct object
- 404 plain text if S3 not configured or object missing
- Reuse `BlobS3` from `c35_mod_file` (add `pub fn s3_client()` or `get_object(key)` export if needed)

**Reference:** `csa_site_published/crates/wire_http/src/app_release.rs` — adapt path prefix from host-based to `/app/`.

- [ ] **Step 1: Export S3 get from `mod_file` (minimal)**

In `servers/crates/mod_file/src/lib.rs` or `s3.rs`:

```rust
pub async fn s3_get_object(key: &str) -> Result<(Vec<u8>, String), String> {
    // returns (bytes, content_type)
}
```

- [ ] **Step 2: Create `app_web.rs` with MIME map + SPA fallback**

- [ ] **Step 3: Mount in `wire_http::router`**

```rust
.merge(app_web::app_web_router())
```

Place **before** site render router if path conflicts — `/app` must not hit guest site handler.

- [ ] **Step 4: Unit test MIME + path normalization (no S3)**

- [ ] **Step 5: Verify**

```powershell
cd D:\c35\servers
cargo test -p c35_wire_http
cargo build -p server_ai
```

---

### Task 3: Flutter web build script

**Files:**
- Create: `_/scripts/deploy/deploy_app/build_web.dart`

**Interfaces:**
- `String buildWebRelease({String? serverUrl})` → path to `clients/app/build/web`

- [ ] **Step 1: Implement build**

```dart
String buildWebRelease({String? serverUrl}) {
  final root = repoRoot();
  final clientApp = deployAppDir(root);
  final out = p.join(clientApp, 'build', 'web');
  final version = versionStampSync(root);
  final apiServer = serverUrl?.trim().isNotEmpty == true
      ? serverUrl!.trim()
      : deployEnv('C35_SERVER', 'https://api.alienai.id');
  stdout.writeln('Building Flutter web (version $version, server $apiServer)...');
  final proc = Process.runSync(
    'flutter',
    ['build', 'web', '--release', '--base-href', '/app/', '--dart-define=C35_SERVER=$apiServer'],
    workingDirectory: clientApp,
    runInShell: Platform.isWindows,
  );
  // check exit + return out
}
```

- [ ] **Step 2: Verify** (build may be slow — smoke with `--dry-run` not available; run analyze only in CI track)

```powershell
dart analyze deploy_app/build_web.dart
```

---

### Task 4: Version publish for web

**Files:**
- Modify: `_/scripts/deploy/deploy_app/publish_app_version.dart`

**Interfaces:**
- `const webAppUrl = 'https://alienai.id/app/';`
- `Future<void> publishWebAppVersion(int versionCode)`
- Extend `publishAppReleaseProd` to call `publishWebAppVersion` when web was uploaded

```dart
const webAppUrl = 'https://alienai.id/app/';

Future<void> publishWebAppVersion(int versionCode) => publishPlatformAppVersion(
  platform: 'web',
  version: versionCode,
  storeUrl: webAppUrl,
);

Future<void> publishAppReleaseProd({
  required int version,
  String apkHash = '',
  int apkSize = 0,
  String windowsHash = '',
  int windowsSize = 0,
  bool includeWeb = false,
}) async {
  await publishAndroidAppVersion(version, apkHash: apkHash, apkSize: apkSize);
  if (windowsHash.isNotEmpty && windowsSize > 0) {
    await publishWindowsAppVersion(version: version, hash: windowsHash, size: windowsSize);
  }
  if (includeWeb) await publishWebAppVersion(version);
}
```

- [ ] **Step 1: Add constants + functions**
- [ ] **Step 2: `dart analyze deploy_app/publish_app_version.dart`**

---

### Task 5: Integrate into `deploy_app_release.dart`

**Files:**
- Modify: `_/scripts/deploy/deploy_app/deploy_app_release.dart`

**Behavior change:**

| Mode | Web |
|------|-----|
| `--tester` | No |
| `--android-only` | No |
| `--windows-only` | No |
| Default prod | Yes — build + S3 upload + `publishWebAppVersion` |
| New `--web-only` | Yes only |

- [ ] **Step 1: Add flags `--web-only`**

```dart
final webOnly = args.contains('--web-only');
if (webOnly) {
  final versionCode = int.parse(versionStampSync(repoRoot()));
  final webDir = buildWebRelease();
  await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
  await publishWebAppVersion(versionCode);
  deployAppBumpVersion();
  deployDone(version: 'v$versionCode', detail: 'web ${dirSizeLabel(webDir)}');
  return;
}
```

- [ ] **Step 2: In default prod path, after Windows upload:**

```dart
final webDir = buildWebRelease();
await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
// ...
await publishAppReleaseProd(..., includeWeb: true);
```

- [ ] **Step 3: Verify `dart analyze deploy_app/deploy_app_release.dart`**

---

### Task 6: Standalone `push_web.dart`

**Files:**
- Create: `_/scripts/deploy/deploy_app/push_web.dart`

Thin script for web-only deploy without Play/Windows (like csa `push_web.dart`):

```dart
Future<void> main(List<String> args) async {
  deployStart();
  deployLoadEnvLocal();
  S3UploadConfig.fromEnv(); // fail fast
  final (_, versionCode) = versionReadPubspec(repoRoot());
  versionStampSync(repoRoot());
  final webDir = buildWebRelease();
  await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
  await publishWebAppVersion(versionCode);
  deployDone(version: 'v$versionCode', detail: 'web only');
}
```

- [ ] **Step 1: Create script**
- [ ] **Step 2: Analyze**

---

### Task 7: Docs

**Files:**
- Modify: `_/docs/app-release.md`
- Modify: `_/docs/auto-update.md`
- Modify: `2026-09-23-app-release-pipeline.md` — mark Task 10 done / link here

**Content:**
- Web URL `https://alienai.id/app/`
- S3 layout `app/web/{N}/`, `app/web/current/`
- Env: `S3_*` (same as CAS), `YB_PASSWORD`, `DEPLOY_AUTH_TOKEN` not needed for web (S3 only)
- Commands: `deploy_app_release.dart`, `push_web.dart`, `--web-only`
- Explicit: assets **not** in Docker image

- [ ] **Step 1: Update docs**

---

### Task 8: Cluster S3 env (ops)

**Files:**
- Modify: `_/deployments/c35-server/deployment.yaml` or document in `_/docs/app-release.md` that `c35-server-env` secret must include `S3_*`

Server needs `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION`, `S3_SECURE` for **read** path (may already exist for CAS writes).

- [ ] **Step 1: Verify secret has S3_* (kubectl / docs)**
- [ ] **Step 2: Fix `/download/web` in `web.rs`:**

```rust
.route("/download/web", get(|| async {
    Redirect::temporary("https://alienai.id/app/")
}))
```

---

### Task 9: E2E smoke checklist

- [ ] **Local:** `flutter build web --base-href /app/` succeeds
- [ ] **Upload:** `dart run deploy_app/push_web.dart` with S3 creds (or dry-run mock)
- [ ] **Serve:** `curl -sI https://alienai.id/app/` → 200 `text/html`
- [ ] **Assets:** `curl -sI https://alienai.id/app/main.dart.js` → 200
- [ ] **SPA:** `curl -sI https://alienai.id/app/settings` → 200 `index.html` (SPA fallback)
- [ ] **Version:** `curl https://api.alienai.id/version/web` → `{ "url": "https://alienai.id/app/", ... }`
- [ ] **Download link:** `curl -sI https://alienai.id/download/web` → 302 → `/app/`

---

## Subagent dispatch map (when executing)

| Subagent | Tasks | Model |
|----------|-------|-------|
| **web-deploy** | 1, 3, 4, 5, 6 | inherit |
| **web-server** | 2, 8 (redirect only) | inherit |
| **web-docs** | 7, 8 (secret doc) | inherit |

Wave 1: `web-deploy` Task 1+3, `web-server` Task 2 (can start once S3 get export interface agreed — or sequential wave 1 deploy lib, wave 2 server).

Wave 2: `web-deploy` Task 4–6, `web-server` finish Task 8.

Wave 3: `web-docs` + E2E Task 9.

---

## Self-review

| Requirement | Task |
|-------------|------|
| `alienai.id/app` URL | 2, 4, 7, 8 |
| S3 storage, not image | 1, 2, 7 |
| `--base-href /app/` | 3 |
| Release pipeline integration | 5, 6 |
| `app.release.c35.web` | 4 |
| No `app.alienai.id` | 7 (documented out of scope) |
| `/download/web` fix | 8 |

No placeholders in task steps.
