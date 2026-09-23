# Skill

Status: **locked** 2026-09-20 | **Self-learning design added** 2026-09-21

Automations the AI can run on behalf of the user — taught interactively, imported, or installed from catalog. Phase 7 adds a **self-learning execution loop** where the agent explores tasks on first run, records them as skills, self-repairs on UI change, and optionally contributes to the shared catalog.

## Reference

| Project | Borrow |
|---------|--------|
| `D:\cs_agent` | `agent.skill`, `skill_step`, `skill_catalog*`, `secret` |
| c35 identity | `device_iid` replaces `space_id`; scope adds `team` |

## Scope

| Scope | Binding | Use |
|-------|---------|-----|
| `user` | owner_iid | Personal assistant on any surface |
| `device` | device_iid (remote/iot identity) | Run on paired Windows/Android agent |
| `team` | team_iid | Shared team playbook |
| `global` | platform | Root-curated defaults |

## Tables

See [`../schemas/skill.sql`](../schemas/skill.sql).

| Table | Synced | Notes |
|-------|--------|-------|
| `skill` | yes | Main doc; `hash_blake3` of body; adds circuit-breaker fields in Phase 7 |
| `skill_step` | yes | UI automation tape |
| `skill_secret` | yes | Encrypted credentials for steps |
| `skill_catalog*` | server | Marketplace registry; not owner-delta synced |

## Wire

Proto: [`../schemas/proto/c35/skill.proto`](../schemas/proto/c35/skill.proto)

- `ReqSkillList` / `ReqSkillPut` — CRUD
- `ReqSkillCatalogList` / `ReqSkillCatalogInstall` — marketplace
- `ReqSkillCatalogSearch` — fuzzy search by `target_app` + `phrases_json` (Phase 7, before auto-submit)

Sync collection name: `skill` (includes steps inline on full get).

---

## Self-Learning Execution Loop (Phase 7)

The full autonomy loop for computer use tasks:

```
User request
    │
    ▼
1. Dispatcher: search local skills by phrases_json + target_app + url_pattern
    │
    ├── Found (confidence ≥ threshold) ──► 2. Execute from skill tape
    │                                            │
    │                                    Success ──► consecutive_ok++
    │                                            │   ≥5 → evaluate catalog push
    │                                    Failure ──► 4. Self-heal
    │
    └── Not found ──► 3. First-time AI exploration
                            │
                            └── Record steps → ReqSkillPut (source=taught)
```

### 3. First-Time Exploration

- Agent runs task via free-form computer use (screenshot + click + type loop).
- On success: records each step as `skill_step` with `ax_target_json` (accessibility tree selector) + `screenshot_hash`.
- `ReqSkillPut` saves the new skill locally (`scope=device` or `scope=user`).
- Next invocation uses the tape.

### 4. Self-Heal on UI Change

When a skill step fails (element not found, wrong state):

```
Step fails
    │
    ├── patch_count < MAX_PATCHES_PER_DAY (3)?
    │       └── Yes → AI re-explores from the failed step
    │                  │
    │                  ├── Fixed → ReqSkillPut (patch_epoch++)
    │                  │           consecutive_ok resets
    │                  └── Re-explore also fails → patch_count++, retry next time
    │
    └── patch_count >= 3 within 24h → status = 'needs_review', auto_run = false
                                       Notify user
```

**Circuit-breaker fields added to `ai.skill`:**

| Column | Type | Purpose |
|--------|------|---------|
| `patch_epoch` | INT | Monotonic; server rejects PUT if epoch doesn't advance |
| `patch_count` | INT | Resets to 0 on success; caps auto-repair at 3/24h |
| `last_patched_ts` | TIMESTAMPTZ | Cooldown reference |
| `consecutive_ok` | INT | Must reach 5 before catalog push is considered |
| `detected_app_version` | VARCHAR(32) | App version stamped at record time by agent |

### 5. Catalog Dispatch (Before Each Task)

Before executing any task, the dispatcher:

1. Checks **local skills** first (owned, device-scoped, or global installed).
2. If no local match → calls `ReqSkillCatalogSearch(q, target_app, platform)`.
3. Server scores results: `(installs×0.3) + (rating×0.3) + (success_rate×0.3) + (recency×0.1)`, filtered by `target_app_version_min/max` against the agent-reported app version.
4. If catalog match found → `ReqSkillCatalogInstall` → run immediately.
5. If still no match → trigger first-time exploration.

### 6. Auto-Submit to Catalog (Safe, Dedup, No Infinite Loop)

Triggered only when `consecutive_ok >= 5`.

```
Compute blake3(body_md + steps)
    │
    ▼
ReqSkillCatalogSearch by target_app + phrases_json similarity
    │
    ├── Same hash in catalog → already published, skip
    │
    ├── Same target_app + overlapping version range, diff steps
    │       └── Submit improvement vote; flag for human review
    │           (does NOT create new entry — no collision)
    │
    ├── Same target_app, non-overlapping version range
    │       └── Create new variant release (semver bump)
    │           status = 'pending_review'
    │
    └── No match → Create new catalog entry
            status = 'pending_review'
            User notified: "Your skill was submitted for review"
```

