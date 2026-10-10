# Time range wire format

Shared contract for **tool `params`** and **server parsers**. One shape for all modules (site queries, tx list, consumption day bounds, expense, billing history, etc.). Do not add per-period tools or per-phrase Rust date routers.

## Precedence

1. **`time_from_ms` / `time_to_ms`** — UTC epoch ms (either may be omitted for open-ended).
2. **`date_from` / `date_to`** — inclusive `YYYY-MM-DD` in the resolved timezone.
3. **`range`** — named calendar window in the resolved timezone.

## Fields

| Field | Type | Notes |
|-------|------|--------|
| `range` | string | `today`, `yesterday`, `this_week`, `last_week`, `this_month`, `last_month`, `mtd`, `ytd`. Alias: `month_to_date` → `mtd`. |
| `date_from`, `date_to` | string | `YYYY-MM-DD` |
| `time_from_ms`, `time_to_ms` | int64 | UTC |
| `tz` | string | IANA e.g. `Asia/Jakarta`. Omit on tool calls; server fills from user prefs / locale. |

## Named ranges

| Token | Window (in `tz`) |
|-------|------------------|
| `today` | Local calendar day |
| `yesterday` | Previous local day |
| `this_week` | ISO week Mon–Sun |
| `last_week` | Prior ISO week |
| `this_month` | Full calendar month |
| `last_month` | Previous calendar month |
| `mtd` | Month start through **today** (inclusive) |
| `ytd` | Jan 1 through **today** (inclusive) |

Empty / missing range with no ms or dates → **unbounded** (caller may default e.g. `today` via inst).

## Rust (`c35_time_range`)

| API | Use |
|-----|-----|
| `DATE_RANGE_INST` | Compose / inst body text |
| `date_range_prompt_block(tz)` | Append to system prompt with default tz note |
| `wire_from_params(&Value)` | Parse JSON tool params |
| `date_range_from_params(params, default_tz)` | Resolve with `Utc::now()` |
| `date_range_from_params_at(params, now, default_tz)` | Tests / deterministic replay |
| `named_range_at(range, now, tz)` | Named token only |
| `range_key_normalize(s)` | Aliases |
| `timezone_default_from_locale(locale)` | `id*` → `Asia/Jakarta`, else `UTC` |

`c35_mod_site::query::params::query_time_range` delegates here (default tz `UTC` unless `params.tz` set).

## Inst

- **`inst.core.date_range`** — trigger `wire:date_range`; matched on every Home turn via compose signal. Body mirrors `DATE_RANGE_INST` (editable live with `inst_put`).
- Task insts (`inst.site.report`, `inst.site.tx_browse`, …) only map **intent → `query_id`**; periods use standard `params`, not custom fields.

## Model vs server

- **`[CURRENT TIME]`** (`prompt/time.rs`) — answer “what day is it” from the clock block.
- **`[DATE RANGE]`** — how to fill **tool params** when filtering data.

Server may inject `tz` on tool exec from `time_timezone_resolve` (future); parsers always accept explicit `params.tz`.
