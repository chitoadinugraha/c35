String tagNormalize(String raw) {
  final t = raw.trim().toLowerCase();
  final noHash = t.startsWith('#') ? t.substring(1) : t;
  return noHash.replaceAll(RegExp(r'[^a-z0-9_-]'), '');
}

String? tagFormatError(String raw) {
  final tag = tagNormalize(raw);
  if (tag.isEmpty) return null;
  if (tag.length > 32) return 'At most 32 characters';
  if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(tag)) return 'Only a-z, 0-9, _ and -';
  return null;
}

List<String> tagsNormalize(List<String> raw) {
  final out = <String>[];
  for (final item in raw) {
    final tag = tagNormalize(item);
    if (tag.isEmpty || out.contains(tag)) continue;
    out.add(tag);
  }
  return out;
}
