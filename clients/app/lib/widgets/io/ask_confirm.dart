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
  final defaultCancel = isId ? 'Batal' : 'Cancel';
  final defaultConfirm = isDestructive
      ? (isId ? 'Hapus' : 'Delete')
      : (isId ? 'Ya, Lanjutkan' : 'Confirm');

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (contentExtra != null) ...[
              const SizedBox(height: 12),
              contentExtra,
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? defaultCancel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel ?? defaultConfirm),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
