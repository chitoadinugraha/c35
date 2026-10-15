import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/pages/mail/mail_module.dart' deferred as mail;
import 'package:alienai_c35/widgets/ui/ui_web_module_loader.dart';
import 'package:flutter/material.dart';

Future<void> openPageMail(BuildContext context, {required ChatConn chatConn}) async {
  await runWebDeferredModule<void>(
    context: context,
    loadModule: mail.loadLibrary,
    loadingLabel: webModuleLoadingMailLabel(),
    action: () async {
      if (!context.mounted) return null;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => mail.PageMail(chatConn: chatConn)),
      );
      return null;
    },
  );
}
