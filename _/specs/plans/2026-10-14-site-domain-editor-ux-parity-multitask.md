# Site editor domains — CSA verify UX + Publish placement — Multitask Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans`. One **Task subagent per track** in each wave; parent dispatches parallel tracks, does not implement all lanes inline.
>
> **Specs (read first):** [`spec.md`](../../../spec.md) · [`_/specs/site.md`](../../../_/specs/site.md) · prior buy plan [`2026-10-08-site-domain-buy-mail-multitask.md`](2026-10-08-site-domain-buy-mail-multitask.md)

**Goal:** Bring c35 site **custom domain** editor UX to CSA parity on **verification flow** (guided DNS dialog, i18n, post-add flow, TLS progress) and **placement** (domains on **Publish**, not buried under Capabilities). Reuse existing `site.domain` RPCs — no new registrar/buy work.

**Architecture:**

- Extract a single **domain panel** widget + small **TLS poll helper** used from **Publish** (primary) and optionally a **Domains** rail item. Remove duplicate domain UI from Capabilities or replace with a one-line link to Publish.
- **DNS dialog** matches CSA copy (Cloudflare grey-cloud warning, apex hint per `site.md`). All strings via `site.domain.*` in `en.json` / `id.json` (+ `translation.sql` if keys are seeded for web).
- **TLS polling** is client-only: after DNS verify succeeds, poll `domainVerify` (or `domainList` + row `tls_status`) every ~4s until `ready` / `failed` / `disabled` or ~3 min — mirror CSA `ui_site_publish_section.dart` `_startCertPoll` behavior without adding a new RPC.

**Tech stack:** Flutter `clients/app`; existing `SiteApi` (`domainList`, `domainPut`, `domainVerify`, buy/search/check). Verify: `._\scripts\dev\verify_flutter_app.ps1`, `check_utf8_sources.ps1 -Changed -Fix`. No server deploy required unless docs-only.

## Global constraints

- Guest URLs stay `https://alienai.id/{alien_id}/…`; custom host is separate `Host` header (`site.md`).
- CNAME target UI copy: **`site.alienai.id`** (grey / DNS only). Do not point customers at orange `alienai.id`.
- Do not copy Cloudflare tokens from `D:\csa_site_published`.
- Prompt-first unchanged: keep `inst.site.domain` + `site.domain_put` / `site.domain_verify` tools.
- Do not commit unless the user asks.
- Subagents: `model: inherit` only (`subagent-model.mdc`).

## Explicitly out of scope

| Item | Notes |
|------|--------|
| New registrar / wallet / `site.domain_order` | Shipped in 2026-10-08 plan |
| Wildcard domains | Future |
| Refund / cancel Cloudflare registration from UI | Detach row only |
| Provider web grounding / new MCP | N/A |

## Reference (CSA)

| What | Path |
|------|------|
| Publish + domains + cert poll | `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_publish_section.dart` |
| DNS verify dialog | `D:\csa_site_published\clients\app\lib\widgets\site\io_custom_domain_dialogs.dart` (`ioCustomDomainCnameDialogOpen`) |
| Domain cards | `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_custom_domain_section.dart` |
| EN/ID strings (`dnsTitle`, `dnsBody`, …) | `D:\csa_site_published\clients\app\assets\translations\en.json` under `site.domain` |

## c35 today (starting point)

| What | Path |
|------|------|
| Domain logic in Settings | `clients/app/lib/widgets/sites/editor/ui_site_settings_editor.dart` |
| Cards | `clients/app/lib/widgets/sites/editor/ui_site_domain_section.dart` |
| DNS dialog (hardcoded EN) | `clients/app/lib/widgets/sites/io_site_domain_dialogs.dart` |
| Publish (no domains) | `clients/app/lib/widgets/sites/editor/ui_site_publish_editor.dart` |
| Helpers | `clients/app/lib/c/site/site_domain.dart`, `site_api.dart` |

---

## Multitask map

```
WAVE 1 — Docs + i18n (parallel)
  D0  site.md editor UX subsection (Publish placement, apex copy rules)
  L1  site.domain DNS/TLS/publish strings (en, id, translation.sql optional)

WAVE 2 — Shared client modules (parallel after L1 keys exist)
  U1  DNS dialog CSA parity (io_site_domain_dialogs.dart)
  C1  SiteDomainEditorController + UiSiteDomainPanel (extract from settings)

WAVE 3 — Editor shell (after C1)
  P1  Publish editor: public URL + domain panel + TLS poll wiring
  N1  Nav: Domains item OR Publish-only (pick one in D0; default Publish-only)
  S1  Capabilities: remove domain block; link to Publish

WAVE 4 — Polish + tests (parallel)
  R1  Typed remove confirm for bought (and optional BYO)
  T1  Widget tests (dialog + panel behaviors)
  V1  verify_flutter_app + manual checklist
```

