import 'dart:convert';

/// Parses `route_json` from notifications into navigation hints.
class NotifOpen {
  static String? pathFromRoute(String routeJson) {
    final raw = routeJson.trim();
    if (raw.isEmpty || raw == '{}') return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final path = decoded['path'];
      if (path is String && path.trim().isNotEmpty) return path.trim();
    } catch (_) {}
    return null;
  }

  static int chatIdFromRoute(String routeJson) {
    final raw = routeJson.trim();
    if (raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 0;
      final chat = decoded['chat_id'];
      if (chat is num) return chat.toInt();
      return int.tryParse('$chat') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String? categoryFromRoute(String routeJson) {
    final raw = routeJson.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final cat = decoded['category'];
      if (cat is String && cat.trim().isNotEmpty) return cat.trim();
    } catch (_) {}
    return null;
  }
}
