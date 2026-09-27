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

bool composerMentionTextHasTokens(String text) =>
    _composerMentionTokenRe.hasMatch(text) || text.contains(composerMentionStart);

String composerMentionPlainText(String text) =>
    text.replaceAll(_composerMentionTokenRe, '').replaceAll(RegExp(r'[ \t]+\n'), '\n').trim();

String composerMentionTextForPrompt(String text, List<CatalogMention> mentions, {List<String>? mentionIds}) {
  var out = text.replaceAllMapped(_composerMentionTokenRe, (m) {
    final id = m.group(1)!.trim();
    return composerMentionLookup(mentions, id)?.displayLabel ?? id;
  });
  final ids = mentionIds ?? composerMentionIdsParse(text);
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

bool composerMentionTextNonempty(String text) =>
    composerMentionPlainText(text).isNotEmpty || composerMentionIdsParse(text).isNotEmpty;

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
            const SizedBox(width: 5),
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