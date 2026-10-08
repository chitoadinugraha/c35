import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/site/site_product_parse_paste.dart';
import 'package:fixnum/fixnum.dart';

const siteProductParsePhotoPrompt = '''
Extract every distinct product or menu item visible in the attached image.
Return ONLY valid JSON (no markdown fences, no commentary) in this shape:
{"products":[{"name":"Item name","description":"optional subtitle","price":0}]}

Field rules:
- name: as printed on the menu
- description: variant or short detail if shown, otherwise ""
- price: integer IDR (rupiah) without decimals; use 0 if missing or unclear
''';

List<SiteProductPasteRow> siteProductParsePhotoRowsFromJson(dynamic decoded) {
  final List<dynamic>? raw = decoded is Map
      ? (decoded['products'] is List
          ? decoded['products'] as List
          : decoded['items'] is List
              ? decoded['items'] as List
              : null)
      : decoded is List
          ? decoded
          : null;
  if (raw == null) return [];
  return [
    for (final item in raw)
      if (item is Map)
        () {
          final name = '${item['name'] ?? ''}'.trim();
          if (name.isEmpty) return null;
          final desc = '${item['description'] ?? item['desc'] ?? ''}'.trim();
          final priceRaw = item['price'];
          final price = priceRaw is num && priceRaw > 0 ? priceRaw.round() : 0;
          return SiteProductPasteRow(name: name, description: desc, price: price);
        }(),
  ].whereType<SiteProductPasteRow>().toList();
}

dynamic siteProductParsePhotoDecodeJson(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true).firstMatch(trimmed);
  if (fence != null) {
    try {
      return jsonDecode(fence.group(1)!.trim());
    } catch (_) {}
  }
  try {
    return jsonDecode(trimmed);
  } catch (_) {}
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    try {
      return jsonDecode(trimmed.substring(start, end + 1));
    } catch (_) {}
  }
  return null;
}

List<SiteProductPasteRow> siteProductParsePhotoFromLlmText(String text) =>
    siteProductParsePhotoRowsFromJson(siteProductParsePhotoDecodeJson(text));

Future<String> siteProductParsePhotoPromptCollect(ChatConn conn, {required String text, required String attachmentsJson}) async {
  final buf = StringBuffer();
  await for (final ev in conn.promptSend(
    text: text,
    attachmentsJson: attachmentsJson,
    chatId: Int64.ZERO,
    toolMode: 'ask',
    locale: 'en',
  )) {
    if (ev.kind == 'fail') throw Exception(ev.message.isNotEmpty ? ev.message : 'Vision request failed');
    if (ev.kind == 'delta' && !ev.thought) buf.write(ev.text);
    if (ev.kind == 'end') break;
  }
  return buf.toString();
}

Future<List<SiteProductPasteRow>> siteProductParsePhoto({
  required ChatConn conn,
  required String hash,
  required String mime,
  String name = 'menu.jpg',
}) async {
  if (hash.isEmpty) return [];
  final attachmentsJson = MsgAttachment.encode([
    MsgAttachment(hash: hash, name: name, mime: mime, url: '/fs/$hash'),
  ]);
  final text = await siteProductParsePhotoPromptCollect(
    conn,
    text: siteProductParsePhotoPrompt,
    attachmentsJson: attachmentsJson,
  );
  return siteProductParsePhotoFromLlmText(text);
}
