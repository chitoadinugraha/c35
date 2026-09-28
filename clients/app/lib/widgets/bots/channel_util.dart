import 'dart:convert';

import 'package:alienai_c35/c/bot/bot_meta.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:flutter/material.dart';

typedef ChannelPlatformVisual = ({IconData icon, Color accent, String label});

ChannelPlatformVisual channelPlatformVisual(String platform) {
  final p = platform.trim().toLowerCase();
  return switch (p) {
    'whatsapp' => (icon: Icons.chat_rounded, accent: const Color(0xFF25D366), label: 'WhatsApp'),
    'telegram' => (icon: Icons.send_rounded, accent: const Color(0xFF38BDF8), label: 'Telegram'),
    'app' => (icon: Icons.apps_rounded, accent: const Color(0xFF18181B), label: 'App'),
    _ => (icon: Icons.link_rounded, accent: const Color(0xFFA1A1AA), label: platform.isNotEmpty ? platform : 'Channel'),
  };
}

String botPeerPlatformResolve({required String channelId, String botMetaJson = ''}) {
  if (channelId == kBotAppChannelId) return 'app';
  for (final ch in botChannelsParse(botMetaJson)) {
    if (ch.id == channelId) {
      final platform = ch.platform.trim();
      if (platform.isNotEmpty) return platform;
    }
  }
  return '';
}

(String label, IconData icon, Color accent) channelDisplay(BotChannelDoc channel) {
  final vis = channelPlatformVisual(channel.platform);
  final (icon, accent) = (vis.icon, vis.accent);
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
