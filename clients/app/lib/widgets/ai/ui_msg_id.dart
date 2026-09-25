import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';

class UiMsgId extends StatelessWidget {
  const UiMsgId({super.key, required this.id, this.alignment = Alignment.centerLeft});

  final int id;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (id <= 0) return const SizedBox.shrink();
    final msgId = '$id';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: alignment,
        child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: msgId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message ID copied'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              msgId,
              style: UiMsgUsage.style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ),
    );
  }
}
