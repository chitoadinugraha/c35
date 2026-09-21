import 'dart:convert';
import 'dart:typed_data';

import 'package:alienai_c35/c/media/media_types.dart';

class MsgAttachment {
  const MsgAttachment({required this.name, required this.mime, this.hash = '', this.url = '', this.localBytes});
  final String hash;
  final String name;
  final String mime;
  final String url;
  final Uint8List? localBytes;

  bool get isImage => mime.startsWith('image/');
  String get servePath => url.isNotEmpty ? url : (hash.isNotEmpty ? '/fs/$hash' : '');
  bool get hasRemote => hash.isNotEmpty || url.isNotEmpty;
  bool get hasLocalPreview => localBytes != null && localBytes!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (hash.isNotEmpty) 'hash': hash,
        if (name.isNotEmpty) 'name': name,
        if (mime.isNotEmpty) 'mime': mime,
        if (url.isNotEmpty) 'url': url,
      };

  factory MsgAttachment.fromJson(Map<String, dynamic> j, {Uint8List? localBytes}) => MsgAttachment(
        hash: '${j['hash'] ?? ''}',
        name: '${j['name'] ?? ''}',
        mime: '${j['mime'] ?? 'application/octet-stream'}',
        url: '${j['url'] ?? ''}',
        localBytes: localBytes,
      );

  factory MsgAttachment.fromStaged(StagedMedia m) => MsgAttachment(hash: m.hash ?? '', name: m.name, mime: m.mime, localBytes: m.bytes.isNotEmpty ? m.bytes : null);

  static String encode(List<MsgAttachment> items) => jsonEncode(items.map((a) => a.toJson()).toList());

  static List<MsgAttachment> decode(String raw, {Map<String, Uint8List>? localByHash}) {
    if (raw.trim().isEmpty) return const [];
    try {
      final v = jsonDecode(raw);
      if (v is! List) return const [];
      return [
        for (final item in v)
          if (item is Map<String, dynamic> || item is Map)
            MsgAttachment.fromJson(Map<String, dynamic>.from(item as Map), localBytes: localByHash?['${item['hash'] ?? ''}']),
      ];
    } catch (_) {
      return const [];
    }
  }
}
