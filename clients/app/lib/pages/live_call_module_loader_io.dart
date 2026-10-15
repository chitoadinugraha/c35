import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/pages/page_live_call.dart';
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
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PageLiveCall(
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
}