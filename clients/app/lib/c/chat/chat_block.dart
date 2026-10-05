import 'dart:convert';

class ChatBlock {
  ChatBlock({required this.kind, this.collapsed = true, required this.body});
  final String kind;
  final bool collapsed;
  final Map<String, dynamic> body;

  factory ChatBlock.fromJson(Map<String, dynamic> j) {
    final kind = j['kind']?.toString() ?? '';
    final body = Map<String, dynamic>.from(j['body'] as Map? ?? const {});
    if (kind == 'image' && body.isEmpty && (j['hash'] != null || j['url'] != null)) {
      return ChatBlock(
        kind: kind,
        collapsed: j['collapsed'] == true,
        body: {
          if (j['hash'] != null) 'hash': j['hash'],
          if (j['url'] != null) 'url': j['url'],
          if (j['mime'] != null) 'mime': j['mime'],
          if (j['prompt'] != null) 'prompt': j['prompt'],
        },
      );
    }
    return ChatBlock(kind: kind, collapsed: j['collapsed'] != false, body: body);
  }

  Map<String, dynamic> toJson() => {'kind': kind, 'collapsed': collapsed, 'body': body};

  static List<ChatBlock> decodeList(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '[]') return const [];
    final v = jsonDecode(s);
    if (v is! List) return const [];
    return v.map((e) => ChatBlock.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static String encodeList(List<ChatBlock> blocks) => jsonEncode(blocks.map((b) => b.toJson()).toList());

  static ChatBlock? imageFirst(String blocksJson) {
    for (final b in decodeList(blocksJson)) {
      if (b.kind == 'image') return b;
    }
    return null;
  }

  static bool imageIsHd(ChatBlock b) {
    if (b.kind != 'image') return false;
    final q = b.body['quality']?.toString().trim().toLowerCase();
    if (q == 'hd') return true;
    final size = b.body['image_size']?.toString().trim().toUpperCase();
    return size == '2K';
  }

  static String mediaProvider(ChatBlock b) => b.body['media_provider']?.toString().trim().toLowerCase() ?? '';

  static String mediaModel(ChatBlock b) => b.body['media_model']?.toString().trim() ?? '';

  static String mediaTool(ChatBlock b) => b.body['tool']?.toString().trim() ?? '';

  static String mediaAspectRatio(ChatBlock b) => b.body['aspect_ratio']?.toString().trim() ?? '';

  static String mediaSourceHash(ChatBlock b) => b.body['source_hash']?.toString().trim() ?? '';

  static int mediaDurationSec(ChatBlock b) => int.tryParse('${b.body['duration_sec'] ?? ''}') ?? 0;

  static bool mediaInstrumental(ChatBlock b) => b.body['instrumental'] == true;

  static bool mediaHasProviderChip(ChatBlock b) => mediaProvider(b).isNotEmpty && const {'image', 'video', 'music', 'audio'}.contains(b.kind);
}
