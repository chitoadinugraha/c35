String chatTitleFromText(String text, {int maxLen = 48}) {
  final raw = text.trim();
  if (raw.isEmpty) return 'Chat';
  final cut = raw.length > maxLen ? raw.substring(0, maxLen) : raw;
  final lower = cut.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

String chatTitleDisplay(String title) {
  final t = title.trim();
  if (t.isEmpty || t == 'New chat') return '';
  return chatTitleFromText(t, maxLen: t.length);
}
