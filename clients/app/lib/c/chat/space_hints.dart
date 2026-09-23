import 'dart:convert';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart' as hint_pb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum HintActionKind { sendText, pickImage, pickFile, openUrl, navigate }

HintActionKind hintActionKindParse(String raw) => switch (raw) {
      'pick_image' => HintActionKind.pickImage,
      'pick_file' => HintActionKind.pickFile,
      'open_url' => HintActionKind.openUrl,
      'navigate' => HintActionKind.navigate,
      _ => HintActionKind.sendText,
    };

Map<String, dynamic> hintPayloadParse(String raw) {
  if (raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry('$k', v));
  } catch (_) {}
  return const {};
}

class SpaceHint {
  const SpaceHint({required this.syncId, required this.id, required this.scope, required this.sort, required this.label, required this.icon, required this.action, required this.sendText, required this.instId, this.updatedAt = 0});

  final int syncId;
  final String id;
  final String scope;
  final int sort;
  final String label;
  final String icon;
  final HintActionKind action;
  final String sendText;
  final String instId;
  final int updatedAt;

  factory SpaceHint.fromJson(Map<String, dynamic> j, {int syncId = 0}) => SpaceHint(
        syncId: syncId,
        id: '${j['id'] ?? ''}',
        scope: '${j['scope'] ?? ''}',
        sort: j['sort_order'] as int? ?? j['sort'] as int? ?? 0,
        label: '${j['label'] ?? ''}',
        icon: '${j['icon'] ?? ''}',
        action: hintActionKindParse('${j['action'] ?? 'send_text'}'),
        sendText: '${j['send_text'] ?? ''}',
        instId: '${j['inst_id'] ?? ''}',
        updatedAt: j['updated_at'] as int? ?? 0,
      );
}

List<SpaceHint> hintsOfflineFallback() => const [
      SpaceHint(syncId: 0, id: 'hint.consumption_add', scope: 'role:personal_assistant', sort: 10, label: 'Track Consumption', icon: 'mdi:restaurant', action: HintActionKind.pickImage, sendText: 'Track food consumption', instId: 'inst.consumption_add'),
      SpaceHint(syncId: 0, id: 'hint.expense_add', scope: 'role:personal_assistant', sort: 20, label: 'Track Expense', icon: 'mdi:receipt', action: HintActionKind.sendText, sendText: 'Track expense', instId: ''),
    ];

String hintPayloadText(Map<String, dynamic> payload, {required String fallback}) {
  final text = '${payload['text'] ?? payload['send_text'] ?? ''}'.trim();
  return text.isNotEmpty ? text : fallback;
}

String _kindWire(HintActionKind action) => switch (action) {
      HintActionKind.pickImage => 'pick_image',
      HintActionKind.pickFile => 'pick_file',
      HintActionKind.openUrl => 'open_url',
      HintActionKind.navigate => 'navigate',
      HintActionKind.sendText => 'send_text',
    };

hint_pb.HintItem hintItemFromSpaceHint(SpaceHint hint) => hint_pb.HintItem(
      id: hint.id,
      label: hint.label,
      icon: hint.icon,
      sort: hint.sort,
      action: hint_pb.HintAction(
        kind: _kindWire(hint.action),
        payloadJson: jsonEncode({
          if (hint.sendText.isNotEmpty) 'text': hint.sendText,
          if (hint.instId.isNotEmpty) 'inst_id': hint.instId,
        }),
      ),
    );

List<hint_pb.HintItem> hintsOfflineFallbackItems() => hintsOfflineFallback().map(hintItemFromSpaceHint).toList(growable: false);

int? hintTouchAssetIid(hint_pb.HintItem item) {
  if (item.hasAction()) {
    final payload = hintPayloadParse(item.action.payloadJson);
    final siteIid = int.tryParse('${payload['site_iid'] ?? ''}') ?? 0;
    if (siteIid > 0) return siteIid;
    final assetIid = int.tryParse('${payload['asset_iid'] ?? ''}') ?? 0;
    if (assetIid > 0) return assetIid;
  }
  final visit = RegExp(r'^hint\.site\.(\d+)\.').firstMatch(item.id);
  if (visit != null) {
    final iid = int.tryParse(visit.group(1) ?? '') ?? 0;
    if (iid > 0) return iid;
  }
  final site = RegExp(r'^hint\.site:(\d+)$').firstMatch(item.id);
  if (site != null) {
    final iid = int.tryParse(site.group(1) ?? '') ?? 0;
    if (iid > 0) return iid;
  }
  return null;
}

