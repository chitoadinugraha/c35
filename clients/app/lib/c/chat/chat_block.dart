import 'dart:convert';

class ChatBlock {
  ChatBlock({required this.kind, this.collapsed = true, required this.body});
  final String kind;
  final bool collapsed;
  final Map<String, dynamic> body;

  factory ChatBlock.fromJson(Map<String, dynamic> j) => ChatBlock(
        kind: j['kind']?.toString() ?? '',
        collapsed: j['collapsed'] != false,
        body: Map<String, dynamic>.from(j['body'] as Map? ?? const {}),
      );

  Map<String, dynamic> toJson() => {'kind': kind, 'collapsed': collapsed, 'body': body};

  static List<ChatBlock> decodeList(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s == '[]') return const [];
    final v = jsonDecode(s);
    if (v is! List) return const [];
    return v.map((e) => ChatBlock.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static String encodeList(List<ChatBlock> blocks) => jsonEncode(blocks.map((b) => b.toJson()).toList());
}
