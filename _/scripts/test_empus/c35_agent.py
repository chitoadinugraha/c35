"""HTTP client for server_ai /v1/mcp/agent (same transport as Node c35 MCP tool_exec)."""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def load_env_local() -> None:
    path = repo_root() / ".env.local"
    if not path.is_file():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        key, val = s.split("=", 1)
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = val


def _mcp_json_env() -> dict[str, str]:
    path = repo_root() / ".cursor" / "mcp.json"
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        env = (data.get("mcpServers") or {}).get("c35", {}).get("env") or {}
        return {str(k): str(v) for k, v in env.items() if v is not None}
    except (json.JSONDecodeError, OSError):
        return {}


def _test_empus_server_url() -> str:
    path = Path(__file__).resolve().parent / "config.json"
    if not path.is_file():
        return ""
    try:
        u = (json.loads(path.read_text(encoding="utf-8")).get("server_url") or "").strip()
    except (json.JSONDecodeError, OSError):
        return ""
    return u.rstrip("/")


def server_url() -> str:
    load_env_local()
    env = os.environ.get("C35_SERVER_URL", "").strip()
    if env:
        return env.rstrip("/")
    te = _test_empus_server_url()
    if te:
        return te
    mcp = _mcp_json_env()
    return (mcp.get("C35_SERVER_URL") or "https://alienai.id").rstrip("/")


def mcp_key() -> str:
    load_env_local()
    key = (os.environ.get("C35_MCP_AGENT_KEY") or "").strip()
    if not key:
        key = _mcp_json_env().get("C35_MCP_AGENT_KEY", "").strip()
    if not key:
        raise RuntimeError("C35_MCP_AGENT_KEY required (see _/docs/mcp-security.md)")
    return key


def agent_post(action: str, owner_iid: int, body: dict[str, Any]) -> dict[str, Any]:
    url = f"{server_url()}/v1/mcp/agent"
    payload = {"action": action, "owner_iid": owner_iid, **body}
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "X-C35-Mcp-Key": mcp_key()},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as res:
            raw = res.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            data = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            data = {"raw": raw}
        data.setdefault("ok", False)
        data.setdefault("error", f"HTTP {e.code}")
        data["status"] = e.code
        return data
    except urllib.error.URLError as e:
        return {"ok": False, "error": f"agent HTTP request failed: {e.reason}", "url": url, "action": action}
    if not raw:
        return {"ok": False, "error": "empty response", "url": url, "action": action}
    data = json.loads(raw)
    if isinstance(data, dict) and data.get("ok") is not False:
        data.setdefault("ok", True)
    return data


def tool_exec(tool_name: str, args: dict[str, Any], owner_iid: int = 99000) -> dict[str, Any]:
    return agent_post(
        "tool_exec",
        owner_iid,
        {"tool_name": tool_name, "args_json": args, "locale": "id-ID"},
    )


def device_list(owner_iid: int = 99000) -> dict[str, Any]:
    return agent_post("device_list", owner_iid, {})