### Agent assignments

| Wave | Track | Files only this track may edit |
|------|-------|--------------------------------|
| 1 | D0 | `_/specs/site.md` (editor UX bullets only) |
| 1 | L1 | `clients/app/assets/translations/en.json`, `id.json`, `_/schemas/translation.sql` (if adding keys there) |
| 2 | U1 | `clients/app/lib/widgets/sites/io_site_domain_dialogs.dart` |
| 2 | C1 | **Create** `clients/app/lib/widgets/sites/editor/site_domain_editor_panel.dart`, **Create** `clients/app/lib/c/site/site_domain_tls_poll.dart`; **Modify** `ui_site_settings_editor.dart` (shrink to use panel or strip domains) |
| 3 | P1 | `ui_site_publish_editor.dart`, `ui_site_editor_shell.dart` (pass `api`, `siteIid` into publish if needed) |
| 3 | N1 | `ui_site_editor_menu.dart`, `site_editor_nav.dart`, `platform_site_editor_test.dart` (if menu changes) |
| 3 | S1 | `ui_site_settings_editor.dart` (capabilities-only + link) |
| 4 | R1 | `ui_site_domain_section.dart` or `io_site_domain_dialogs.dart` (remove confirm) |
| 4 | T1 | `clients/app/test/site_domain_editor_test.dart` (new) |
| 4 | V1 | verification scripts only (no feature edits) |

C1 owns the panel API; P1/S1 only **import** `UiSiteDomainPanel` — do not fork verify logic.

---

# WAVE 1

## Track D0 — Docs

**Modify:** `_/specs/site.md` — add short **Site editor (domains)** subsection under Custom domains or Flutter admin:

- Domains UI lives on **Publish** (primary); Capabilities holds feature toggles only.
- BYO verify flow: add hostname → DNS instructions dialog → Verify (server `site_domain_verify`).
- Copy must mention **grey cloud** on Cloudflare and **apex** A/AAAA / ALIAS option (link to customer DNS table already in spec).
- TLS: UI may poll `tls_status` after DNS verify; no PEM in DB.

No change to verify algorithm or CNAME target env vars.

## Track L1 — Locales

Port CSA `site.domain` keys missing in c35 (minimum):

| Key | Purpose |
|-----|---------|
| `dnsTitle` | Dialog title |
| `dnsBody` | Intro with `{domain}`, `{target}` + Cloudflare grey-cloud paragraph |
| `dnsType`, `dnsHost`, `dnsTarget` | Row labels |
| `dnsApexHint` | Apex-only extra line (A/AAAA or CNAME flatten) — new, spec-aligned |
| `cnameNotFound` | Failed verify in dialog (with `{target}`) |
| `dnsInstructions` | Card button: open dialog without verifying |
| `copyTooltip` | Copy icon on DNS rows |
| `addExpiresHint` | Add dialog footer (24h BYO) |
| `removeTypeToConfirm` | Typed remove label |

Mirror EN → ID (rewrite for ID, not literal). Align `io_site_domain_dialogs.dart` and add dialog in `ui_site_domain_section.dart` to use `.tr()`.

**Acceptance:** No hardcoded user-facing DNS strings left in domain dialog / panel.

---

# WAVE 2

## Track U1 — DNS dialog

**Modify:** `clients/app/lib/widgets/sites/io_site_domain_dialogs.dart`

- Title/body/actions use L1 keys (match CSA `ioCustomDomainCnameDialogOpen` structure).
- On verify failure: show server message when `verify_error` passed in; else `site.domain.cnameNotFound`.
- If `siteDomainIsApex(hostname)` helper (new in `site_domain.dart`): show `dnsApexHint` below CNAME rows.
- Optional: `host` row shows registrable host label (e.g. `www` vs `@`) — if too heavy, keep full FQDN like CSA but add apex hint for apex rows only.

**Acceptance:** Side-by-side with CSA EN strings, dialog reads the same; copy buttons work.

## Track C1 — Shared panel + controller

**Create:** `site_domain_tls_poll.dart`

```dart
// Poll domainList or domainVerify until tls terminal or max ticks.
class SiteDomainTlsPoll { ... }
```

Constants: `interval = 4s`, `maxTicks = 45` (CSA parity). Cancel on dispose.

**Create:** `site_domain_editor_panel.dart`

- Stateful widget: `api`, `siteIid`, optional `onDomainsChanged`.
- State: `_domains`, `_domainsBusy`, `_checkingDomainId`, `_fixingDomainId`, `SiteDomainTlsPoll?`.
- Methods moved from `ui_site_settings_editor.dart`: `_load`, `_addDomain`, `_buyDomain`, `_removeDomain`, `_verifyDomain`, `_runVerify`, `_fixHttps`.
- **BYO add:** after successful `domainPut`, `ioSiteDomainDnsDialogOpen` immediately (CSA `_addDomain` → `_openDomainConfig`).
- **BYO verify:** card **Verify** opens DNS dialog with `onCheck: _runVerify`.
- **Bought:** verify without dialog unless DNS still pending (keep current server-driven DNS).
- On `_runVerify` success with DNS ok and TLS not terminal → start TLS poll.

