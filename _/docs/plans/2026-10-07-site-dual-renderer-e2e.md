# Site dual renderer — E2E checklist (I1)

Plan: [`2026-10-07-site-dual-renderer-multitask.md`](2026-10-07-site-dual-renderer-multitask.md) · Wave 7 · Track **I1**

Manual verification before ship (picker, boot preview, prompt tools).

---

## Checklist

- [ ] User with 10 sites: welcome has no site chips; picker lists all.
- [ ] Chat `site.create` → card expands → widget preview matches guest HTML smoke (same title/hero).
- [ ] Draft Visit URL works in browser.
- [ ] `@site` → `site.patch` / `site.publish` in `prompt_run`.
- [ ] UITable product edit still syncs; widget `product_grid` updates after refresh.
- [ ] WebView flag off: Preview tab still usable.

---

## Prompt compose (T4 regression)

| Phrase | Expect |
|--------|--------|
| `enable POS on @test-site` | `inst.site.capabilities` or mention `inst.web.builder`; `site.config.put` in selected tools |
| `compare profit warung` | `inst.site.compare`; `site.query.run` fed |

Run MCP `prompt_compose` with `owner_iid` **33000** (automated tester) and spot-check **99000** after deploy.
