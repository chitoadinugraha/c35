import 'dart:convert';
import 'dart:ui' as ui;

import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/mention/mention_device_icon.dart';
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

bool _composerMentionInsideBracketAt(String text, int index) {
  final before = text.substring(0, index);
  final open = before.lastIndexOf('[@');
  if (open < 0) return false;
  return !before.substring(open).contains(']');
}

String composerMentionPlainIidOutsideBrackets(String text) {
  final buf = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final m = _composerMentionPlainIidRe.matchAsPrefix(text, i);
    if (m != null && !_composerMentionInsideBracketAt(text, i)) {
      buf.write(composerMentionBracketForId(m.group(0)!));
      i = m.end;
      continue;
    }
    buf.write(text[i]);
    i++;
  }
  return buf.toString();
}

/// Bracket mention in stored / wire message text. `[@iid:<snowflake>]`, optional `|label` snapshot.
/// Future kinds (e.g. `[@file:<hash>]`) extend the same pattern — see `_/specs/mention.md`.
final RegExp composerMentionBracketRe = RegExp(r'\[@(iid|catalog|drive):([^\]]+)\]', caseSensitive: false);

(String payload, String? label) composerMentionBracketBodyParts(String body) {
  final b = body.trim();
  final idx = b.indexOf('|');
  if (idx < 0) return (b, null);
  final payload = b.substring(0, idx).trim();
  final label = b.substring(idx + 1).trim();
  if (payload.isEmpty) return (b, null);
  if (label.isEmpty) return (payload, null);
  return (payload, label);
}

String? composerMentionBracketLabelFromBody(String body) => composerMentionBracketBodyParts(body).$2;

String composerMentionBracketForId(String canonicalId, {String? label}) {
  var t = canonicalId.trim();
  if (t.startsWith('[@') && t.contains(']')) {
    final end = t.indexOf(']');
    final inner = t.substring(2, end);
    final colon = inner.indexOf(':');
    if (colon > 0) {
      final id = composerMentionIdFromBracket(inner.substring(0, colon), inner.substring(colon + 1));
      if (id != null) return composerMentionBracketForId(id, label: label);
    }
  }
  final bracketed = composerMentionBracketRe.firstMatch(t);
  String? existingSnap;
  if (bracketed != null) {
    final id = composerMentionIdFromBracket(bracketed.group(1)!, bracketed.group(2)!);
    existingSnap = composerMentionBracketLabelFromBody(bracketed.group(2)!);
    if (id != null) t = id;
  }
  String bracket(String kind, String payload) {
    final (core, snapInPayload) = composerMentionBracketBodyParts(payload);
    final snap = (label?.trim().isNotEmpty == true ? label!.trim() : null) ?? existingSnap ?? snapInPayload;
    if (snap != null && snap.isNotEmpty && !snap.contains(']')) {
      return '[@$kind:$core|$snap]';
    }
    return '[@$kind:$core]';
  }

  if (t.startsWith('iid:')) {
    final (payload, _) = composerMentionBracketBodyParts(t.substring(4));
    return bracket('iid', payload);
  }
  if (t.startsWith('catalog:')) {
    final (payload, _) = composerMentionBracketBodyParts(t.substring(8));
    return bracket('catalog', payload);
  }
  if (t.startsWith('drive:')) {
    final (payload, _) = composerMentionBracketBodyParts(t.substring(6));
    return bracket('drive', payload);
  }
  if (RegExp(r'^\d+$').hasMatch(t)) return bracket('iid', t);
  return bracket('catalog', t);
}

String? composerMentionIdFromBracket(String kind, String body) {
  final k = kind.trim().toLowerCase();
  final (payload, _) = composerMentionBracketBodyParts(body);
  if (payload.isEmpty) return null;
  if (k == 'iid') return 'iid:$payload';
  if (k == 'catalog') return 'catalog:$payload';
  if (k == 'drive') return 'drive:$payload';
  return null;
}

