import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/chat.pb.dart';

const kBotAppChannelId = 'app';

bool botPeerIsApp(Chat chat) => chat.channelId == kBotAppChannelId;

bool botActiveFromMetaJson(String metaJson) {
  if (metaJson.trim().isEmpty) return true;
  try {
    final decoded = jsonDecode(metaJson);
    if (decoded is! Map) return true;
    final active = decoded['active'];
    if (active is bool) return active;
    return true;
  } catch (_) {
    return true;
  }
}
