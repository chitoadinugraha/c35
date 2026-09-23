---
description: Always use askConfirm for user confirmation dialogs
globs: clients/app/lib/**/*.dart
---

# Confirmation Dialog Policy

Whenever prompting the user for confirmation before performing any action (e.g. delete, cancel, reset, discard changes, or destructive operations):

1. **Always use `askConfirm()`** located in `package:alienai_c35/widgets/io/ask_confirm.dart`.
2. **Never roll custom `AlertDialog` or `showDialog`** for confirmations.
3. Pass `isDestructive: true` for deletion or irreversible operations so the dialog properly styles the action button in error/danger theme.
4. Support localization (Indonesian / English) or pass clear `confirmLabel` and `cancelLabel` when domain-specific text is required.

Example:
```dart
final confirmed = await askConfirm(
  context,
  title: 'Hapus Catatan Makan',
  message: 'Apakah Anda yakin ingin menghapus catatan konsumsi ini?',
  isDestructive: true,
);
if (!confirmed) return;
// proceed with deletion
```
