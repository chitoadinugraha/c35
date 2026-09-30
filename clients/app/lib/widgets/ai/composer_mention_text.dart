import 'dart:convert';
import 'dart:ui' as ui;

import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

const composerMentionStart = '\uFFFC';
const composerMentionEnd = '\uFFFD';
const _chipGrey = Color(0xFF3F3F46);
const _chipBorder = Color(0xFF52525B);
const _iconGrey = Color(0xFF9CA3B8);
const zinc100 = Color(0xFFF4F4F5);

final RegExp _composerMentionTokenRe = RegExp(
  r'\uFFFC([^\uFFFD]+)\uFFFD',
);

String composerMentionToken(String catalogId) =>
    composerMentionStart + catalogId + composerMentionEnd;

List<String> composerMentionIdsParse(String text) =>
    _composerMentionTokenRe.allMatches(text).map((m) => m.group(1)!).toList(growable: false);

final RegExp _composerMentionPlainIidRe = RegExp(r'\biid:\d+\b', caseSensitive: false);

/// Bracket mention in stored / wire message text. `[@iid:<snowflake>]`, `[@catalog:<id>]`.
/// Future kinds (e.g. `[@file:<hash>]`) extend the same pattern — see `_/docs/chat.md`.
final RegExp composerMentionBracketRe = RegExp(r'\[@(iid|catalog|drive):([^\]]+)\]', caseSensitive: false);

String composerMentionBracketForId(String canonicalId) {
  var t = canonicalId.trim();
  final bracketed = composerMentionBracketRe.firstMatch(t);
  if (bracketed != null) {
    final id = composerMentionIdFromBracket(bracketed.group(1)!, bracketed.group(2)!);
    if (id != null) t = id;
  }
  if (t.startsWith('iid:')) return '[@iid:${t.substring(4)}]';
  if (t.startsWith('catalog:')) return '[@catalog:${t.substring(8)}]';
  if (t.startsWith('drive:')) return '[@drive:${t.substring(6)}]';
  if (RegExp(r'^\d+$').hasMatch(t)) return '[@iid:$t]';
  return '[@catalog:$t]';
}

String? composerMentionIdFromBracket(String kind, String body) {
  final k = kind.trim().toLowerCase();
  final b = body.trim();
  if (b.isEmpty) return null;
  if (k == 'iid') return 'iid:$b';
  if (k == 'catalog') return 'catalog:$b';
  if (k == 'drive') return 'drive:$b';
  return null;
}

String composerMentionBracketTokenize(String text) => text.replaceAllMapped(composerMentionBracketRe, (m) {
      final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
      return id == null ? m.group(0)! : composerMentionToken(id);
    });

List<String> composerMentionIdsCollect(String text) {
  final out = <String>[];
  final seen = <String>{};
  for (final id in composerMentionIdsParse(text)) {
    if (seen.add(id)) out.add(id);
  }
  for (final m in composerMentionBracketRe.allMatches(text)) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id != null && seen.add(id)) out.add(id);
  }
  for (final m in _composerMentionPlainIidRe.allMatches(text)) {
    final id = m.group(0)!;
    if (seen.add(id)) out.add(id);
  }
  return out;
}

bool composerMentionHasChipTokens(String text) => _composerMentionTokenRe.hasMatch(text);

bool composerMentionTextHasTokens(String text) =>
    composerMentionHasChipTokens(text) ||
    text.contains(composerMentionStart) ||
    composerMentionBracketRe.hasMatch(text);

String composerMentionPlainText(String text) =>
    text.replaceAll(_composerMentionTokenRe, '').replaceAll(RegExp(r'[ \t]+\n'), '\n').trim();

String composerMentionInlineIidTokenize(String text) => text.replaceAllMapped(_composerMentionPlainIidRe, (m) => composerMentionToken(m.group(0)!));

/// Remove literal `[@kind:…]` when that id is already a chip token (avoids badge + bracket text).
String composerMentionStripOrphanBrackets(String text) {
  final idsInTokens = composerMentionIdsParse(text).toSet();
  return text.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id == null) return '';
    if (idsInTokens.contains(id)) return '';
    return composerMentionToken(id);
  });
}

/// Drop duplicate device label right after its chip (wire bracket + composer label).
String composerMentionStripDuplicateLabelsAfterTokens(String text, List<CatalogMention> mentions) {
  var out = text;
  for (final id in composerMentionIdsParse(out)) {
    final label = composerMentionLookup(mentions, id)?.displayLabel.trim() ?? '';
    if (label.isEmpty) continue;
    final token = composerMentionToken(id);
    for (final gap in [' ', '  ']) {
      final dup = '$token$gap$label';
      while (out.contains(dup)) {
        out = out.replaceAll(dup, token);
      }
      final dupAt = '$dup ';
      while (out.contains(dupAt)) {
        out = out.replaceAll(dupAt, '$token ');
      }
    }
  }
  return out;
}

