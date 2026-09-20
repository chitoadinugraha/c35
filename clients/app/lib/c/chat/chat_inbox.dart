import 'dart:convert';

import 'package:alienai_c35/c/session.dart';
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

/// Hide usage only on the in-flight assistant (last row). During Ollama wait the last row is the user, so the previous assistant keeps usage.
bool msgUsageStreaming({required bool busy, required int i, required int lastAssistantIdx, required int lastIdx}) =>
    busy && i == lastAssistantIdx && i == lastIdx;

bool msgThoughtIsPlaceholder(String raw) {
  final t = raw.trim().toLowerCase().replaceAll('…', '...').replaceAll(RegExp(r'\.+$'), '');
  return t == 'thinking' || t == 'capturing screen';
}

String msgThoughtStripPlaceholders(String raw) => raw.split('\n').where((line) => !msgThoughtIsPlaceholder(line)).join('\n').trim();

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

bool sessionViewerIsRoot() {
  if (Session.instance.isRoot) return true;
  if (Session.instance.uid == 99000) return true;
  final h = Session.instance.handle.trim().toLowerCase().replaceAll('@', '');
  if (h == 'chito') return true;
  final n = Session.instance.name.trim().toLowerCase().replaceAll('@', '');
  return n == 'chito';
}
