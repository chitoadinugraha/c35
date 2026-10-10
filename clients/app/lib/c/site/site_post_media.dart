import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';

const sitePostMediaMaxCount = 10;

/// Ordered image storage paths from [SitePost.media_json].
List<String> sitePostMediaPaths(SitePost post) => sitePostMediaPathsParse(post.mediaJson);

List<String> sitePostMediaPathsParse(String mediaJson) {
  final raw = mediaJson.trim();
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final out = <String>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final src = item['src']?.toString().trim() ?? '';
      if (src.isNotEmpty) out.add(src);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

String sitePostMediaEncode(List<String> paths) {
  final items = <Map<String, dynamic>>[];
  var order = 0;
  for (final path in paths) {
    final src = path.trim();
    if (src.isEmpty) continue;
    items.add({'src': src, 'type': 'image', 'sort_order': order});
    order += 10;
  }
  return jsonEncode(items);
}

String sitePostThumbFromPaths(List<String> paths) {
  for (final path in paths) {
    final src = path.trim();
    if (src.isNotEmpty) return src;
  }
  return '';
}

SitePost sitePostWithMedia(SitePost post, List<String> paths) {
  final cleaned = paths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  if (cleaned.length > sitePostMediaMaxCount) {
    throw ArgumentError('media max $sitePostMediaMaxCount items');
  }
  final out = post.clone();
  out.mediaJson = sitePostMediaEncode(cleaned);
  out.thumb = sitePostThumbFromPaths(cleaned);
  return out;
}
