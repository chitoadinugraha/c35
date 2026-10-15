import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/remote/webrtc_module_loader.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/pages/live_call_module.dart' deferred as live_call;
import 'package:alienai_c35/widgets/ui/ui_web_module_loader.dart';
import 'package:flutter/material.dart';

Future<void> openPageLiveCall({
  required BuildContext context,
  required ChatConn conn,
  required LiveOffer offer,
  int? chatId,
  ChatStore? chatStore,
  List<String> mentionIds = const [],
  String mentionLabel = '',
  void Function(List<String> mentionIds)? onMentions,
}) async {
  await runWebDeferredModule<void>(
    context: context,
    loadModule: () async {
      await ensureWebRtcModule();
      await live_call.loadLibrary();
    },
    loadingLabel: webModuleLoadingCallLabel(),
    action: () async {
      if (!context.mounted) return null;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => live_call.PageLiveCall(
            conn: conn,
            offer: offer,
            chatId: chatId,
            chatStore: chatStore,
            mentionIds: mentionIds,
            mentionLabel: mentionLabel,
            onMentions: onMentions,
          ),
        ),
      );
      return null;
    },
  );
}
