import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:flutter/material.dart';

const msgBadAiReportReasons = [
  'Incorrect information',
  'Did not follow instructions',
  'Harmful or unsafe',
  'Incomplete or unhelpful',
  'Other',
];

Future<String?> showMsgBadAiReportReasonMenu({required BuildContext context, required Offset global}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(child: GestureDetector(onTap: () => Navigator.of(ctx).pop(), behavior: HitTestBehavior.opaque)),
        ChatMessageContextMenu(
          anchors: TextSelectionToolbarAnchors(primaryAnchor: global),
          items: [
            for (final reason in msgBadAiReportReasons)
              ChatMessageMenuAction(
                label: reason,
                icon: Icons.flag_outlined,
                onPressed: () => Navigator.of(ctx).pop(reason),
              ),
          ],
        ),
      ],
    ),
  );
}
