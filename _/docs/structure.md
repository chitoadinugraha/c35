# Repository structure (LOCKED)

Status: **locked** 2026-09-20

How files are organized before and during implementation. Canonical specs stay in `_/`; runnable code in `servers/`, `remotes/`, `clients/`.

## Top level

```
c35/
  _/                         # specs — source of truth
    docs/                     # architecture, modules, this file
    schemas/                  # *.sql + proto/c35/*.proto
    scripts/                  # protoc, deploy helpers
  servers/                    # Rust server workspace → .cache/server
  remotes/                    # Rust agent workspace → .cache/agent (Phase 6)
  clients/app/                # Flutter (Phase 2)
  .cache/                     # gitignored cargo targets
  concept.md                  # index → _/docs/
```

**Rules**

- SQL and proto live only under `_/schemas/`. Crates **include** or **generate** from there — no forks.
- Server library crates live under `servers/crates/` only (never repo-root `crates/`).
- Add new `mod_*` crates when that roadmap phase starts — not all upfront.

## Schema apply order

```
identity → billing → chat → log → embed → skill → consumption → site → tx → file (later)
```

Boot: `store::migrate::apply_all()` when `C35_DB_MIGRATE=1`.

## Server workspace (Phase 1)

```
servers/
  Cargo.toml                  # workspace members + shared deps
  .cargo/config.toml          # target-dir = ../.cache/server
  server_ai/                  # thin binary — boot, migrate, mount wire
    Cargo.toml
    .env.example
    src/
      main.rs
      config.rs
      boot.rs
  crates/
    proto/                    # prost codegen from _/schemas/proto
      build.rs
      src/lib.rs
    store/                    # YB pool, migrate, since_list helpers
      src/
        lib.rs
        pool.rs
        migrate.rs
        schema.rs
    wire/                     # WireErr, pb helpers
      src/lib.rs
    wire_http/                # GET /health, /livez
      src/lib.rs
    wire_ws/                  # GET /v1/ws — WsReq/WsRes router
      src/
        lib.rs
        session.rs
        router.rs
    system/
      ctx/                    # AppState, Ctx { pool, caller_iid }
        src/lib.rs
      trace/                  # structured log → ai.log (stub Phase 1)
        src/lib.rs
    mod_identity/             # JWT, profile, nav, session_init
      src/
        lib.rs
        auth_jwt.rs
        identity_profile_get.rs
        identity_nav_counts.rs
        session_init.rs
    mod_billing/              # billing_account_get
      src/
        lib.rs
        billing_account_get.rs
```

### Phase 1+ crates (add folder when phase starts)

| Phase | Crate |
|-------|--------|
| 3 | `mod_referral` |
| 4 | `mod_chat` |
| 5 | `mod_log` |
| 6 | `mod_device` |
| 7 | `mod_skill`, `mod_consumption`, `mod_llm` |
| 8 | `mod_site` |
| 9 | `mod_tx` |

### Dependency direction

```
server_ai → wire_ws, wire_http → mod_identity, mod_billing → store, proto
                              → system/ctx, system/trace
```

`mod_*` must not depend on `wire_ws` or `server_ai`.

### Inside a `mod_*` crate

One concern per file; names `domain_action`:

```
mod_identity/src/
  identity_profile_get.rs
  identity_put.rs
  session_init.rs
```

Use `=================================` / `---------------------------------` section separators in larger files.

## Flutter (Phase 2)

```
clients/app/
  pubspec.yaml
  lib/
    main.dart
    c/
      conn/                   # WS, watermark, session_init
      pb/                     # generated from _/schemas/proto
      utils/ext/_log.dart
    pages/
      page_home.dart
      page_bots.dart
      page_devices.dart
      page_sites.dart
    widgets/
      ui/                     # ui_appbar, ui_master_detail, …
      io/
      in/
```

## Remotes (Phase 6)

```
remotes/
  Cargo.toml
  c_remote_core/
  c_remote_windows/
  c_remote_android/
```

Proto: path-dep `../servers/crates/proto` or shared `_/scripts/protoc`.

## Config & env

| Var | Purpose |
|-----|---------|
| `LISTEN` | HTTP bind (default `0.0.0.0:8080`) |
| `C35_DB_MIGRATE` | `1` = apply `_/schemas/*.sql` on boot |
| `YB_*` / `POSTGRES_*` | Yugabyte connection |
| `C35_JWT_SECRET` | WS `?jwt=` validation |
| `NATS_URL` | optional Phase 5+ |

See `servers/server_ai/.env.example`.

## What not to create early

- Empty `mod_site` / `mod_tx` crates until their phase
- Duplicate proto under `clients/` by hand
- Root-level `crates/` directory
- `file.sql` until CAS strategy is locked

## Related docs

- [server.md](server.md) — crate roles, deployment
- [roadmap.md](roadmap.md) — phase map
- [architecture.md](architecture.md) — system overview
