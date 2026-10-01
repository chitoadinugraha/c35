# test_empus

## Phase 1 — Google Sheet only (no browser)

Export **nama** + **no_kartu** (+ sheet row) for parallel ePus workers:

```powershell
cd _/scripts/test_empus
python sheet_export.py              # all rows with NO KARTU
python sheet_export.py --mode todo  # only rows with empty FASKES
python shard_queue.py --parts 8     # data/shards/shard-00.json ...
```

Outputs:

| File | Use |
|------|-----|
| `data/participants.jsonl` | One JSON per line — best for workers |
| `data/participants.csv` | Human check |
| `data/queue.json` | Same list (legacy name for `extract.py`) |

## Phase 2 — ePus by no_kartu (browser extension)

Set `shard_json` in `config.json` per worker, e.g. `"shard_json": "data/shards/shard-00.json"`.

```powershell
python extract.py   # uses participants.jsonl or shard_json; needs agent + ePus tab
```

Transport: `c35_agent.py` → `POST /v1/mcp/agent` (`C35_SERVER_URL`, `C35_MCP_AGENT_KEY`).
