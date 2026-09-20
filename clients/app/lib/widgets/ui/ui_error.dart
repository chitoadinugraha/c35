import 'package:flutter/material.dart';

class UIError extends StatelessWidget {
  const UIError({super.key, required this.message, this.compact = false});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: TextStyle(color: const Color(0xFFF87171), fontSize: compact ? 12 : 13),
      );
}