String composerMentionBracketTokenize(String text) => text.replaceAllMapped(composerMentionBracketRe, (m) {
      final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
      return id == null ? m.group(0)! : composerMentionToken(id);
    });

/// Union mention ids for a prompt turn: composer payload, sticky selection, chat meta, and inline text.
List<String> composerMentionIdsForWire({
  Iterable<String>? fromComposer,
  Iterable<String> selectedSticky = const [],
  Iterable<String> chatSticky = const [],
  required String text,
}) {
  final seen = <String>{};
  final out = <String>[];
  void add(String raw) {
    final id = raw.trim();
    if (id.isEmpty || id == 'image' || !seen.add(id)) return;
    out.add(id);
  }
  for (final id in fromComposer ?? const []) {
    add(id);
  }
  for (final id in selectedSticky) {
    add(id);
  }
  for (final id in chatSticky) {
    add(id);
  }
  for (final id in composerMentionIdsCollect(text)) {
    add(id);
  }
  return out;
}

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

String composerMentionComparePlain(String text) {
  var out = composerMentionBracketTokenize(text);
  out = out.replaceAll(_composerMentionTokenRe, ' ');
  out = out.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    final label = composerMentionBracketLabelFromBody(m.group(2)!);
    if (label != null && label.isNotEmpty) return label;
    return id ?? '';
  });
  return out.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

/// Local chip draft vs server `chat_msg.content` for the same turn (not a different user message).
bool composerMentionContentSameTurn(String localDraft, String serverContent) {
  final a = composerMentionComparePlain(localDraft);
  final b = composerMentionComparePlain(serverContent);
  if (a.isEmpty || b.isEmpty) return a == b;
  return a == b;
}

String composerMentionInlineIidTokenize(String text) => text.replaceAllMapped(_composerMentionPlainIidRe, (m) => composerMentionToken(m.group(0)!));

/// `[@` … chip token … `]` — bracket shell left when @ picker inserts a token after typed `[@`.
final RegExp _composerMentionBracketAroundTokenRe = RegExp(r'\[@\s*(\uFFFC[^\uFFFD]+\uFFFD)\s*\]');
final RegExp _composerMentionBracketOpenBeforeTokenRe = RegExp(r'\[@\s*(\uFFFC[^\uFFFD]+\uFFFD)');
final RegExp _composerMentionBracketCloseAfterTokenRe = RegExp(r'(\uFFFC[^\uFFFD]+\uFFFD)\s+\]');

/// Strip incomplete `[@` the user typed before picking a chip (avoids `[@[@iid:…]` on wire).
String composerMentionStripTrailingOpenBracketShell(String before) {
  var b = before;
  for (var i = 0; i < 4; i++) {
    final next = b.replaceFirst(RegExp(r'\[\s*@\s*$'), '');
    if (next == b) break;
    b = next;
  }
  return b;
}

/// Collapse nested `[@` shells before wire / title (mirrors server `mention_bracket_fixup_nesting`).
bool _composerMentionIsLetter(String ch) => RegExp(r'[A-Za-z]').hasMatch(ch);

