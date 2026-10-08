# Device control — Chito (99000) consent

Mirrored for Cursor: [`.cursor/rules/device-control-chito.mdc`](../../.cursor/rules/device-control-chito.mdc)

## Allowed without extra confirmation

When the user asks to **debug, fix, or test remote / computer use** (streaming, Hyper-V agent, screenshots, shell on paired PCs):

- Use **`owner_iid` / `uid` = 99000** (Chito) for MCP `tool_exec`, `device_screenshot`, `device_command`, `device_input`, and `prompt_run` / `computer_use.delegate` on **their** paired devices.
- Use **`device_list` / `device_get`** (when shipped) to resolve `device_iid` and confirm the row’s `owner_iid` is **99000** before any mutating action.
- Use **`device_log_tail`**, **`log_tail`**, **`yb_query`** on `ai.log` / `ai.identity` for **99000** to diagnose agent WebRTC and presence.

## Forbidden unless the user explicitly says so

- **`device.command`**, **`device.input`**, **`device.screenshot`**, or **`computer_use.delegate`** targeting devices **not** owned by **99000**.
- Passing a different **`owner_iid`** to impersonate another user’s devices without the user naming that owner and device in the same thread.
- Destructive or irreversible shell commands on **99000** devices without stating intent in the reply — prefer read-only diagnostics first.

## Defaults

| Context | `owner_iid` |
|---------|-------------|
| Chito’s real machines, app repro, Hyper-V | **99000** |
| Automated regression, seeds | **33000** (tester) |

## Workflow

1. `device_list` or SQL → confirm device id and **owner_iid = 99000**.
2. `device_log_tail` / `log_tail` → agent WS + WebRTC clues.
3. `device_screenshot` or `device.command` (read-only) → verify capture path.
4. Only then `device.input` / delegate for UI automation.

Server allowlist: **33000** and **99000** only — see `_/specs/mcp-security.md`.
