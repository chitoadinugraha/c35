import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';

class UiMsgId extends StatelessWidget {
  const UiMsgId({super.key, required this.id, this.alignment = Alignment.centerLeft});

  final int id;
  final Alignment alignment;

  void _copy(BuildContext context, String msgId) {
    Clipboard.setData(ClipboardData(text: msgCopyClipboardId('Message ID', msgId)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message ID copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (id <= 0) return const SizedBox.shrink();
    final msgId = '$id';
    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _copy(context, msgId),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                msgId,
                style: UiMsgUsage.style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          InkWell(
            onTap: () => _copy(context, msgId),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 14, color: Color(0xFF71717A)),
            ),
          ),
        ],
      ),
    );
  }
}
