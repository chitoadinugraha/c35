import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/pages/page_devices.dart';
import 'package:flutter/material.dart';

Future<void> openPageDevices(
  BuildContext context, {
  required ChatConn chatConn,
  ChatStore? shellStore,
}) async {
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => PageDevices(chatConn: chatConn, shellStore: shellStore)),
  );
}
