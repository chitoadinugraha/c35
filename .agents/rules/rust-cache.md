---
description: Rust build caches live under .cache/ only — never workspace target/
alwaysApply: true
---

# Rust build cache

All local Cargo output goes under **`.cache/`** (gitignored, cursorignored). Never commit or index `**/target/`.

## Workspaces

| Workspace | Build from | Cache dir |
|-----------|------------|-----------|
| Server | `servers/` | `.cache/server` |
| Remote agent | `remotes/` | `.cache/c_remote` |
| Node stats | `node_stats/` | `.cache/node_stats` |
| hash_blake3 tool | `_/scripts/deploy/tools/hash_blake3/` | `.cache/rust/hash_blake3` |

Each workspace has `.cargo/config.toml` with `target-dir` pointing at its row above.

## Rules

1. **`cd` into the workspace** before `cargo build`, `cargo test`, or `cargo clean`.  
   `servers/.cargo/config.toml` is ignored when Cargo runs from repo root with `--manifest-path` — that falls back to `servers/target/`.
2. Do **not** add new `target/` dirs under `servers/`, `remotes/`, or `node_stats/`.
3. Scripts that build from repo root must set `CARGO_TARGET_DIR` explicitly (see `hash_blake3.dart`).
4. Cleanup: `.\_\scripts\dev\cleanup_rust_cache.ps1` (trim) or `-Full` (wipe `.cache` rust dirs + legacy `*/target/`).

## Verify (server edits)

```powershell
cd servers
cargo build -p server_ai
```
