import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:flutter/material.dart';

(String label, IconData icon, Color accent) channelDisplay(BotChannelDoc channel) {
  final (icon, accent) = switch (channel.platform) {
    'whatsapp' => (Icons.chat_rounded, const Color(0xFF25D366)),
    'telegram' => (Icons.send_rounded, const Color(0xFF38BDF8)),
    _ => (Icons.link_rounded, const Color(0xFFA1A1AA)),
  };
  if (channel.platform == 'telegram') {
    final username = channel.botUsername.trim();
    if (username.isNotEmpty) return (username.startsWith('@') ? username : '@$username', icon, accent);
  }
  if (channel.platform == 'whatsapp' && channel.phone.trim().isNotEmpty) {
    return (channel.phone.trim(), icon, accent);
  }
  final platform = channel.platform.isNotEmpty ? channel.platform : 'Channel';
  return (platform, icon, accent);
}

String channelExternalKey(BotChannelDoc channel) {
  if (channel.platform == 'telegram') {
    final username = channel.botUsername.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (username.isNotEmpty) return 'telegram:$username';
  }
  if (channel.platform == 'whatsapp') {
    final digits = channel.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) return 'whatsapp:$digits';
  }
  return '${channel.platform}:${channel.id}';
}

bool channelIsActive(BotChannelDoc channel) => channel.status == 'connected' || channel.status == 'pairing';

List<BotChannelDoc> botChannelsParse(String metaJson) {
  if (metaJson.trim().isEmpty) return const [];
  try {
    final root = jsonDecode(metaJson);
    if (root is! Map) return const [];
    final raw = root['channels'];
    if (raw is! List) return const [];
    return raw.map((e) {
      if (e is! Map) return null;
      return BotChannelDoc(
        id: '${e['id'] ?? ''}',
        platform: '${e['platform'] ?? ''}',
        provider: '${e['provider'] ?? ''}',
        status: '${e['status'] ?? ''}',
        botUsername: '${e['bot_username'] ?? e['botUsername'] ?? ''}',
        phone: '${e['phone'] ?? ''}',
        errorMessage: '${e['error_message'] ?? e['errorMessage'] ?? ''}',
      );
    }).whereType<BotChannelDoc>().toList();
  } catch (_) {
    return const [];
  }
}

List<(IconData, Color)> botChannelIcons(String metaJson) {
  final counts = <String, int>{};
  for (final ch in botChannelsParse(metaJson)) {
    final platform = ch.platform.trim().isEmpty ? 'unknown' : ch.platform.trim();
    counts[platform] = (counts[platform] ?? 0) + 1;
  }
  final out = <(IconData, Color)>[];
  for (final e in counts.entries) {
    final (_, icon, accent) = channelDisplay(BotChannelDoc(platform: e.key));
    for (var i = 0; i < e.value; i++) {
      out.add((icon, accent));
    }
  }
  return out;
}
