import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
import 'package:flutter/material.dart';

/// Stored / first-line inbox title length (UI still ellipsizes in sidebar).
const kChatTitleMaxChars = 80;

String chatTitleFromText(String text, {int maxLen = kChatTitleMaxChars}) {
  final raw = text.trim();
  if (raw.isEmpty) return 'Chat';
  if (composerMentionTextHasTokens(raw)) {
    return _chatTitleFromBracketText(raw, maxLen: maxLen);
  }
  final cut = raw.length > maxLen ? raw.substring(0, maxLen) : raw;
  if (cut.isEmpty) return 'Chat';
  return cut[0].toUpperCase() + cut.substring(1);
}

String _chatTitleFromBracketText(String text, {required int maxLen}) {
  var out = StringBuffer();
  var count = 0;
  var i = 0;
  while (i < text.length && count < maxLen) {
    if (text.startsWith('[@', i)) {
      final end = text.indexOf(']', i);
      if (end < 0) break;
      final token = text.substring(i, end + 1);
      if (count + token.length > maxLen) {
        i = end + 1;
        continue;
      }
      out.write(token);
      count += token.length;
      i = end + 1;
      continue;
    }
    out.write(text[i]);
    count++;
    i++;
  }
  final trimmed = out.toString().trim();
  if (trimmed.isEmpty) return 'Chat';
  return _capitalizeFirstLetter(trimmed);
}

String _capitalizeFirstLetter(String s) {
  var i = 0;
  while (i < s.length) {
    if (s.startsWith('[@', i)) {
      final end = s.indexOf(']', i);
      if (end < 0) break;
      i = end + 1;
      continue;
    }
    final c = s[i];
    if (RegExp(r'[A-Za-z]').hasMatch(c)) {
      return s.substring(0, i) + c.toUpperCase() + s.substring(i + 1);
    }
    i++;
  }
  return s;
}

/// When the stored title dropped a sticky site/device mention, prepend a labeled bracket token.
String chatTitlePrependPrimarySticky(String title, List<String> stickyMentionIds, List<CatalogMention> mentions) {
  final t = title.trim();
  if (t.isEmpty || stickyMentionIds.isEmpty || mentions.isEmpty) return t;
  for (final raw in stickyMentionIds) {
    final id = raw.trim();
    if (id.isEmpty || id == 'image' || id == 'image_high') continue;
    final label = composerMentionLookup(mentions, id)?.displayLabel.trim() ?? '';
    if (label.isEmpty) continue;
    final bracket = composerMentionBracketForId(id, label: label);
    if (t.contains(bracket)) return t;
    if (t.toLowerCase().contains(label.toLowerCase())) return t;
    return '$bracket $t';
  }
  return t;
}

String chatTitleStoredNormalize(
  String title, {
  List<CatalogMention> mentions = const [],
  List<String> stickyMentionIds = const [],
}) {
  final t = title.trim();
  if (t.isEmpty || t == 'New chat') return '';
  var resolved = composerMentionBracketRepair(t);
  resolved = composerMentionBracketFixupNesting(resolved);
  return chatTitlePrependPrimarySticky(resolved, stickyMentionIds, mentions);
}

/// Plain string for search / accessibility (strips bracket tokens to labels).
String chatTitleDisplayPlain(
  String title, {
  List<CatalogMention> mentions = const [],
  List<String> stickyMentionIds = const [],
}) {
  final stored = chatTitleStoredNormalize(title, mentions: mentions, stickyMentionIds: stickyMentionIds);
  if (stored.isEmpty) return '';
  if (!composerMentionTextHasTokens(stored)) return chatTitleFromText(stored);
  return composerMentionTextForPrompt(
    stored,
    mentions,
    mentionIds: composerMentionIdsCollect(stored),
  );
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
  List<CatalogMention> mentions = const [],
}) {
  var first = previewLine.split('\n').first.trim();
  first = composerMentionBracketFixupNesting(first);
  final fromPreview = first.isNotEmpty ? chatTitleFromText(first) : 'New chat';
  if (serverChatId != localChatId) return fromPreview;
  if (!chatTitleIsPlaceholder(existingTitle)) return existingTitle.trim();
  return fromPreview;
}

/// Sidebar / header title with mention chips (same badges as message bubbles).
class ChatTitleText extends StatelessWidget {
  const ChatTitleText({
    super.key,
    required this.title,
    required this.mentions,
    this.stickyMentionIds = const [],
    this.style,
    this.maxLines = 1,
  });

  final String title;
  final List<CatalogMention> mentions;
  final List<String> stickyMentionIds;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final stored = chatTitleStoredNormalize(title, mentions: mentions, stickyMentionIds: stickyMentionIds);
    if (stored.isEmpty) return const SizedBox.shrink();
    return ComposerMentionStyledText(
      text: stored,
      mentions: mentions,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
