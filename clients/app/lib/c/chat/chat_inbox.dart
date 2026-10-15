import 'dart:convert';

import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';

String chatMsgUsageMsLabel(int durationMs) => uiFmtDurationMs(durationMs);

String chatMsgTimeLabel(int tsMs) {
  if (tsMs <= 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(tsMs).toLocal();
  final h = t.hour;
  final m = t.minute.toString().padLeft(2, '0');
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  final ampm = h >= 12 ? 'PM' : 'AM';
  return '$hour12:$m $ampm';
}

String chatMsgTraceLabel(String reqId) {
  final id = reqId.trim();
  if (id.isEmpty) return '';
  return id.length <= 24 ? id : '${id.substring(0, 22)}…';
}

/// Root / wide-access check for trace and admin UI.
/// Same rules as cs_bots: `isRoot`, uid 99000, or handle `chito`.
bool msgCanTrace({required bool viewerIsRoot, required bool isAssistant, required String reqId}) =>
    viewerIsRoot && isAssistant && reqId.trim().isNotEmpty;

/// Usage spinner on the assistant row for the active prompt turn (`req_id`), not list index.
bool msgUsageStreaming({required bool busy, required String msgReqId, required String liveReqId}) {
  final rid = msgReqId.trim();
  final live = liveReqId.trim();
  return busy && rid.isNotEmpty && live.isNotEmpty && rid == live;
}

bool msgThoughtIsPlaceholder(String raw) {
  final t = raw.trim().toLowerCase().replaceAll('…', '...').replaceAll(RegExp(r'\.+$'), '');
  return t == 'thinking' || t == 'capturing screen';
}

bool msgThoughtIsToolCallingLine(String raw) {
  final t = raw.trim().replaceAll('...', '…').replaceAll(RegExp(r'…+$'), '…');
  return RegExp(r'^Using [\w.]+(…)?$', caseSensitive: false).hasMatch(t);
}

String msgThoughtStripPlaceholders(String raw) =>
    raw.split('\n').where((line) => !msgThoughtIsPlaceholder(line) && !msgThoughtIsToolCallingLine(line)).join('\n').trim();

const _msgUserSteerSuffixMarkers = <String>[
  '\n\n[GOOGLE SHEETS ON DEVICE]',
  '\n\n[GOOGLE FORMS',
  '\n\n[GOOGLE SHEETS PARENT TURN]',
  '\n\n[GOOGLE SHEETS GOTO CELL]',
  '\n\n[RETRY]',
  '\n\n[COMPUTER USE',
];

/// Internal compose/delegate blocks appended after the real user phrase (server child goal).
bool msgUserContentHasSteerSuffix(String raw) =>
    _msgUserSteerSuffixMarkers.any((m) => raw.contains(m));

/// User-visible text only — strips appended steering playbooks.
String msgUserContentPublic(String raw) {
  var out = raw;
  for (final m in _msgUserSteerSuffixMarkers) {
    final i = out.indexOf(m);
    if (i >= 0) out = out.substring(0, i);
  }
  return out.trim();
}

/// Compose / device steering leaked into the visible answer stream (not end-user text).
bool msgStreamLooksLikeSteerLeak(String raw) {
  final t = raw.trimLeft();
  if (t.isEmpty) return false;
  if (msgUserContentHasSteerSuffix(raw) && msgUserContentPublic(raw).isEmpty) {
    return true;
  }
  if (t.startsWith('[') && t.contains(']')) {
    final head = t.split(']').first.toUpperCase();
    if (head.contains('GOOGLE SHEETS') ||
        head.contains('GOOGLE FORMS') ||
        head.contains('RETRY') ||
        head.contains('COMPUTER USE') ||
        head.contains('DELEGATE')) {
      return true;
    }
  }
  return t.startsWith('[GOOGLE SHEETS') ||
      t.startsWith('[GOOGLE FORMS') ||
      t.startsWith('[RETRY]') ||
      t.startsWith('[COMPUTER USE');
}

/// Live status row while the assistant row has no answer text yet (tool hops, prepare).
String msgThoughtLiveStatusLabel({required String thought, required String defaultLabel}) {
  final lines = thought.split('\n');
  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i].trim();
    if (msgThoughtIsToolCallingLine(line)) {
      return line.replaceAll('...', '…');
    }
  }
  final fallback = defaultLabel.trim();
  return fallback.isNotEmpty ? fallback : 'Thinking';
}