**`pending_review`** entries are visible only to the submitter until:
- A moderator approves, OR
- 3+ other users succeed with the skill (auto-approve threshold).

**Rate limits on auto-submit:**

| Rule | Value |
|------|-------|
| Min time between catalog pushes per skill | 1 hour |
| `patch_epoch` must advance | Server rejects stale PUTs |
| `consecutive_ok` gate | 5 successful runs required |
| Max auto-patches before `needs_review` | 3 per 24 hours |

### 7. App Version Pinning

The agent detects target app version at teach time:
- **Windows**: `GetFileVersionInfo` on target EXE
- **Web**: URL hostname + DOM version fingerprint
- **Android**: package `versionName` via ADB

This stamps `detected_app_version` on `ai.skill` and is stored as `target_app_version_min/max` on the catalog variant.

**Result:** BCA Mobile v5.x and v6.x skills are separate catalog variant releases — not collisions. Old skills stay valid for old app versions. A UI change creates a new release, not an overwrite.

### 8. Ranking Formula (Catalog Search)

```
score = (install_count × 0.3)
      + (rating × 0.3)
      + (success_rate × 0.3)      -- success_count / (success_count + fail_count)
      + (recency_score × 0.1)     -- decays over 90 days

filtered by:
  platform = agent.platform
  target_app matches (fuzzy)
  target_app_version_min <= detected_version <= target_app_version_max

boosted by:
  phrases_json embedding cosine similarity to user request
```

---

## Schema Delta (Phase 7 additions)

### `ai.skill` (local — add columns)

```sql
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS patch_epoch        INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS patch_count        INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS last_patched_ts    TIMESTAMPTZ;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS consecutive_ok     INT NOT NULL DEFAULT 0;
ALTER TABLE ai.skill ADD COLUMN IF NOT EXISTS detected_app_version VARCHAR(32) NOT NULL DEFAULT '';
```

### `ai.skill_catalog_variant` (add version range)

```sql
ALTER TABLE ai.skill_catalog_variant
    ADD COLUMN IF NOT EXISTS target_app_version_min VARCHAR(32) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS target_app_version_max VARCHAR(32) NOT NULL DEFAULT '';
```

### `ai.skill_catalog_release` (add success metrics)

```sql
ALTER TABLE ai.skill_catalog_release
    ADD COLUMN IF NOT EXISTS success_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fail_count    INT NOT NULL DEFAULT 0;
```

### `ai.skill_catalog` (add status + contributor)

```sql
-- status: published | pending_review | rejected
ALTER TABLE ai.skill_catalog
    ADD COLUMN IF NOT EXISTS contributor_iids_json JSONB NOT NULL DEFAULT '[]';

-- Add 'pending_review' and 'rejected' to status check or use VARCHAR without check
```

---

## Wire Delta (Phase 7 additions)

Add to `skill.proto`:

```protobuf
// New: fuzzy search before auto-submit or first-time dispatch
message ReqSkillCatalogSearch {
  string q               = 1;   // free text (phrases, task description)
  string target_app      = 2;
  string platform        = 3;   // windows | android | web
  string app_version     = 4;   // agent-detected target app version
  int32  limit           = 5;
}

message ResSkillCatalogSearch {
  repeated SkillCatalog catalogs = 1;
}

// New: report execution outcome back to server for success_rate tracking
message ReqSkillRunReport {
  int64  catalog_release_id = 1;
  bool   success            = 2;
  string error_hint         = 3;  // step kind that failed, for diagnostics
}

message ResSkillRunReport {}
```

Add to `Skill` message:
```protobuf
int32  patch_epoch            = 21;
int32  patch_count            = 22;
int32  consecutive_ok         = 23;
string detected_app_version   = 24;
```

---

## UI (Phase 7)

- **Teach mode** on Devices page → Skill tab: record steps → `ReqSkillPut`.
- **Skill picker** in prompt tools: match `phrases_json`, `url_pattern`, `target_app` against user request.
- **Catalog browser**: search, install, rate — Phase 7+.
- **`needs_review` banner** on skill row: "Auto-repair paused — this skill needs attention."
- **"Submitted to catalog"** notification after successful auto-submit.

## Task execution

Skills attach to `ai.task` / `ai.task_run` (see [remote.md](remote.md)). A task may reference `skill_id`; dispatch is NATS JetStream → agent server session.

## Deferred

- OpenSkill API routing (fall back to external catalog if internal search misses).
- Cron scheduler worker (`task_trigger.kind=cron`) — table ready; worker is follow-up.
- Embedding-based phrase matching (v1 uses exact + substring; v2 upgrades to cosine on `ai.embed_cache`).
- Skill marketplace payments — `price_usd`, `billing_period` columns already in schema.
