import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:flutter/material.dart';

enum HintAction { sendText, pickImage, pickFile }

HintAction hintActionParse(String raw) => switch (raw) {
      'pick_image' => HintAction.pickImage,
      'pick_file' => HintAction.pickFile,
      _ => HintAction.sendText,
    };

class SpaceHint {
  const SpaceHint({required this.syncId, required this.id, required this.scope, required this.sort, required this.label, required this.icon, required this.action, required this.sendText, required this.instId, this.updatedAt = 0});

  final int syncId;
  final String id;
  final String scope;
  final int sort;
  final String label;
  final String icon;
  final HintAction action;
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
        action: hintActionParse('${j['action'] ?? 'send_text'}'),
        sendText: '${j['send_text'] ?? ''}',
        instId: '${j['inst_id'] ?? ''}',
        updatedAt: j['updated_at'] as int? ?? 0,
      );
}

List<SpaceHint> hintsOfflineFallback() => const [
      SpaceHint(syncId: 0, id: 'hint.consumption_add', scope: 'role:personal_assistant', sort: 10, label: 'Track Food Consumption', icon: 'mdi:restaurant', action: HintAction.pickImage, sendText: 'Track food consumption', instId: 'inst.consumption_add'),
      SpaceHint(syncId: 0, id: 'hint.expense_add', scope: 'role:personal_assistant', sort: 20, label: 'Track Expense', icon: 'mdi:receipt', action: HintAction.sendText, sendText: 'Track expense', instId: ''),
    ];

Future<void> hintRun({
  required SpaceHint hint,
  required Future<void> Function(String text, List<MsgAttachment> attachments) onSend,
  Future<List<StagedMedia>?> Function()? askMediaFn,
}) async {
  switch (hint.action) {
    case HintAction.sendText:
      final text = hint.sendText.trim().isNotEmpty ? hint.sendText : hint.label;
      await onSend(text, const []);
    case HintAction.pickImage:
      final ask = askMediaFn ?? () => askMedia(types: const [MediaType.image], allowMultiple: false);
      final picked = await ask();
      if (picked == null || picked.isEmpty) return;
      final item = picked.first;
      var hash = item.hash ?? '';
      if (hash.isEmpty && item.bytes.isNotEmpty) {
        final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
        hash = res?.hash ?? '';
      }
      final text = hint.sendText.trim().isNotEmpty ? hint.sendText : hint.label;
      await onSend(text, [MsgAttachment(hash: hash, name: item.name, mime: item.mime, localBytes: item.bytes.isNotEmpty ? item.bytes : null)]);
    case HintAction.pickFile:
      final ask = askMediaFn ?? () => askMedia(types: const [MediaType.document, MediaType.any], allowMultiple: false);
      final picked = await ask();
      if (picked == null || picked.isEmpty) return;
      final item = picked.first;
      var hash = item.hash ?? '';
      if (hash.isEmpty && item.bytes.isNotEmpty) {
        final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
        hash = res?.hash ?? '';
      }
      final text = hint.sendText.trim().isNotEmpty ? hint.sendText : hint.label;
      await onSend(text, [MsgAttachment(hash: hash, name: item.name, mime: item.mime, localBytes: item.bytes.isNotEmpty ? item.bytes : null)]);
  }
}

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
