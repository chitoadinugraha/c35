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

bool chatTitleIsPlaceholder(String title) {
  final t = title.trim();
  return t.isEmpty || t == 'New chat' || t == 'Chat';
}

/// Client inbox title on prompt start: first user line for new chats only; keep existing title on follow-ups.
String chatTitleOnPromptStart({
  required int localChatId,
  required int serverChatId,
  required String existingTitle,
  required String previewLine,
}) {
  final first = previewLine.split('\n').first.trim();
  final fromPreview = first.isNotEmpty ? chatTitleFromText(first) : 'New chat';
  if (serverChatId != localChatId) return fromPreview;
  if (!chatTitleIsPlaceholder(existingTitle)) return existingTitle.trim();
  return fromPreview;
}
