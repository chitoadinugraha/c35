---
description: YSQL schema changes — _/schemas, version hash, c35_migrate, server boot
globs: _/schemas/**/*.sql,servers/crates/store/src/migrate.rs,servers/crates/store/src/schema.rs,servers/crates/store/src/bin/c35_migrate.rs
alwaysApply: false
---

# DB schema change (c35)

Read [`_/specs/schema-migrate.md`](../../_/specs/schema-migrate.md) before editing DDL or migrate behavior.

## Rules

1. **Edit SQL in `_/schemas/`** — idempotent statements only on the boot path (`IF NOT EXISTS`, safe `ON CONFLICT`, etc.).
2. **Register new files** in `servers/crates/store/src/schema.rs` -> `SCHEMA_APPLY_ORDER` (order matters).
3. **Version is automatic** — Blake3 bundle hash stored in `ai.config` key `c35.schema_version`. Do not bump a manual integer; changing SQL changes the hash.
4. **Apply to shared YB** after schema edits:

   ```powershell
   cd servers
   cargo run -p c35_store --bin c35_migrate -- apply
   ```

5. **One-off data migrations** -> `_/schemas/migrations/` (manual run; not in bundle unless merged into main `.sql` files).
6. **Do not** rely on `C35_SCHEMA_SKIP` in production; local escape hatch only (`server_ai/.env.example`).
7. **Boot patches** (`BOOT_PATCH_SQL` in `migrate.rs`) are part of the hash — keep small and idempotent.

## Checklist

- [ ] SQL change in `_/schemas/*.sql` (+ `schema.rs` if new file)
- [ ] `cargo run -p c35_store --bin c35_migrate -- apply` against target DB
- [ ] `cargo run -p c35_store --bin c35_migrate -- audit` exits 0
- [ ] Cluster: roll `server_ai` after apply so pods log `schema: up to date`
- [ ] If proto/wire types change, update `_/schemas/proto/` and regenerate clients per repo conventions

## Verify (Rust)

```powershell
cd servers
cargo test -p c35_store
cargo build -p server_ai
```