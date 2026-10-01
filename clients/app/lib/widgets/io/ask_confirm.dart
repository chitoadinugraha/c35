import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';

/// Shows a generic confirmation dialog across the app.
///
/// Returns `true` if the user confirms the action, or `false` if cancelled or dismissed.
Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
  Widget? contentExtra,
}) async {
  final isId = Localizations.maybeLocaleOf(context)?.languageCode == 'id';
  final defaultConfirm = isDestructive
      ? (isId ? 'Hapus' : 'Delete')
      : (isId ? 'Ya, Lanjutkan' : 'Confirm');

  final result = await uiDialogShow<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      return UiDialog(
        maxWidth: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiDialogHeader(title: title, onClose: () => Navigator.of(ctx).pop(false)),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            if (contentExtra != null) ...[
              const SizedBox(height: 12),
              contentExtra,
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: isDestructive
                    ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)
                    : null,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(confirmLabel ?? defaultConfirm),
              ),
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}
