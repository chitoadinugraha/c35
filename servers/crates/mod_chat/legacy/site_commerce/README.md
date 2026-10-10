# Legacy site commerce prefetch (archived)

Moved out of the active prompt path on 2026-10-10. Home chat now uses the standard tool loop only:

1. Compose matches `inst.site.*` and feeds `site.query.run`
2. Model hop 1: `site.query.run { query_id, params }`
3. Model hop 2: reply from compact `llm` + UI `block`

## Files (reference only — not compiled)

| File | Was |
|------|-----|
| `site_report.rs` | Phrase parser `site_report_parse` |
| `site_report_run.rs` | Zero-hop prefetch for aggregates |
| `tx_browse.rs` | Phrase parser `tx_browse_parse` |
| `tx_browse_run.rs` | Prefetch + `tx_browse_cluster_turn` summarize bypass |

Active replacements: `tools/builtin/site_query.rs`, `tx_browse_render.rs`, `c35_time_range`, `inst.core.date_range`.

Regression tests for archived parsers: `tests/legacy_site_commerce_parse_test.rs`.