String pcToolErrorText(Object error) {
  final s = error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  if (s.contains('Connection refused') || s.contains('Failed host lookup') || s.contains('TimeoutException')) {
    return 'PC runtime is offline';
  }
  return s;
}

Map<String, dynamic> pcToolContinueResult(Map<String, dynamic>? result, Object? error) =>
    error != null ? {'ok': false, 'error': pcToolErrorText(error)} : (result ?? {});

class ChatSseFold {
  String _buf = '';
  Map<String, dynamic> last = {};

  void add(String chunk, {void Function(String delta)? onDelta, void Function(String thought)? onThought}) {
    _buf += chunk;
    final parts = _buf.split('\n\n');
    _buf = parts.isEmpty ? '' : parts.last;
    for (var i = 0; i < parts.length - 1; i++) {
      _apply(parts[i], onDelta: onDelta, onThought: onThought);
    }
  }

  Map<String, dynamic> finish({void Function(String delta)? onDelta, void Function(String thought)? onThought}) {
    if (_buf.trim().isNotEmpty) {
      _apply(_buf, onDelta: onDelta, onThought: onThought);
      _buf = '';
    }
    if (last.isEmpty) throw Exception('empty stream');
    return last;
  }

  void _apply(String raw, {void Function(String delta)? onDelta, void Function(String thought)? onThought}) {
    final line = raw.split('\n').where((l) => l.startsWith('data:')).map((l) => l.substring(5).trim()).join();
    if (line.isEmpty) return;
    final ev = jsonDecode(line) as Map<String, dynamic>;
    if (ev['kind'] == 'delta') onDelta?.call(ev['text']?.toString() ?? '');
    if (ev['kind'] == 'thought') onThought?.call(ev['text']?.toString() ?? '');
    if (ev['kind'] == 'pc_tool' || ev['kind'] == 'done' || ev['kind'] == 'text') last = ev;
    if (ev['kind'] == 'error') throw Exception('${ev['message'] ?? 'Request failed'}');
  }
}

bool chatSseCanFallback(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('connection refused') ||
      s.contains('failed host lookup') ||
      s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('connection reset') ||
      s.contains('connection abort') ||
      s.contains('network is unreachable');
}

Map<String, dynamic> pcToolResultForLlm(Map<String, dynamic> result) {
  final copy = Map<String, dynamic>.from(result)..remove('jpeg_b64');
  if (result['jpeg_b64'] is String && '${result['jpeg_b64']}'.isNotEmpty) copy['jpeg_note'] = 'image attached';
  return copy;
}

bool pcToolIsStaleId(Map<String, dynamic> result) => '${result['reason'] ?? ''}' == 'stale_id';

bool pcToolStaleCanRecapture(String name) {
  final n = name.replaceAll('_', '.');
  return n == 'ui.click' || n == 'mouse.click' || n == 'ui.type';
}

Map<String, dynamic> pcToolStaleRetryArgs(Map<String, dynamic> args, Map<String, dynamic> stale) {
  final label = '${stale['stale_name'] ?? args['name'] ?? ''}'.trim();
  final retry = Map<String, dynamic>.from(args)..remove('id');
  if (label.isNotEmpty) retry['name'] = label;
  return retry;
}

bool pcToolStaleShouldRetry(Map<String, dynamic> retryArgs) => '${retryArgs['name'] ?? ''}'.trim().isNotEmpty;

String msgAssistantProvider({String? stored, required String fallback}) {
  final p = (stored ?? '').trim();
  return p.isEmpty ? fallback : p;
}

