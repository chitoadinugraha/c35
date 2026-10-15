import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remote-ready attachment row (hash / URL only — no bytes on disk).
class ComposerDraftAttachment {
  const ComposerDraftAttachment({
    required this.name,
    required this.mime,
    required this.type,
    required this.size,
    this.hash = '',
    this.url = '',
  });

  final String name;
  final String mime;
  final String type;
  final int size;
  final String hash;
  final String url;

  Map<String, dynamic> toJson() => {
        'name': name,
        'mime': mime,
        'type': type,
        'size': size,
        if (hash.isNotEmpty) 'hash': hash,
        if (url.isNotEmpty) 'url': url,
      };

  factory ComposerDraftAttachment.fromJson(Map<String, dynamic> j) => ComposerDraftAttachment(
        name: '${j['name'] ?? ''}',
        mime: '${j['mime'] ?? 'application/octet-stream'}',
        type: '${j['type'] ?? 'any'}',
        size: j['size'] as int? ?? 0,
        hash: '${j['hash'] ?? ''}',
        url: '${j['url'] ?? ''}',
      );

  static ComposerDraftAttachment? fromStaged(StagedMedia m) {
    final hash = m.hash?.trim() ?? '';
    final url = m.previewUrl?.trim() ?? '';
    if (hash.isEmpty && url.isEmpty) return null;
    return ComposerDraftAttachment(
      name: m.name,
      mime: m.mime,
      type: m.type.name,
      size: m.size,
      hash: hash,
      url: url.isNotEmpty ? url : (hash.isNotEmpty ? '/fs/$hash' : ''),
    );
  }

  StagedMedia toStaged() {
    final hash = this.hash.trim();
    final url = this.url.trim();
    return StagedMedia(
      name: name,
      bytes: Uint8List(0),
      mime: mime,
      type: _mediaTypeFromWire(type),
      size: size,
      hash: hash.isEmpty ? null : hash,
      previewUrl: url.isEmpty ? null : url,
      uploadProgress: 1.0,
    );
  }
}

MediaType _mediaTypeFromWire(String raw) {
  for (final t in MediaType.values) {
    if (t.name == raw) return t;
  }
  return MediaType.any;
}

/// Per-chat composer draft (`null` chat id = Home "new chat" hero).
class ComposerDraft {
  const ComposerDraft({
    required this.text,
    required this.mentionIds,
    required this.attachments,
  });

  final String text;
  final List<String> mentionIds;
  final List<ComposerDraftAttachment> attachments;

  bool get isEmpty => text.trim().isEmpty && mentionIds.isEmpty && attachments.isEmpty;

  Map<String, dynamic> toJson() => {
        'text': text,
        'mentionIds': mentionIds,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory ComposerDraft.fromJson(Map<String, dynamic> j) => ComposerDraft(
        text: '${j['text'] ?? ''}',
        mentionIds: [for (final e in (j['mentionIds'] as List?) ?? const []) '$e'],
        attachments: [
          for (final e in (j['attachments'] as List?) ?? const [])
            if (e is Map) ComposerDraftAttachment.fromJson(Map<String, dynamic>.from(e)),
        ],
      );
}

class ComposerDraftStore {
  ComposerDraftStore._();
  static final ComposerDraftStore instance = ComposerDraftStore._();

  static const _newChatSuffix = '__new__';

  final _mem = <String, ComposerDraft>{};
  var _uid = 0;
  Timer? _persistDebounce;

  static String storageSuffixForChatId(int? chatId) => chatId == null ? _newChatSuffix : '$chatId';

  static List<ComposerDraftAttachment> attachmentsFromStaged(Iterable<StagedMedia> items) {
    final out = <ComposerDraftAttachment>[];
    for (final m in items) {
      final row = ComposerDraftAttachment.fromStaged(m);
      if (row != null) out.add(row);
    }
    return out;
  }

  Future<void> restoreForUid(int uid) async {
    _uid = uid;
    _mem.clear();
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    final prefix = 'c35.composer.draft.$uid.';
    for (final key in p.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final suffix = key.substring(prefix.length);
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _mem[suffix] = ComposerDraft.fromJson(decoded);
        } else if (decoded is Map) {
          _mem[suffix] = ComposerDraft.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }
  }

  ComposerDraft? get(int? chatId) => _mem[storageSuffixForChatId(chatId)];

  void put(
    int? chatId, {
    required String text,
    required Iterable<String> mentionIds,
    Iterable<StagedMedia> stagedAttachments = const [],
  }) {
    final attachments = attachmentsFromStaged(stagedAttachments);
    final ids = mentionIds.toList(growable: false);
    if (text.trim().isEmpty && ids.isEmpty && attachments.isEmpty) {
      remove(chatId);
      return;
    }
    _mem[storageSuffixForChatId(chatId)] = ComposerDraft(text: text, mentionIds: ids, attachments: attachments);
    _schedulePersist();
  }

  void remove(int? chatId) {
    final removed = _mem.remove(storageSuffixForChatId(chatId));
    if (removed != null) _schedulePersist();
  }

  void migrateKey(int? from, int? to) {
    if (from == to) return;
    final fromKey = storageSuffixForChatId(from);
    final toKey = storageSuffixForChatId(to);
    final draft = _mem.remove(fromKey);
    if (draft != null) {
      _mem[toKey] = draft;
      _schedulePersist();
    }
  }

  Future<void> clearForUid(int uid) async {
    _mem.clear();
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    final prefix = 'c35.composer.draft.$uid.';
    for (final key in p.getKeys()) {
      if (key.startsWith(prefix)) await p.remove(key);
    }
  }

  void _schedulePersist() {
    if (_uid <= 0) return;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 450), () => unawaited(_persistNow()));
  }

  Future<void> _persistNow() async {
    final uid = _uid;
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    final prefix = 'c35.composer.draft.$uid.';
    final keep = _mem.keys.toSet();
    for (final key in p.getKeys()) {
      if (key.startsWith(prefix) && !keep.contains(key.substring(prefix.length))) {
        await p.remove(key);
      }
    }
    for (final e in _mem.entries) {
      await p.setString('$prefix${e.key}', jsonEncode(e.value.toJson()));
    }
  }
}
