# Project Rules & Guidelines (`c35`)

This workspace adheres to the unified project rules and documentation standards defined in `.cursor/rules/`, `spec.md`, and `_/docs/`.

---

## 1. Documentation & Specs (Read Before Implementing)

- **Source of Truth**: Read [`spec.md`](./spec.md) for locked architectural decisions, phase scope, and the documentation index before implementing features or changing behavior.
- **Module Specs**: Read the relevant module specifications under `_/docs/` (e.g. `identity.md`, `chat.md`, `ui.md`, `inst.md`, `remote-agent.md`).
- **Schemas**: Inspect `_/schemas/` for SQL tables and Protobuf contracts when touching database models or wire types.
- **Spec Precedence**: If code and documentation disagree, follow the documentation — or update the documentation first before implementing. Never invent architecture or scope beyond what the specs define.

---

## 2. Verification After Edits

Before concluding any task that modifies code or scripts, run the relevant checks and ensure there are no errors:

- **PowerShell (`*.ps1`, `dev_*.ps1`)**:
  ```powershell
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile('PATH.ps1', [ref]$null, [ref]$errors)
  if ($errors) { $errors | Format-List; exit 1 }
  ```
  Use ASCII quotes only; prefer `('-s', ('"' + $path + '"'))` over nested backtick quotes.
- **Rust (`servers/**/*.rs`)**:
  ```powershell
  cd servers
  cargo build -p server_ai
  ```
  Run `cargo test -p <CRATE>` when touching crates with unit tests.
- **Flutter / Dart (`clients/app/**`)**:
  ```powershell
  cd clients/app
  flutter analyze
  ```
  Run `flutter test` when tests exist for changed code.

---

## 3. Implementation Rules (Reference `.cursor/rules/`)

Always refer to and enforce the detailed rules in `.cursor/rules/`:
- **`inst.mdc`**: Instruction macros (`ai.inst`) — DB-only prompt steering, seed first in `inst.sql`, pair with tools, runtime cache invalidation via NATS.
- **`hint.mdc`**: Precompiled home hint chips (`ai.hint`, `ai.user_asset_touch`, `ai.hint_bundle`). Never JOIN on `SessionInit`.
- **`plan-execution.mdc`**: For multitask work or plans with independent tracks, dispatch subagents (`Task`) rather than doing all work inline.
- **`subagent-model.mdc`**: Default subagent model to `inherit` unless explicitly requested otherwise.
- **`ask_confirm.mdc`**: Confirm before destructive operations or schema-breaking migrations.
- **`rust-cache.mdc`**: Manage Rust build cache and targets appropriately.
- **`app-release-min.mdc`**: Flutter release build minimization and optimization rules.
- **`ui-page.mdc`** & **`ui-dropdown.mdc`**: Flutter UI component styling, layout, and dropdown behavior standards.