**Modify:** `ui_site_settings_editor.dart` — delete inlined domain block; either remove section or temporary `TextButton` → navigate to Publish (until P1 lands).

**Acceptance:** Panel works when embedded in a test harness `MaterialApp` with mock `SiteApi` (T1) or manual run on Capabilities during transition.

---

# WAVE 3

## Track P1 — Publish editor

**Modify:** `ui_site_publish_editor.dart`

- Change to `StatefulWidget` if needed for panel state, or embed `UiSiteDomainPanel` as child.
- Above publish button: show **Public URL** `https://alienai.id/{alien_id}` (from `SiteRow` / draft handle — same as CSA `sitePublicUrl`).
- Below description: full `UiSiteDomainPanel`.
- Keep existing publish button / version row.

**Modify:** `ui_site_editor_shell.dart`

- Pass `widget.api` and `_siteIid` into `UiSitePublishEditor`.

**Acceptance:** Open site editor → **Publish** → add BYO domain → DNS dialog opens → verify → HTTPS chip moves pending → ready without manual Fix HTTPS when TLS sync enabled on cluster.

## Track N1 — Navigation (default: Publish-only)

**Default (recommended):** No new menu item; domains only on Publish (CSA).

**Optional:** Add `SiteEditorMenuItem('domains', …)` that shows the same `UiSiteDomainPanel` in a thin wrapper — only if Publish feels overcrowded. If added, wire in `ui_site_editor_shell.dart` switch; update `platform_site_editor_test.dart`.

## Track S1 — Capabilities cleanup

**Modify:** `ui_site_settings_editor.dart`

- Remove `UiSiteDomainPanel` duplicate.
- Add muted line + link: “Custom domains are configured under **Publish**.” (i18n `site.domain.movedToPublish`).

**Acceptance:** Capabilities page has no domain cards; Publish has full UI.

---

# WAVE 4

## Track R1 — Typed remove

**Modify:** `ui_site_domain_section.dart` (or new `io_site_domain_remove_dialog.dart`)

- For **bought** domains (required): CSA-style type hostname to confirm (`ioCustomDomainRemoveConfirmOpen`).
- BYO: keep simple confirm or same typed flow (product choice: **bought only** to reduce friction).

Wire `onRemove` from panel.

## Track T1 — Tests

**Create:** `clients/app/test/site_domain_editor_test.dart`

- `siteDomainIsApex` / normalize helpers (if added).
- Widget: DNS dialog shows `dnsBody` with target; verify failure shows error text.
- Widget: panel disables Add when `siteDomainPendingByo`.
- Optional: pump panel + mock API returning one unverified row → tap Verify → dialog visible.

Run: `flutter test clients/app/test/site_domain_editor_test.dart` from `clients/app`.

## Track V1 — Verify

```powershell
.\_\scripts\dev\check_utf8_sources.ps1 -Changed -Fix
.\_\scripts\dev\verify_flutter_app.ps1
```

**Manual checklist**

1. BYO: Add `www.example.com` → dialog opens → copy target → Verify fails before DNS → succeeds after DNS (staging hostname).
2. Bought row (if available): no misleading CNAME dialog on verify; email chip still shown when mail onboard runs.
3. Publish + Capabilities: domains only on Publish; link on Capabilities works.
4. ID locale: DNS dialog strings in Indonesian on `/id/` app language.
5. Home: “Connect domain X to my site” still hits `site.domain_put` / `site.domain_verify` (smoke `prompt_compose` optional).

---

## Risk notes

| Risk | Mitigation |
|------|------------|
| TLS never reaches `ready` in dev (`C35_TLS_SYNC_ENABLED=0`) | Poll stops at `disabled` / timeout; copy explains cluster TLS |
| Duplicate UI if S1 not merged with P1 | C1 single panel; S1 must strip settings domains |
| Apex users follow wrong record | `dnsApexHint` + spec table in dialog |

## Success criteria

- Verification UX subjectively matches CSA (guided dialog, i18n, post-add open, Cloudflare hint).
- Domains discoverable on **Publish**.
- No regression on buy/search/check RPCs.
- Flutter analyze clean; new tests pass.

---

## Parent dispatch order

1. Wave 1: dispatch **D0** + **L1** in parallel.
2. Wave 2: **U1** + **C1** in parallel (C1 can stub EN keys until L1 merges).
3. Wave 3: **P1** then **S1**; **N1** only if D0 chose optional Domains menu.
4. Wave 4: **R1** + **T1** parallel, then **V1**.

End parent reply with: plan path and “dispatch wave 1 when ready to implement.”
