import 'package:flutter/material.dart';

String msgCopyPad2(int n) => n.toString().padLeft(2, '0');

String msgCopyPrefix({required String role, required String userName, required int createdAtMs, DateTime? now}) {
  final ms = createdAtMs > 0 ? createdAtMs : (now ?? DateTime.now()).millisecondsSinceEpoch;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  final stamp = '${msgCopyPad2(dt.day)} ${msgCopyPad2(dt.month)} ${dt.year} ${msgCopyPad2(dt.hour)}:${msgCopyPad2(dt.minute)}';
  final who = role == 'user' ? userName.trim() : 'Alien AI';
  return '[${who.isEmpty ? 'Account' : who} $stamp]:';
}

String msgCopyBody({required String prefix, required bool leadingNewline}) => '${leadingNewline ? '\n' : ''}$prefix\n';

class UiMsgCopyPrefix extends StatelessWidget {
  const UiMsgCopyPrefix({super.key, required this.text, this.leadingNewline = false});

  final String text;
  final bool leadingNewline;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 0,
          child: Text(msgCopyBody(prefix: text, leadingNewline: leadingNewline), style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 0)),
        ),
      );
}
