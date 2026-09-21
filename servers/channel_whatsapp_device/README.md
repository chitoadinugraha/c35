# cs-channel-whatsapp

Linked-device WhatsApp worker (`wa-rs`). One runtime per account; session persisted in Postgres.

---

## Session lifecycle

### Storage

| Layer | Location | Lifetime |
|---|---|---|
| Durable auth | `ai.asset_channel.session_data.sqlite_session_b64` | Until paired success, explicit abort, lease expiry, or invalidation |
| Runtime file | `/app/sessions/whatsapp_channel_{id}.db` (pod `emptyDir`) | Restored from DB on start; ephemeral across pod restarts |
| Pair watch | `session_data.pair_watch_until_ms` (Unix ms) | Set by cs-server while app is pairing |

Minimum blob size to persist: **8192 bytes** (incomplete pairing never saved).

---

## Flow

```
App pair dialog open
  → pair_start (cs-server)
      status = pairing, session fields cleared
      pair_watch_until_ms = now + 5 min
      NATS pair event + worker restart
  → worker starts bot, emits QR only while pair_watch active
  → channelGet every ~3s extends pair_watch + 2 min

Scan QR success
  → status = active, phone_jid set
  → sqlite blob written to DB
  → worker keeps running (poll also starts active channels)

Pod restart
  → poll restores blob → reconnect without re-scan
```

---

## Cleanup (session removed)

| Trigger | DB | Worker | Asset row |
|---|---|---|---|
| **Pair success** | Session **kept** | Keeps running | Kept, `active` |
| **Cancel** (dialog button) | Cleared, `disconnected` | `/stop` | Deleted if new channel; kept if re-pair |
| **Pair error** | `error` + message; no valid blob | Stops on error | Kept |
| **Invalid saved session** (reconnect fails) | `error`; no background QR | Stops | Kept |
| **Dialog dismissed** (tap outside) | Lease expires ~2 min after last poll → same as abort | Stopped on expiry | Kept |
| **Logged out from phone** | `error` message | May stop | Kept |

`channel_abort_pairing` clears: `qr_raw`, `phone_jid`, `sqlite_session_b64`, `pair_watch_until_ms`.

---

## On-demand pairing

- **Poll loop** starts only `status = 'active'` channels (reconnect after deploy).
- **Pairing** starts only via `pair_start` (NATS `cs.act.channel.whatsapp.pair`).
- **QR** is not emitted when `pair_watch_until_ms` expired or when reconnecting an invalid saved session (`was_active`).
- **Expired pairing** cleanup runs each poll tick: stop runtime, abort session, log `pair_expired`.

---

## One channel per account

- Poll: `DISTINCT ON (owner_uid)` for linked WhatsApp channels.
- Worker stops duplicate runtimes for the same `owner_uid`.
- Server: `channel_whatsapp_deactivate_siblings` on pair start and cloud connect.

---

## HTTP (internal)

| Route | Action |
|---|---|
| `POST /v1/channel/{id}/restart` | Stop + start bot (pair start) |
| `POST /v1/channel/{id}/stop` | Stop bot (pair abort) |
| `GET /v1/channel/{id}/status` | Read DB status / QR |

Set `WHATSAPP_WORKER_URL` on cs-server so pair start/abort can call these.

---

## Logs

Worker and server write to `ai.log` (`kind`: `pair_start`, `qr`, `connected`, `pair_expired`, `pair_abort`, `error`, …). Shown in app channel log sheet.

---

## Deploy

```powershell
.\_\deployments\publish.ps1 -Target whatsapp
```

Pair watch lease is set by **cs-server** (`pair_start`, `channel_get`). Deploy server when changing pairing behavior:

```powershell
.\_\deployments\publish.ps1 -Target server
```

Both run on **linux/arm64** (btm cluster). Pod includes WARP mesh sidecar for Cloudflare egress.
