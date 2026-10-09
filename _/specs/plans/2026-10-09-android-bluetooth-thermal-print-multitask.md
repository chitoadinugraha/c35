# Android Bluetooth ESC/POS Printing — Multitask Plan

> **Goal:** Add optional in-app Bluetooth thermal printing on Android without changing Network or System/PDF flows.

**Architecture:** Reuse existing `EscPosReceiptFormatter` bytes. Add `ThermalPrinterType.bluetooth` + `print_bluetooth_thermal` for Android SPP transport. Settings UI lists paired devices; `ThermalPrinterManager.printRaw` routes by mode.

**Tech stack:** Flutter, `print_bluetooth_thermal`, `permission_handler` (BLUETOOTH_CONNECT / SCAN).

## Tasks

| Wave | Track | Deliverable |
|------|--------|-------------|
| 1 | A | `thermal_bluetooth_permission.dart`, `thermal_printer_bluetooth.dart` |
| 1 | B | `ThermalPrinterManager` bluetooth prefs + `usesRawEscPos` + routing |
| 2 | C | Printer settings dialog (Android Bluetooth mode) |
| 2 | D | `ui_site_tx_editor` raw print on bluetooth |
| 3 | E | Unit tests + `verify_flutter_app.ps1` |
| 3 | F | Emulator smoke (paired list / permissions; no physical printer) |

## Global constraints

- Default remains `pdfPreview`; existing pref values unchanged.
- No provider web grounding / no STT changes.
- UTF-8 sources; run `check_utf8_sources.ps1 -Changed -Fix` after edits.
