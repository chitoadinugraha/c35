import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/widgets/ai/ui_attach_chips.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:flutter/material.dart';

class UiUserBubble extends StatelessWidget {
  const UiUserBubble({super.key, required this.content, required this.copyPrefix, this.attachments = const [], this.leadingNewline = false});
  final String content;
  final String copyPrefix;
  final List<MsgAttachment> attachments;
  final bool leadingNewline;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        key: const Key('user-bubble'),
        constraints: const BoxConstraints(maxWidth: 520),
        child: IntrinsicWidth(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF27272A),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiMsgCopyPrefix(text: copyPrefix, leadingNewline: leadingNewline),
                  if (attachments.isNotEmpty) ...[UiAttachChips(attachments: attachments), if (content.trim().isNotEmpty) const SizedBox(height: 8)],
                  if (content.trim().isNotEmpty) Text(content, style: const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
}
