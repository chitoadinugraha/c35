# Referral tree & staff roles (LOCKED)

Status: **locked** 2026-09-27

Referral **upline** lives on `ai.identity.referred_by_iid`. **Branch share %** lives in `ai.referral_share`. Sign-up / package **codes** live in `ai.referral_code`. Commission accrual: [`billing.md`](billing.md) (Commission section).

Related: [`identity.md`](identity.md) (users), [`event.md`](event.md) (admin audit events), [`ui.md`](ui.md) (Referral tree page), [`auth.md`](auth.md) (claim flow).

---

## Global roles (staff)

Staff capabilities for the referral forest are **not** `identity_grant` rows. They are stored on the user row:

| Store | Field | Notes |
|-------|--------|--------|
| `ai.identity.meta` | `global_roles` | JSON array of strings, e.g. `["partner","marketing"]` |
| `ai.identity.meta` | `is_root` | Platform root; forest treats as root even if `global_roles` omits `"root"` |

**Assignable via `admin_user_put` (not on root targets):**

| Role | Director may assign | Root may assign |
|------|---------------------|-----------------|
| `partner` | Yes | Yes |
| `marketing` | Yes | Yes |
| `finance` | Yes | Yes |
| `director` | No | Yes |
| `root` | Never via API | Never via API (`is_root` only) |

Server normalizes: lowercase, dedupe, sort; strips `"root"` from `global_roles` patches.

**Tree node badges (Flutter):** each `ReferralTreeNode` includes `global_roles` from meta and `mailbox_count` (member mailboxes, same basis as `mail.mailbox.list`). The forest card shows a **mail** chip first when `mailbox_count > 0`, then **Root** when `is_root` / legacy root heuristics match, plus chips for other roles (`Partner`, `Director`, `Marketing`, `Finance`) via `referralGlobalRoleLabel`.

**Wide forest load:** staff with wide access load `depth = 1` initially (root/director spine + direct children only); **Expand** loads one more horizontal level per tap (`depth = 1` on that parent). `ReferralTreeSlice.platform_user_count` is set on wide forest responses (active `kind=user` rows); server caches the count ~2 minutes — not recomputed on every page open.

---

## Who sees the full forest

**Wide access** = load the **entire** referral forest (`referral_tree_get` with `root_id = 0`), not only the viewer’s downline.

| Viewer | Wide forest |
|--------|-------------|
| Root (`is_root` or dev root uid) | Yes |
| `global_roles` contains `director` | Yes |
| `global_roles` contains `partner` | Yes |
| Everyone else | Own subtree only (viewer as start, or expand branches) |

**Server:** `c35_mod_admin::referral_tree_wide_access` (used by `mod_referral::referral_tree_get`).

**Client:** `referralTreeWideAccess` — session `global_roles` + loaded node roles; must match server (do not infer edit rights from wide access).

---

## Admin RPC (`admin_user_*`)

Wire: `ReqAdminUserSearch`, `ReqAdminUserPut` in [`../schemas/proto/c35/admin.proto`](../schemas/proto/c35/admin.proto). Handler: `c35_mod_admin::admin_user_put` via HTTP invoke.

### Search

`admin_user_search` — any **referral staff** (root, director, partner). Used for “set referred by” picker and profile admin.

### Put — permission matrix

| Field | Root | Director | Partner |
|-------|------|----------|---------|
| `name`, `handle`, `avatar_url`, `auth_email` | Yes | No | No |
| `referred_by_uid` (set parent or `0` = clear) | Yes | Yes | No |
| `global_roles` (`AdminGlobalRolesPatch.roles`) | Yes | Yes (limited roles) | No |

**Rules (all roles that may write):**

- Cannot change referrer or roles on a **root user** target.
- Referrer: no self-reference; no cycles (target’s downline cannot become referrer).
- Email/handle uniqueness enforced against `identity_provider` / `alien_id`.

**Client profile dialog:**

- **Edit user** menu (name, email, handle, pic, referrer) — **root only**.
- **Referrer** menu (set / clear) — **director** when not root (root uses Edit menu).
- **Roles** section — tap to edit — **root or director**.
- Wallet adjust / commission simulate — unchanged (director/root finance rules in billing UI).

---

## Event audit (who changed what)

Every successful `admin_user_put` side effect emits an **event** row (`class=event`) and NATS on the **actor’s** user timeline:

`owner_iid` = viewer who performed the change (director/root), not the target user.

| `event_kind` | When | Useful `meta` |
|--------------|------|----------------|
| `admin.user_profile_updated` | Name, handle, avatar, email | `actor_iid`, `target_iid`, `fields` |
| `admin.user_referrer_updated` | Referrer set or cleared | `from_referred_by_iid`, `to_referred_by_iid` |
| `admin.user_roles_updated` | `global_roles` patch | `roles_before`, `roles_after`, `roles_added`, `roles_removed` |

Catalog + English templates: [`event.md`](event.md) (Catalog — admin).

**Query examples (Yugabyte / MCP):**

```sql
-- Who promoted someone to partner recently
SELECT id, owner_iid, text, meta, created_ts
FROM ai.log
WHERE event_kind = 'admin.user_roles_updated'
  AND meta->'roles_added' ? 'partner'
ORDER BY created_ts DESC
LIMIT 50;

-- All admin actions by one staff uid
SELECT event_kind, text, meta, created_ts
FROM ai.log
WHERE owner_iid = 99000
  AND event_kind LIKE 'admin.user_%'
ORDER BY created_ts DESC
LIMIT 100;

-- Referrer changes on a target user
SELECT owner_iid, text, meta, created_ts
FROM ai.log
WHERE event_kind = 'admin.user_referrer_updated'
  AND (meta->>'target_iid')::bigint = 123456789
ORDER BY created_ts DESC;
```

Filter triggers and reports on **`event_kind` + `meta`**, not localized `text`.

---

## Referral tree RPC (read path)

| RPC | Role |
|-----|------|
| `referral_tree_get` | Slice of forest; wide vs subtree per viewer (above) |
| `referral_share_set` | Parent sets child branch % (own downline or staff) |
| `referral_code_*` | Issuer-owned codes |
| `referral_user_stats` | Stats + wallet snapshot; contact fields for root/director on others |

Proto: [`../schemas/proto/c35/referral.proto`](../schemas/proto/c35/referral.proto). Server: `c35_mod_referral`.

---

## UI entry

- Page: `clients/app/lib/pages/referral/page_referral_tree.dart`
- Forest chart + node badges: `ui_referral_forest_chart.dart`, `ui_referral_forest_node.dart`
- User profile / admin actions: `ui_referral_user_profile_dialog.dart`
- Session roles: `Session.globalRoles` / `Session.isRoot` (from sign-in / session init)

Avatar menu → **Referral tree** ([`ui.md`](ui.md)).

---

## Implementation map

| Layer | Location |
|-------|----------|
| Wide access + `admin_user_put` RBAC | `servers/crates/mod_admin/src/lib.rs` |
| Event emit | `servers/crates/mod_admin/src/admin_event.rs`, `c35_mod_event` catalog |
| Tree SQL | `servers/crates/mod_referral/src/lib.rs` |
| Invoke router | `servers/crates/wire_http/src/invoke.rs` (`admin_user_put` passes NATS for emit) |