/// Re-wrap device mention labels as composer tokens after retry / server plain text.
String composerMentionDisplayRestore(String plain, List<CatalogMention> mentions, {List<String>? mentionIds}) {
  var out = composerMentionBracketTokenize(plain);
  if (!_composerMentionTokenRe.hasMatch(out)) {
    out = composerMentionInlineIidTokenize(out);
  }
  var rest = out.trimLeft();
  final iidLead = RegExp(r'^(iid:\d+)(?=\s|$)', caseSensitive: false);
  final iidMatch = iidLead.firstMatch(rest);
  if (iidMatch != null) {
    return composerMentionToken(iidMatch.group(1)!) + rest.substring(iidMatch.end);
  }
  final tryIds = mentionIds ?? composerMentionIdsCollect(plain);
  for (final id in tryIds) {
    final m = composerMentionLookup(mentions, id);
    if (m == null) continue;
    final label = m.displayLabel.trim();
    if (label.isEmpty) continue;
    if (!rest.toLowerCase().startsWith(label.toLowerCase())) continue;
    return composerMentionToken(id) + rest.substring(label.length);
  }
  for (final m in mentions) {
    if (!m.isDevice) continue;
    final label = m.displayLabel.trim();
    if (label.isEmpty) continue;
    if (!rest.toLowerCase().startsWith(label.toLowerCase())) continue;
    return composerMentionToken(m.id) + rest.substring(label.length);
  }
  out = composerMentionStripOrphanBrackets(out);
  out = composerMentionStripDuplicateLabelsAfterTokens(out, mentions);
  return out;
}

/// Plain text safe for [Text] when mention chips cannot render (empty catalog, reload).
String composerMentionUserContentDisplay(String content, List<CatalogMention> mentions) {
  if (!composerMentionTextHasTokens(content)) return content;
  if (mentions.isNotEmpty) return content;
  return composerMentionTextForPrompt(content, mentions, mentionIds: composerMentionIdsCollect(content));
}

String composerMentionTextForPrompt(String text, List<CatalogMention> mentions, {List<String>? mentionIds}) {
  var out = composerMentionBracketTokenize(text);
  out = out.replaceAllMapped(_composerMentionTokenRe, (m) {
    final id = m.group(1)!.trim();
    return composerMentionLookup(mentions, id)?.displayLabel ?? id;
  });
  out = out.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id == null) return m.group(0)!;
    return composerMentionLookup(mentions, id)?.displayLabel ?? id;
  });
  final ids = mentionIds ?? composerMentionIdsCollect(text);
  if (out.contains(composerMentionStart) && ids.isNotEmpty) {
    final queue = List<String>.from(ids);
    final sb = StringBuffer();
    for (final rune in out.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == composerMentionStart) {
        if (queue.isEmpty) continue;
        final id = queue.removeAt(0);
        sb.write(composerMentionLookup(mentions, id)?.displayLabel ?? id);
      } else if (ch != composerMentionEnd) {
        sb.write(ch);
      }
    }
    out = sb.toString();
  }
  out = out.replaceAll(composerMentionStart, '').replaceAll(composerMentionEnd, '');
  return out.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r' {2,}'), ' ').trim();
}

/// Plain text + bracket mentions for wire / server `chat_msg.content`.
String composerMentionTextForWire(String text, List<CatalogMention> mentions, {List<String>? mentionIds}) {
  var out = text.replaceAllMapped(_composerMentionTokenRe, (m) => composerMentionBracketForId(m.group(1)!));
  out = out.replaceAllMapped(_composerMentionPlainIidRe, (m) => composerMentionBracketForId(m.group(0)!));
  out = out.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    return id == null ? m.group(0)! : composerMentionBracketForId(id);
  });
  var rest = out.trimLeft();
  final ids = mentionIds ?? composerMentionIdsCollect(out);
  for (final id in ids) {
    final m = composerMentionLookup(mentions, id);
    if (m == null) continue;
    final label = m.displayLabel.trim();
    if (label.isEmpty || !rest.toLowerCase().startsWith(label.toLowerCase())) continue;
    out = composerMentionBracketForId(id) + rest.substring(label.length);
    break;
  }
  return out.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r' {2,}'), ' ').trim();
}

bool composerMentionTextNonempty(String text) =>
    composerMentionPlainText(text).isNotEmpty ||
    composerMentionIdsParse(text).isNotEmpty ||
    composerMentionIdsCollect(text).isNotEmpty;

bool _composerMentionStickyId(String id) {
  final t = id.trim();
  if (t.isEmpty || t == 'image') return false;
  return t.startsWith('iid:') || t.startsWith('catalog:') || t.startsWith('drive:');
}

/// Draft prefix from per-chat sticky mention ids (device / site / bot chips).
String composerMentionDraftFromStickyIds(Iterable<String> mentionIds, List<CatalogMention> mentions) {
  final parts = <String>[];
  final seen = <String>{};
  for (final raw in mentionIds) {
    final id = raw.trim();
    if (!_composerMentionStickyId(id) || !seen.add(id)) continue;
    if (composerMentionLookup(mentions, id) != null || id.startsWith('iid:') || id.startsWith('catalog:') || id.startsWith('drive:')) {
      parts.add(composerMentionToken(id));
    }
  }
  return parts.join(' ');
}