/// Close unclosed `[@iid:…` before message text; drop truncated open brackets; fix `]word` spacing.
String composerMentionBracketRepair(String text) {
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    if (text.startsWith('[@iid:', i)) {
      final start = i;
      i += 6;
      while (i < text.length && RegExp(r'\d').hasMatch(text[i])) {
        i++;
      }
      if (i < text.length && text[i] == '|') {
        i++;
        while (i < text.length && text[i] != ']' && text[i] != '[') {
          i++;
        }
      }
      if (i < text.length && text[i] == ']') {
        out.write(text.substring(start, i + 1));
        i++;
        continue;
      }
      if (i < text.length && _composerMentionIsLetter(text[i])) {
        out.write(text.substring(start, i));
        out.write('] ');
        continue;
      }
      out.write(text.substring(start, i));
      continue;
    }
    if ((text.startsWith('[@catalog:', i) || text.startsWith('[@drive:', i)) && text.indexOf(':', i) >= 0) {
      final colon = text.indexOf(':', i);
      final start = i;
      i = colon + 1;
      while (i < text.length && text[i] != ']' && text[i] != '[') {
        i++;
      }
      if (i < text.length && text[i] == ']') {
        out.write(text.substring(start, i + 1));
        i++;
        continue;
      }
      if (i < text.length && _composerMentionIsLetter(text[i])) {
        out.write(text.substring(start, i));
        out.write('] ');
        continue;
      }
      out.write(text.substring(start, i));
      continue;
    }
    if (text[i] == ']' && i + 1 < text.length && _composerMentionIsLetter(text[i + 1])) {
      out.write('] ');
      i++;
      continue;
    }
    out.write(text[i]);
    i++;
  }
  return composerMentionStripDanglingOpenBrackets(out.toString());
}

String composerMentionStripDanglingOpenBrackets(String text) {
  var out = text;
  out = out.replaceAll(RegExp(r'\[@(?:iid|catalog|drive):[^\]]*$', caseSensitive: false), '');
  return out.trimRight();
}

String composerMentionBracketFixupNesting(String text) {
  var s = text;
  for (var i = 0; i < 8; i++) {
    final prev = s;
    while (s.contains('[@[@')) {
      s = s.replaceFirst('[@[@', '[@');
    }
    final nestedOpen = '[@' + '@[';
    while (s.contains(nestedOpen)) {
      s = s.replaceFirst(nestedOpen, '[@');
    }
    if (s.startsWith('[@') &&
        !s.startsWith('[@iid:') &&
        !s.startsWith('[@catalog:') &&
        !s.startsWith('[@drive:')) {
      final positions = <int>[
        if (s.contains('[@iid:')) s.indexOf('[@iid:'),
        if (s.contains('[@catalog:')) s.indexOf('[@catalog:'),
        if (s.contains('[@drive:')) s.indexOf('[@drive:'),
      ];
      if (positions.isNotEmpty) {
        final idx = positions.reduce((a, b) => a < b ? a : b);
        if (idx > 0) s = s.substring(idx);
      }
    }
    final pos = s.indexOf('[@iid:');
    if (pos >= 0) {
      final tail = s.substring(pos);
      final r = tail.indexOf(']');
      if (r >= 0) {
        final after = pos + r + 1;
        if (after < s.length && s[after] == ']') {
          s = s.substring(0, after) + s.substring(after + 1);
          continue;
        }
      }
    }
    if (s == prev) break;
  }
  return s;
}

String composerMentionStripBracketShellAroundTokens(String text) {
  var out = text;
  for (var i = 0; i < 8; i++) {
    final next = out.replaceAllMapped(_composerMentionBracketAroundTokenRe, (m) => m.group(1)!);
    if (next == out) break;
    out = next;
  }
  out = out.replaceAllMapped(_composerMentionBracketOpenBeforeTokenRe, (m) => m.group(1)!);
  out = out.replaceAllMapped(_composerMentionBracketCloseAfterTokenRe, (m) => m.group(1)!);
  return out;
}

String composerMentionSanitizeLabelLeaks(String text, List<CatalogMention> mentions) {
  if (text.isEmpty) return text;
  final snapLabels = composerMentionBracketSnapshotLabels(text);
  var out = text;
  final ids = <String>{
    ...composerMentionIdsParse(out),
    ...composerMentionIdsCollect(out),
  };
  for (final id in ids) {
    final label = _composerMentionDisplayLabel(id, mentions, snapLabels);
    if (label.isEmpty || label == id || label.startsWith('iid:')) continue;
    final token = composerMentionToken(id);
    final esc = RegExp.escape(label);
    out = out.replaceAll(RegExp('$token(\\|$esc\\]|\\|$esc)+'), token);
    out = out.replaceAll(RegExp('^\\|$esc(\\|$esc\\]|\\|$esc)*\\]?'), '');
  }
  return out;
}