String hintTouchAssetKind(hint_pb.HintItem item) {
  if (!item.hasAction()) return 'site';
  final payload = hintPayloadParse(item.action.payloadJson);
  final kind = '${payload['asset_kind'] ?? ''}'.trim();
  return kind.isNotEmpty ? kind : 'site';
}

Future<void> hintActionRunFromProto({
  required hint_pb.HintItem item,
  required Future<void> Function(String text, List<MsgAttachment> attachments) onSend,
  Future<void> Function(String route, Map<String, dynamic> payload)? onNavigate,
  Future<void> Function(String url)? onOpenUrl,
  Future<List<StagedMedia>?> Function()? askMediaFn,
}) async {
  if (item.items.isNotEmpty || !item.hasAction()) return;
  final action = item.action;
  final kind = hintActionKindParse(action.kind);
  final payload = hintPayloadParse(action.payloadJson);
  switch (kind) {
    case HintActionKind.sendText:
      await onSend(hintPayloadText(payload, fallback: item.label), const []);
    case HintActionKind.pickImage:
      final ask = askMediaFn ?? () => askMedia(types: const [MediaType.image], allowMultiple: false);
      final picked = await ask();
      if (picked == null || picked.isEmpty) return;
      final media = picked.first;
      var hash = media.hash ?? '';
      if (hash.isEmpty && media.bytes.isNotEmpty) {
        final res = await casUpload(bytes: media.bytes, mime: media.mime, name: media.name);
        hash = res?.hash ?? '';
      }
      await onSend(hintPayloadText(payload, fallback: item.label), [MsgAttachment(hash: hash, name: media.name, mime: media.mime, localBytes: media.bytes.isNotEmpty ? media.bytes : null)]);
    case HintActionKind.pickFile:
      final ask = askMediaFn ?? () => askMedia(types: const [MediaType.document, MediaType.any], allowMultiple: false);
      final picked = await ask();
      if (picked == null || picked.isEmpty) return;
      final media = picked.first;
      var hash = media.hash ?? '';
      if (hash.isEmpty && media.bytes.isNotEmpty) {
        final res = await casUpload(bytes: media.bytes, mime: media.mime, name: media.name);
        hash = res?.hash ?? '';
      }
      await onSend(hintPayloadText(payload, fallback: item.label), [MsgAttachment(hash: hash, name: media.name, mime: media.mime, localBytes: media.bytes.isNotEmpty ? media.bytes : null)]);
    case HintActionKind.openUrl:
      final url = '${payload['url'] ?? ''}'.trim();
      if (url.isEmpty) return;
      if (onOpenUrl != null) {
        await onOpenUrl(url);
      } else {
        final uri = Uri.tryParse(url);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    case HintActionKind.navigate:
      final route = '${payload['route'] ?? ''}'.trim();
      if (route.isEmpty || onNavigate == null) return;
      await onNavigate(route, payload);
  }
}

Future<void> hintRun({
  required SpaceHint hint,
  required Future<void> Function(String text, List<MsgAttachment> attachments) onSend,
  Future<List<StagedMedia>?> Function()? askMediaFn,
}) => hintActionRunFromProto(item: hintItemFromSpaceHint(hint), onSend: onSend, askMediaFn: askMediaFn);

IconData? hintIconFallback(String icon) {
  final id = icon.contains(':') ? icon.split(':').last : icon;
  return switch (id) {
    'restaurant' => Icons.restaurant_outlined,
    'receipt' => Icons.receipt_long_outlined,
    'business-center' => Icons.business_center_outlined,
    'monitor-screenshot' => Icons.screenshot_monitor_outlined,
    'note-edit-outline' => Icons.edit_note_outlined,
    _ => null,
  };
}

IconData hintMenuIcon(hint_pb.HintItem item) {
  if (item.hasAction()) {
    return switch (hintActionKindParse(item.action.kind)) {
      HintActionKind.openUrl => Icons.open_in_new,
      HintActionKind.navigate => Icons.point_of_sale,
      _ => hintIconFallback(item.icon) ?? Icons.lightbulb_outline,
    };
  }
  return hintIconFallback(item.icon) ?? Icons.lightbulb_outline;
}
