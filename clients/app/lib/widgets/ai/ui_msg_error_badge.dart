import 'package:flutter/material.dart';

class UiMsgErrorBadge extends StatelessWidget {
  const UiMsgErrorBadge({super.key, required this.error});

  final String error;

  Future<void> _showDialog(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          title: const Text('Error', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
          content: SingleChildScrollView(
            child: SelectableText(error, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.45, fontFamily: 'Consolas')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'View error',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: () => _showDialog(context),
        icon: const Icon(Icons.error_rounded, size: 18, color: Color(0xFFF87171)),
      );
}
