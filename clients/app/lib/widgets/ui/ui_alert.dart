import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _title = Color(0xFFF4F4F5);
const _body = Color(0xFFA1A1AA);

Future<void> uiAlertInfo(BuildContext context, {required String title, String? message}) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(title, style: const TextStyle(color: _title)),
        content: message == null ? null : Text(message, style: const TextStyle(color: _body)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );

Future<void> uiAlertError(BuildContext context, Object error, {String? fallback}) => uiAlertInfo(
      context,
      title: 'Error',
      message: uiFriendlyError(error, fallback: fallback ?? 'Something went wrong.'),
    );