/// Keeps sticky chips at the start of the composer after send; preserves typed follow-up text.
String composerMentionDraftMergeSticky(String userText, Iterable<String> stickyIds, List<CatalogMention> mentions) {
  final sticky = composerMentionDraftFromStickyIds(stickyIds, mentions);
  var body = userText.trimLeft();
  for (final raw in stickyIds) {
    final id = raw.trim();
    if (id.isEmpty) continue;
    body = body.replaceAll(composerMentionToken(id), '').trimLeft();
  }
  if (sticky.isEmpty) return body;
  if (body.isEmpty) return sticky;
  return '$sticky $body';
}

List<String> msgMentionIdsDecode(String mentionIdsJson) {
  final raw = mentionIdsJson.trim();
  if (raw.isEmpty || raw == '[]') return const [];
  try {
    final v = jsonDecode(raw);
    if (v is! List) return const [];
    return [for (final e in v) '$e'.trim()].where((e) => e.isNotEmpty).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String msgMentionIdsEncode(Iterable<String> ids) {
  final out = <String>[];
  final seen = <String>{};
  for (final id in ids) {
    final t = id.trim();
    if (t.isEmpty || t == 'image' || !seen.add(t)) continue;
    out.add(t);
  }
  return jsonEncode(out);
}

/// Stable user-bubble text: stored mention ids + inline iid + catalog labels.
String msgUserContentForDisplay({
  required String content,
  required String mentionIdsJson,
  required List<CatalogMention> mentions,
}) {
  final stored = msgMentionIdsDecode(mentionIdsJson);
  final collected = composerMentionIdsCollect(content);
  final ids = [...stored, ...collected.where((id) => !stored.contains(id))];
  var out = composerMentionDisplayRestore(content, mentions, mentionIds: ids);
  if (!composerMentionTextHasTokens(out) && ids.isNotEmpty) {
    out = composerMentionDisplayRestore(out, mentions, mentionIds: ids);
  }
  return out;
}

CatalogMention? composerMentionLookup(List<CatalogMention> mentions, String id) {
  for (final m in mentions) {
    if (m.id == id) return m;
  }
  return null;
}

class ComposerMentionSpanBuilder extends SpecialTextSpanBuilder {
  ComposerMentionSpanBuilder({required this.mentions});

  final List<CatalogMention> mentions;

  @override
  SpecialText? createSpecialText(String flag, {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, required int index}) {
    if (!isStart(flag, composerMentionStart)) return null;
    return _ComposerMentionSpecial(
      mentions: mentions,
      textStyle: textStyle,
      startIndex: index - (composerMentionStart.length - 1),
    );
  }
}

class _ComposerMentionSpecial extends SpecialText {
  _ComposerMentionSpecial({required this.mentions, required TextStyle? textStyle, required this.startIndex})
      : super(composerMentionStart, composerMentionEnd, textStyle);

  final List<CatalogMention> mentions;
  final int startIndex;

  @override
  InlineSpan finishText() {
    final id = getContent();
    final mention = composerMentionLookup(mentions, id);
    final label = mention?.displayLabel ?? id;
    final token = toString();
    return ExtendedWidgetSpan(
      start: startIndex,
      actualText: token,
      deleteAll: true,
      alignment: ui.PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: _ComposerMentionChipInline(mention: mention, fallbackLabel: label),
      ),
    );
  }
}

class _ComposerMentionChipInline extends StatelessWidget {
  const _ComposerMentionChipInline({required this.mention, required this.fallbackLabel});

  final CatalogMention? mention;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final label = mention?.displayLabel ?? fallbackLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      decoration: BoxDecoration(
        color: _chipGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mention?.isDevice == true)
            const Icon(Icons.computer_rounded, size: 13, color: _iconGrey)
          else if (mention != null)
            SizedBox(width: 13, height: 13, child: Center(child: _mentionIcon(mention!)))
          else
            const SizedBox.shrink(),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: zinc100, fontSize: 12.5, height: 1.2, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _mentionIcon(CatalogMention m) {
    if (m.isSite) return const Icon(Icons.language_rounded, size: 13, color: _iconGrey);
    final raw = m.icon.trim();
    if (raw.startsWith('iconify://') || (raw.contains(':') && !raw.contains(' '))) {
      return UiIcon(raw, size: 13, color: _iconGrey, recolor: true);
    }
    return const Icon(Icons.alternate_email_rounded, size: 13, color: _iconGrey);
  }
}

class ComposerMentionMessageText extends StatelessWidget {
  const ComposerMentionMessageText({super.key, required this.text, required this.mentions, this.style});

  final String text;
  final List<CatalogMention> mentions;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ExtendedText(
        text,
        specialTextSpanBuilder: ComposerMentionSpanBuilder(mentions: mentions),
        style: style ?? const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500),
      );
}