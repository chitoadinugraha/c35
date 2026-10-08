# App realtime NATS lane (`c35.user.{owner_iid}.app.*`)

Canonical doc: [`_/specs/sync.md`](../../_/specs/sync.md) — **App realtime lane**.

## Hard rule

Flutter unsolicited pushes → `c35.user.{owner_iid}.app.<tail>` via `c35_nats::user_app_subject_*` in `servers/crates/system/nats/src/user_app.rs`.

Never publish app UI state on `c35.user.{iid}.ev.*` or legacy flat subjects (`c35.user.{iid}.balance`, `c35.user.{iid}.chat.*` without `.app.`).

WS: subscribe `user_app_subscribe_subject(owner_iid)`; decode `user_app_fanout_decode`.

Events: `c35.user.{iid}.ev.{slug}` — not on app WS unless admin log subscribe.
