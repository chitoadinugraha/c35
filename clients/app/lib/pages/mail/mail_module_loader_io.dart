import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/pages/mail/page_mail.dart';
import 'package:flutter/material.dart';

Future<void> openPageMail(BuildContext context, {required ChatConn chatConn}) async {
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => PageMail(chatConn: chatConn)),
  );
}
