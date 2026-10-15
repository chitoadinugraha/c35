import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/remote/webrtc_module_loader.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/pages/devices_module.dart' deferred as devices;
import 'package:alienai_c35/widgets/ui/ui_web_module_loader.dart';
import 'package:flutter/material.dart';

Future<void> openPageDevices(
  BuildContext context, {
  required ChatConn chatConn,
  ChatStore? shellStore,
}) async {
  await runWebDeferredModule<void>(
    context: context,
    loadModule: () async {
      await ensureWebRtcModule();
      await devices.loadLibrary();
    },
    loadingLabel: webModuleLoadingDevicesLabel(),
    action: () async {
      if (!context.mounted) return null;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => devices.PageDevices(chatConn: chatConn, shellStore: shellStore)),
      );
      return null;
    },
  );
}
