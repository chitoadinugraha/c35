import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';

String chatTitleFromText(String text, {int maxLen = 48}) {
  final raw = text.trim();
  if (raw.isEmpty) return 'Chat';
  final cut = raw.length > maxLen ? raw.substring(0, maxLen) : raw;
  if (cut.isEmpty) return 'Chat';
  return cut[0].toUpperCase() + cut.substring(1);
}

String chatTitleDisplay(String title, {List<CatalogMention> mentions = const []}) {
  final t = title.trim();
  if (t.isEmpty || t == 'New chat') return '';
  final hasMentionWire = composerMentionTextHasTokens(t);
  final resolved = hasMentionWire
      ? composerMentionTextForPrompt(
          composerMentionBracketFixupNesting(t),
          mentions,
          mentionIds: composerMentionIdsCollect(t),
        )
      : t;
  return chatTitleFromText(resolved, maxLen: resolved.length);
}

bool chatTitleIsPlaceholder(String title) {
  final t = title.trim();
  return t.isEmpty || t == 'New chat' || t == 'Chat';
}

/// Client inbox title on prompt start: first user line for new chats only; keep existing title on follow-ups.
/// [previewLine] should already use resolved mention labels (not wire brackets) so the title is a snapshot.
String chatTitleOnPromptStart({
  required int localChatId,
  required int serverChatId,
  required String existingTitle,
  required String previewLine,
  List<CatalogMention> mentions = const [],
}) {
  var first = previewLine.split('\n').first.trim();
  if (first.isNotEmpty && mentions.isNotEmpty && composerMentionTextHasTokens(first)) {
    first = composerMentionTextForPrompt(
      first,
      mentions,
      mentionIds: composerMentionIdsCollect(first),
    );
  }
  final fromPreview = first.isNotEmpty ? chatTitleFromText(first) : 'New chat';
  if (serverChatId != localChatId) return fromPreview;
  if (!chatTitleIsPlaceholder(existingTitle)) return existingTitle.trim();
  return fromPreview;
}