String composerMentionDisplayFinalize(String text, List<CatalogMention> mentions) {
  var out = composerMentionStripBracketShellAroundTokens(text);
  out = composerMentionStripOrphanBrackets(out);
  out = composerMentionStripDuplicateLabelsAfterTokens(out, mentions);
  out = composerMentionSanitizeLabelLeaks(out, mentions);
  return out;
}

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
  var out = composerMentionBracketRepair(plain);
  out = composerMentionBracketFixupNesting(out);
  out = composerMentionSanitizeLabelLeaks(out, mentions);
  out = composerMentionBracketTokenize(out);
  if (!_composerMentionTokenRe.hasMatch(out)) {
    out = composerMentionInlineIidTokenize(out);
  }
  var rest = out.trimLeft();
  final iidLead = RegExp(r'^(iid:\d+)(?=\s|$)', caseSensitive: false);
  final iidMatch = iidLead.firstMatch(rest);
  if (iidMatch != null) {
    return composerMentionDisplayFinalize(composerMentionToken(iidMatch.group(1)!) + rest.substring(iidMatch.end), mentions);
  }
  final tryIds = mentionIds ?? composerMentionIdsCollect(plain);
  for (final id in tryIds) {
    final m = composerMentionLookup(mentions, id);
    if (m == null) continue;
    final label = m.displayLabel.trim();
    if (label.isEmpty) continue;
    if (!rest.toLowerCase().startsWith(label.toLowerCase())) continue;
    return composerMentionDisplayFinalize(composerMentionToken(id) + rest.substring(label.length), mentions);
  }
  for (final m in mentions) {
    if (!m.isDevice) continue;
    final label = m.displayLabel.trim();
    if (label.isEmpty) continue;
    if (!rest.toLowerCase().startsWith(label.toLowerCase())) continue;
    return composerMentionDisplayFinalize(composerMentionToken(m.id) + rest.substring(label.length), mentions);
  }
  return composerMentionDisplayFinalize(out, mentions);
}

/// Plain text safe for [Text] when mention chips cannot render (empty catalog, reload).
String composerMentionUserContentDisplay(String content, List<CatalogMention> mentions) {
  if (!composerMentionTextHasTokens(content)) return content;
  return composerMentionTextForPrompt(content, mentions, mentionIds: composerMentionIdsCollect(content));
}

Map<String, String> composerMentionBracketSnapshotLabels(String text) {
  final out = <String, String>{};
  for (final m in composerMentionBracketRe.allMatches(text)) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    final snap = composerMentionBracketLabelFromBody(m.group(2)!);
    if (id != null && snap != null && snap.isNotEmpty) {
      out[id] = snap;
    }
  }
  return out;
}

String _composerMentionDisplayLabel(String id, List<CatalogMention> mentions, Map<String, String> snapLabels) {
  return composerMentionLookup(mentions, id)?.displayLabel ?? snapLabels[id] ?? id;
}