bool sessionViewerIsRoot() => Session.instance.isRoot;

String msgErrorNormalize(Object error) {
  final s = error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  if (s.startsWith('Error: ')) return s.substring(7);
  return s;
}

String msgRowError(MsgRow m) {
  final raw = (m as dynamic).error;
  return raw is String ? raw : '';
}

String msgPromptErrorMessage(String raw) => uiPromptErrorMessage(raw);

class MsgUsageStats {
  const MsgUsageStats({this.tokensIn = 0, this.tokensOut = 0, this.tokensCached = 0, this.durationMs = 0, this.costUsd = 0, this.model = ''});
  final int tokensIn;
  final int tokensOut;
  final int tokensCached;
  final int durationMs;
  final double costUsd;
  final String model;
  bool get hasMetrics => tokensIn > 0 || tokensOut > 0 || durationMs > 0 || costUsd > 0;

  bool get hasData => hasMetrics || model.isNotEmpty;
}

/// True when trace fetch can still fill model (and related totals) on assistant rows.
bool msgUsageNeedsTraceBackfill(MsgRow m) {
  if (m.role != 'assistant' || m.reqId.trim().isEmpty) return false;
  return msgUsageStats(m).model.isEmpty;
}

MsgUsageStats msgUsageStats(MsgRow m) {
  var tokensIn = m.tokensIn;
  var tokensOut = m.tokensOut;
  var tokensCached = 0;
  var durationMs = m.durationMs;
  var costUsd = m.costUsd;
  var model = m.model;
  final trace = m.traceJson.trim();
  if (trace.isNotEmpty) {
    try {
      final root = jsonDecode(trace) as Map<String, dynamic>;
      if (durationMs <= 0) durationMs = root['duration_ms'] as int? ?? (root['duration_ms'] as num?)?.toInt() ?? 0;
      if (costUsd <= 0) costUsd = (root['cost_usd'] as num?)?.toDouble() ?? 0;
      if (model.isEmpty) model = '${root['model'] ?? ''}';
      if (tokensIn <= 0) tokensIn = root['tokens_in'] as int? ?? (root['tokens_in'] as num?)?.toInt() ?? 0;
      if (tokensOut <= 0) tokensOut = root['tokens_out'] as int? ?? (root['tokens_out'] as num?)?.toInt() ?? 0;
      tokensCached = root['cached_tokens'] as int? ?? (root['cached_tokens'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }
  return MsgUsageStats(tokensIn: tokensIn, tokensOut: tokensOut, tokensCached: tokensCached, durationMs: durationMs, costUsd: costUsd, model: model);
}

bool msgModelUsesAllowancePool(String model) {
  final m = model.trim().toLowerCase();
  return m.isEmpty || m == 'alienai' || m == 'auto' || m == 'alien' || m == 'cloud';
}

bool msgUsageBillingIncluded(MsgRow m, {String model = ''}) {
  final trace = m.traceJson.trim();
  if (trace.isNotEmpty) {
    try {
      final root = jsonDecode(trace);
      if (root is Map<String, dynamic>) {
        if (root['billing_included'] == true) return true;
        if (root['billing_included'] == false) return false;
      }
    } catch (_) {}
  }
  final slug = model.trim().isNotEmpty ? model : m.model;
  return msgModelUsesAllowancePool(slug);
}

String msgDisplayContent(MsgRow m) {
  var c = m.content;
  final err = msgRowError(m).trim();
  if (err.isNotEmpty) {
    for (final suffix in ['\n\nError: $err', '\nError: $err', 'Error: $err']) {
      if (c.endsWith(suffix)) return c.substring(0, c.length - suffix.length).trimRight();
    }
    if (c.endsWith(err)) return c.substring(0, c.length - err.length).trimRight();
  }
  final legacy = RegExp(r'\.?Error:\s*.+$');
  if (legacy.hasMatch(c)) return c.replaceFirst(legacy, '').trimRight();
  return c;
}
