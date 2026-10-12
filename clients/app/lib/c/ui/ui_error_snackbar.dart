import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating snackbar for failed API / RPC requests with copy-to-clipboard.
void uiShowErrorSnackBar(BuildContext context, Object error, {String? copyText}) {
  var raw = copyText ?? error.toString();
  if (raw.startsWith('Exception: ')) raw = raw.substring('Exception: '.length);
  final message = uiFriendlyError(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () => Clipboard.setData(ClipboardData(text: raw.trim())),
      ),
    ),
  );
}