String composerMentionTextForPrompt(String text, List<CatalogMention> mentions, {List<String>? mentionIds}) {
  final snapLabels = composerMentionBracketSnapshotLabels(text);
  var out = composerMentionBracketTokenize(text);
  out = out.replaceAllMapped(_composerMentionTokenRe, (m) {
    final id = m.group(1)!.trim();
    return _composerMentionDisplayLabel(id, mentions, snapLabels);
  });
  out = out.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id == null) return m.group(0)!;
    return _composerMentionDisplayLabel(id, mentions, snapLabels);
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
        sb.write(_composerMentionDisplayLabel(id, mentions, snapLabels));
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
  var out = composerMentionBracketRepair(text);
  out = composerMentionBracketFixupNesting(out);
  out = composerMentionStripBracketShellAroundTokens(out);
  out = out.replaceAllMapped(_composerMentionTokenRe, (m) {
    final id = m.group(1)!;
    final label = composerMentionLookup(mentions, id)?.displayLabel;
    return composerMentionBracketForId(id, label: label);
  });
  out = composerMentionPlainIidOutsideBrackets(out);
  out = out.replaceAllMapped(composerMentionBracketRe, (m) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id == null) return m.group(0)!;
    final snap = composerMentionBracketLabelFromBody(m.group(2)!);
    final label = composerMentionLookup(mentions, id)?.displayLabel ?? snap;
    return composerMentionBracketForId(id, label: label);
  });
  var rest = out.trimLeft();
  final ids = mentionIds ?? composerMentionIdsCollect(out);
  if (!rest.startsWith('[@') && !composerMentionBracketRe.hasMatch(rest.split(' ').first)) {
    for (final id in ids) {
      final m = composerMentionLookup(mentions, id);
      if (m == null) continue;
      final label = m.displayLabel.trim();
      if (label.isEmpty || !rest.toLowerCase().startsWith(label.toLowerCase())) continue;
      out = composerMentionBracketForId(id, label: label) + rest.substring(label.length);
      break;
    }
  }
  out = composerMentionBracketFixupNesting(out);
  out = composerMentionSanitizeLabelLeaks(out, mentions);
  return out.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r' {2,}'), ' ').trim();
}

bool composerMentionTextNonempty(String text) =>
    composerMentionPlainText(text).isNotEmpty ||
    composerMentionIdsParse(text).isNotEmpty ||
    composerMentionIdsCollect(text).isNotEmpty;

bool composerMentionStickyId(String id) {
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
    if (!composerMentionStickyId(id) || !seen.add(id)) continue;
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
  return composerMentionDisplayFinalize(out, mentions);
}

CatalogMention? composerMentionLookup(List<CatalogMention> mentions, String id) {
  for (final m in mentions) {
    if (m.id == id) return m;
  }
  return null;
}

/// Catalog rows plus `|label` snapshots from bracket text (for titles / history before catalog loads).
List<CatalogMention> composerMentionCatalogWithBracketSnapshots(String text, List<CatalogMention> mentions) {
  final seen = mentions.map((m) => m.id).toSet();
  final out = List<CatalogMention>.from(mentions);
  for (final m in composerMentionBracketRe.allMatches(text)) {
    final id = composerMentionIdFromBracket(m.group(1)!, m.group(2)!);
    if (id == null || seen.contains(id)) continue;
    final snap = composerMentionBracketLabelFromBody(m.group(2)!);
    if (snap == null || snap.isEmpty) continue;
    seen.add(id);
    out.add(CatalogMention(
      id: id,
      topicId: 'device',
      icon: '',
      color: '',
      labelKey: '',
      captionKey: '',
      label: snap,
      kind: 'identity',
    ));
  }
  return out;
}

/// Stored title / preview with bracket mentions -> chip tokens for [ComposerMentionMessageText].
String composerMentionTextForTitleUi(String text, List<CatalogMention> mentions) {
  var out = composerMentionBracketRepair(text);
  out = composerMentionBracketFixupNesting(out);
  out = composerMentionBracketTokenize(out);
  out = composerMentionDisplayFinalize(out, composerMentionCatalogWithBracketSnapshots(text, mentions));
  return out;
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
        padding: const EdgeInsets.fromLTRB(1, 0, 7, 0),
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
          if (mention != null)
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

  Widget _mentionIcon(CatalogMention m) => catalogMentionIdentityIcon(m, size: 13, iconColor: _iconGrey);
}

class ComposerMentionMessageText extends StatelessWidget {
  const ComposerMentionMessageText({
    super.key,
    required this.text,
    required this.mentions,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final List<CatalogMention> mentions;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => ExtendedText(
        text,
        maxLines: maxLines,
        overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        specialTextSpanBuilder: ComposerMentionSpanBuilder(mentions: mentions),
        style: style ?? const TextStyle(fontSize: 14.5, height: 1.45, color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500),
      );
}