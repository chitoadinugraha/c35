import 'dart:convert';

import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';

class TraceToolFilterCandidate {
  const TraceToolFilterCandidate({required this.toolId, this.sim = 0, this.fed = false, this.isInst = false});
  final String toolId;
  final double sim;
  final bool fed;
  final bool isInst;
}

class TraceScreenshot {
  const TraceScreenshot({this.hash = '', this.url = '', this.width = 0, this.height = 0, this.som = false, this.marker = false});
  final String hash;
  final String url;
  final int width;
  final int height;
  final bool som;
  final bool marker;

  bool get hasPreview => hash.trim().isNotEmpty || url.trim().isNotEmpty;
  String get imageSrc => traceScreenshotImageSrc(hash: hash, url: url);
}

String traceScreenshotImageSrc({String hash = '', String url = ''}) {
  final u = url.trim();
  if (u.isNotEmpty) return u;
  final h = hash.trim();
  if (h.isEmpty) return '';
  if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
  return '/fs/$h';
}

TraceScreenshot? traceScreenshotFromLog(TraceLogDoc log) {
  final raw = log.meta['screenshot'];
  if (raw is Map) {
    final hash = _asStr(raw['hash']);
    final url = _asStr(raw['url']);
    if (hash.isNotEmpty || url.isNotEmpty) {
      return TraceScreenshot(
        hash: hash,
        url: url,
        width: _asInt(raw['width']),
        height: _asInt(raw['height']),
        som: raw['som'] == true,
        marker: raw['marker'] == true,
      );
    }
  }
  final json = traceToolJsonFromLog(log);
  if (json == null) return null;
  final hash = _asStr(json['image_hash']);
  final url = _asStr(json['image_url']);
  if (hash.isEmpty && url.isEmpty) return null;
  return TraceScreenshot(
    hash: hash,
    url: url,
    width: _asInt(json['width']),
    height: _asInt(json['height']),
    som: json['som'] == true,
    marker: json['marker'] == true,
  );
}

class TraceBranch {
  const TraceBranch({
    required this.label,
    this.stageKey = '',
    this.isTool = false,
    this.iconUrl = '',
    this.durationMs = 0,
    this.costUsd = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.ok = true,
    this.detail = '',
    this.parallel = false,
    this.toolCandidates = const [],
    this.droppedGap = const [],
    this.ragSkipped = false,
    this.ragSkipReason = '',
    this.screenshot,
  });
  final String label;
  /// Server stage key or trace topic — used for UI grouping.
  final String stageKey;
  final bool isTool;
  final String iconUrl;
  final int durationMs;
  final double costUsd;
  final int tokensIn;
  final int tokensOut;
  final bool ok;
  final String detail;
  final bool parallel;
  final List<TraceToolFilterCandidate> toolCandidates;
  final List<TraceToolFilterCandidate> droppedGap;
  final bool ragSkipped;
  final String ragSkipReason;
  final TraceScreenshot? screenshot;

  bool get hasToolFilterDetail => toolCandidates.isNotEmpty || droppedGap.isNotEmpty;
  bool get hasScreenshotPreview => screenshot?.hasPreview ?? false;
}

class TraceBranchGroup {
  const TraceBranchGroup({required this.id, required this.title, this.branches = const []});
  final String id;
  final String title;
  final List<TraceBranch> branches;

  int get durationMs {
    if (branches.isEmpty) return 0;
    if (id == 'billing' || id == 'setup') {
      return branches.fold(0, (a, b) => a + b.durationMs);
    }
    var max = 0;
    for (final b in branches) {
      if (b.durationMs > max) max = b.durationMs;
    }
    return max;
  }

  double get costUsd => branches.fold(0.0, (a, b) => a + b.costUsd);

  String get collapsedSubtitle {
    if (id == 'instruction') {
      final inst = branches
          .expand((b) => b.toolCandidates)
          .where((c) => c.isInst && c.fed)
          .map((c) => c.toolId)
          .toSet()
          .length;
      if (inst > 0) return '$inst inst';
    }
    final n = branches.length;
    return n == 1 ? '1 step' : '$n steps';
  }
}

const _traceGroupOrder = ['vision', 'billing', 'setup', 'context', 'instruction', 'tools', 'other'];

const _traceGroupTitles = <String, String>{
  'vision': 'Desktop vision',
  'billing': 'Billing',
  'setup': 'Setup',
  'context': 'Context',
  'instruction': 'Instruction',
  'tools': 'Tools & embed',
  'other': 'Other',
};

String traceBranchGroupKey(TraceBranch branch) {
  final k = branch.stageKey.trim().toLowerCase();
  final label = branch.label.trim().toLowerCase();
  if (k == 'llm_vision' || (branch.hasScreenshotPreview && !label.contains('device.screenshot'))) {
    return 'vision';
  }
  if (k == 'billing_resolve' ||
      k == 'billing_gate' ||
      k == 'trace_gate' ||
      label.contains('billing') ||
      label.contains('quota') ||
      label.contains('settle')) {
    return 'billing';
  }
  if (k == 'chat_setup' ||
      k == 'trace_setup' ||
      k == 'last_turn_cleanup' ||
      k == 'persist_user_msg' ||
      k == 'prompt_run' ||
      k == 'compose' ||
      label.contains('chat &') ||
      label.contains('cleanup') ||
      label.contains('save user message') ||
      label.contains('checkpoint') ||
      label.contains('compose tools')) {
    return 'setup';
  }
  if (k == 'inst_list' ||
      k == 'trace_inst_enrich' ||
      k == 'trace_scope_instruction' ||
      k == 'scope_instruction' ||
      k == 'topic_block' ||
      label.contains('inst ') ||
      label.contains('instruction') ||
      label.contains('topic instruction')) {
    return 'instruction';
  }
  if (k == 'trace_tool_filter' ||
      k == 'trace_tool_embed' ||
      k == 'embed_warm' ||
      label.contains('tool filter') ||
      label.contains('prompt embed') ||
      label.contains('embed')) {
    return 'tools';
  }
  return 'context';
}

/// Collapse long prepare/settle branch lists into labeled sections.
List<TraceBranchGroup> groupTraceStepBranches(TraceStep step) {
  if (step.branches.isEmpty) return const [];
  final grouped = <String, List<TraceBranch>>{};
  for (final b in step.branches) {
    final key = traceBranchGroupKey(b);
    grouped.putIfAbsent(key, () => []).add(b);
  }
  final out = <TraceBranchGroup>[];
  for (final id in _traceGroupOrder) {
    final rows = grouped.remove(id);
    if (rows == null || rows.isEmpty) continue;
    if (id == 'vision') {
      rows.sort((a, b) {
        final aStart = a.label.toLowerCase().contains('turn-start') ? 0 : 1;
        final bStart = b.label.toLowerCase().contains('turn-start') ? 0 : 1;
        return aStart.compareTo(bStart);
      });
    }
    out.add(TraceBranchGroup(id: id, title: _traceGroupTitles[id] ?? id, branches: rows));
  }
  for (final entry in grouped.entries) {
    if (entry.value.isEmpty) continue;
    out.add(TraceBranchGroup(id: entry.key, title: _traceGroupTitles[entry.key] ?? entry.key, branches: entry.value));
  }
  return out;
}

bool traceStepUsesBranchGroups(TraceStep step) => step.title == 'Prepare' || step.title == 'Settle';

class TraceStep {
  const TraceStep({
    required this.index,
    required this.title,
    this.durationMs = 0,
    this.costUsd = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.tokensCached = 0,
    this.model = '',
    this.branches = const [],
    this.detail = '',
    this.modelReasoning = '',
  });

  final int index;
  final String title;
  final int durationMs;
  final double costUsd;
  final int tokensIn;
  final int tokensOut;
  final int tokensCached;
  final String model;
  final List<TraceBranch> branches;
  final String detail;
  /// Internal model reasoning for this LLM hop (root trace only; from `llm_call` meta).
  final String modelReasoning;
}

class TraceTotals {
  const TraceTotals({this.tokensIn = 0, this.tokensOut = 0, this.tokensCached = 0, this.durationMs = 0, this.costUsd = 0, this.model = ''});
  final int tokensIn;
  final int tokensOut;
  final int tokensCached;
  final int durationMs;
  final double costUsd;
  final String model;
}

class TraceView {
  const TraceView({this.steps = const [], this.totals = const TraceTotals()});
  final List<TraceStep> steps;
  final TraceTotals totals;
  bool get isEmpty => steps.isEmpty && totals.tokensIn == 0 && totals.tokensOut == 0;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _asStr(dynamic v) => v == null ? '' : '$v'.trim();

double _asFloat(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

List<TraceToolFilterCandidate> _toolCandidatesFromMeta(dynamic raw) {
  if (raw is! List) return const [];
  final out = <TraceToolFilterCandidate>[];
  for (final row in raw) {
    if (row is! Map) continue;
    final toolId = _asStr(row['tool_id']).isNotEmpty ? _asStr(row['tool_id']) : _asStr(row['toolId']);
    if (toolId.isEmpty) continue;
    out.add(TraceToolFilterCandidate(toolId: toolId, sim: _asFloat(row['sim']), fed: row['fed'] == true));
  }
  return out;
}

List<String> _stringListFromMeta(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => _asStr(e)).where((s) => s.isNotEmpty).toList();
}

String traceModelLabel(String model) {
  final m = model.trim().toLowerCase();
  if (m.isEmpty || m == 'auto' || m == 'alien' || m == 'alienai' || m == 'cloud') return 'alienai';
  return model.trim();
}

Map<String, dynamic>? traceToolJsonFromLog(TraceLogDoc log) {
  final preview = _asStr(log.meta['output_preview']);
  final text = log.text.trim();
  final jsonStr = preview.isNotEmpty ? preview : text;
  if (jsonStr.isEmpty) return null;
  try {
    final raw = jsonDecode(jsonStr);
    if (raw is Map) return raw.map((k, v) => MapEntry('$k', v));
  } catch (_) {
    if (jsonStr.endsWith('…')) {
      try {
        final raw = jsonDecode(jsonStr.substring(0, jsonStr.length - 1));
        if (raw is Map) return raw.map((k, v) => MapEntry('$k', v));
      } catch (_) {}
    }
  }
  return null;
}

Map<String, String> traceToolVarsFromLog(TraceLogDoc log, {bool done = true}) {
  final vars = <String, String>{'source': '', 'query': '', 'url': '', 'detail': ''};
  final tool = _asStr(log.meta['tool']).replaceAll('_', '.').trim();
  final args = log.meta['args'];
  if (args is Map) {
    final url = _asStr(args['url']);
    vars['url'] = url;
    vars['source'] = citationHost(url);
    vars['query'] = _asStr(args['query']).isNotEmpty ? _asStr(args['query']) : _asStr(args['q']);
    if (tool == 'device.input') {
      vars['detail'] = traceDeviceInputDetailFromArgs(args, done: done);
    } else if (tool == 'device.screenshot') {
      vars['detail'] = args['som'] == true ? catalogT('tool.device.screenshot.detail.som') : catalogT('tool.device.screenshot.detail.screen');
    } else if (tool == 'shell.run') {
      vars['detail'] = _truncateTraceDetail(_asStr(args['command']));
      if (vars['detail']!.isEmpty) {
        vars['detail'] = catalogT('tool.var.shell_command');
      }
    }
  }
  final raw = traceToolJsonFromLog(log);
  if (raw != null) {
    final url = _asStr(raw['url']);
    if (url.isNotEmpty) {
      vars['url'] = url;
      vars['source'] = citationHost(url);
    }
    final query = _asStr(raw['query']);
    if (query.isNotEmpty) vars['query'] = query;
    if (raw['results'] is List && (vars['query']?.isEmpty ?? true)) {
      for (final item in raw['results'] as List) {
        if (item is! Map) continue;
        final title = _asStr(item['title']);
        if (title.isNotEmpty) {
          vars['query'] = title;
          break;
        }
      }
    }
  }
  return vars;
}

bool traceToolUsesFavicon(String toolId) {
  final tool = toolId.replaceAll('_', '.').trim();
  return tool == 'web.visit' || tool == 'web.search' || tool == 'web.research';
}

String traceToolIconUrlFromLog(TraceLogDoc log) {
  final tool = _asStr(log.meta['tool']);
  if (!traceToolUsesFavicon(tool)) return '';
  var url = traceToolVarsFromLog(log)['url'] ?? '';
  if (url.isEmpty) {
    final raw = traceToolJsonFromLog(log);
    if (raw?['results'] is List) {
      for (final item in raw!['results'] as List) {
        if (item is! Map) continue;
        final u = _asStr(item['url']);
        if (u.isNotEmpty) {
          url = u;
          break;
        }
      }
    }
  }
  return url.isNotEmpty ? citationFaviconUrl(url) : '';
}

String _truncateTraceDetail(String text, {int max = 28}) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty) return '';
  if (t.length <= max) return t;
  return '${t.substring(0, max)}…';
}

String traceDeviceInputDetailFromArgs(dynamic args, {bool done = true}) {
  if (args is! Map) return '';
  final actions = args['actions'];
  if (actions is List && actions.length > 1) {
    final key = done ? 'tool.device.input.batch.done' : 'tool.device.input.batch.calling';
    return toolLabelFromTemplate(catalogT(key), {'count': '${actions.length}'});
  }
  final Map<dynamic, dynamic> event;
  if (actions is List && actions.isNotEmpty && actions.first is Map) {
    event = actions.first as Map;
  } else {
    event = args;
  }
  return _deviceInputEventDetail(event, done: done);
}

String _deviceInputEventDetail(Map<dynamic, dynamic> event, {required bool done}) {
  var type = _asStr(event['event_type']).toLowerCase();
  if (type.isEmpty && (event.containsKey('x') || event.containsKey('y'))) {
    type = 'mouse_click';
  }
  final text = _asStr(event['text']);
  switch (type) {
    case 'mouse_click':
    case 'double_click':
    case 'triple_click':
    case 'right_click':
    case 'middle_click':
      return catalogT(done ? 'tool.device.input.clicked.done' : 'tool.device.input.clicked.calling');
    case 'type_text':
    case 'click_and_type':
    case 'clear_text':
      final snippet = _truncateTraceDetail(text);
      if (snippet.isEmpty) {
        return catalogT(done ? 'tool.device.input.typed.done' : 'tool.device.input.typed.calling');
      }
      final tpl = catalogT(done ? 'tool.device.input.typed_text.done' : 'tool.device.input.typed_text.calling');
      return toolLabelFromTemplate(tpl, {'text': snippet});
    case 'shortcut':
    case 'key_down':
    case 'key_up':
      final keys = text.isNotEmpty ? text : _asStr(event['key_code']);
      if (keys.isEmpty) {
        return catalogT(done ? 'tool.device.input.shortcut.done' : 'tool.device.input.shortcut.calling');
      }
      final tpl = catalogT(done ? 'tool.device.input.shortcut_keys.done' : 'tool.device.input.shortcut_keys.calling');
      return toolLabelFromTemplate(tpl, {'keys': keys});
    case 'mouse_move':
      return catalogT(done ? 'tool.device.input.moved.done' : 'tool.device.input.moved.calling');
    case 'mouse_drag':
    case 'mouse_stroke':
      return catalogT(done ? 'tool.device.input.dragged.done' : 'tool.device.input.dragged.calling');
    case 'wheel':
      return catalogT(done ? 'tool.device.input.scrolled.done' : 'tool.device.input.scrolled.calling');
    case 'clipboard_image':
    case 'clipboard_paste_image':
      return catalogT(done ? 'tool.device.input.pasted.done' : 'tool.device.input.pasted.calling');
    default:
      return '';
  }
}

String toolLabelFromTemplate(String template, Map<String, String> vars) {
  var out = template.trim();
  if (out.isEmpty) return '';
  final source = (vars['source'] ?? '').trim().isNotEmpty ? vars['source']!.trim() : catalogT('tool.var.source');
  final query = (vars['query'] ?? '').trim().isNotEmpty ? vars['query']!.trim() : catalogT('tool.var.query');
  final url = (vars['url'] ?? '').trim();
  final detail = (vars['detail'] ?? '').trim().isNotEmpty ? vars['detail']!.trim() : catalogT('tool.var.device_action');
  final count = (vars['count'] ?? '').trim();
  final text = (vars['text'] ?? '').trim();
  final keys = (vars['keys'] ?? '').trim();
  out = out
      .replaceAll('{{source}}', source)
      .replaceAll('{{query}}', query)
      .replaceAll('{{url}}', url)
      .replaceAll('{{detail}}', detail)
      .replaceAll('{{count}}', count.isNotEmpty ? count : '0')
      .replaceAll('{{text}}', text)
      .replaceAll('{{keys}}', keys);
  return out.replaceAll('…', '').trim();
}

String traceSubagentLabelFromLog(TraceLogDoc log) {
  final sub = log.meta['subagent'];
  if (sub is! Map) return '';
  final kind = _asStr(sub['kind']);
  final topic = _asStr(sub['topic_id']);
  final child = _asStr(sub['child_req_id']);
  final status = _asStr(sub['status']);
  final parts = <String>['Subagent'];
  if (kind.isNotEmpty) parts.add(kind);
  if (topic.isNotEmpty && topic != kind) parts.add(topic);
  if (status.isNotEmpty) parts.add(status);
  if (child.isNotEmpty) {
    final tail = child.length > 8 ? child.substring(child.length - 8) : child;
    parts.add('…$tail');
  }
  return parts.join(' · ');
}

String traceToolLabelFromLog(TraceLogDoc log, {bool done = true}) {
  final subagent = traceSubagentLabelFromLog(log);
  if (subagent.isNotEmpty) return subagent;
  final tool = _asStr(log.meta['tool']).replaceAll('_', '.').trim();
  if (tool.isEmpty) return 'Tool';
  final key = 'tool.$tool.${done ? 'done' : 'calling'}';
  final template = catalogT(key);
  if (template == key) return tool;
  return toolLabelFromTemplate(template, traceToolVarsFromLog(log, done: done));
}

String traceToolLabel(String toolId) {
  final id = toolId.replaceAll('_', '.').trim();
  if (id.isEmpty) return 'Tool';
  return toolLabelFromTemplate(catalogT('tool.$id.done'), const {});
}

String _scopeInstructionTraceDetail(Map<dynamic, dynamic> meta) {
  final injected = meta['injected'] == true;
  final preview = _asStr(meta['block_preview']);
  final entries = meta['entries'];
  final applied = <String>[];
  final configured = <String>[];
  if (entries is List) {
    for (final e in entries) {
      if (e is! Map) continue;
      final kind = _asStr(e['scope_kind']);
      final mode = _asStr(e['mode']);
      final name = _asStr(e['site_name']);
      final label = kind == 'site' && name.isNotEmpty ? 'site:$name' : kind;
      configured.add('$label ($mode)');
      if (e['applied'] == true) applied.add(label);
    }
  }
  if (injected && preview.isNotEmpty) {
    final head = applied.isEmpty ? 'Injected' : 'Injected: ${applied.join(', ')}';
    return '$head · $preview';
  }
  if (applied.isNotEmpty) return 'Matched: ${applied.join(', ')}';
  if (configured.isNotEmpty) return 'Configured: ${configured.join(', ')} · not injected';
  return preview;
}

List<TraceToolFilterCandidate> _userAssetsCandidatesFromMeta(Map<dynamic, dynamic> meta) {
  final out = <TraceToolFilterCandidate>[];
  for (final raw in [meta['sites'], meta['bots']]) {
    if (raw is! List) continue;
    for (final row in raw) {
      if (row is! Map) continue;
      final name = _asStr(row['name']).isNotEmpty ? _asStr(row['name']) : _asStr(row['alien_id']);
      if (name.isEmpty) continue;
      out.add(TraceToolFilterCandidate(toolId: name, sim: _asFloat(row['sim']), fed: row['injected'] == true));
    }
  }
  return out;
}

String _userAssetSectionDetail(String sectionLabel, dynamic raw) {
  if (raw is! List) return '';
  final injected = <String>[];
  for (final row in raw) {
    if (row is! Map || row['injected'] != true) continue;
    final name = _asStr(row['name']).isNotEmpty ? _asStr(row['name']) : _asStr(row['alien_id']);
    if (name.isEmpty) continue;
    final sim = _asFloat(row['sim']);
    injected.add(sim > 0 ? '$name · ${traceSimLabel(sim)}' : name);
  }
  if (injected.isEmpty) return '';
  return '$sectionLabel: ${injected.join(', ')}';
}

String _userAssetsTraceDetail(Map<dynamic, dynamic> meta) {
  final parts = [
    _userAssetSectionDetail('Sites', meta['sites']),
    _userAssetSectionDetail('Bots', meta['bots']),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isNotEmpty) return parts.join(' · ');
  if (meta['injected'] != true) return 'Not injected';
  final blockChars = _asInt(meta['block_chars']);
  if (blockChars > 0) return 'Injected · $blockChars chars';
  return 'Injected';
}

int _prepareBranchOrder(String topic) => switch (topic) {
      'trace_gate' => -2,
      'trace_setup' => -1,
      'trace_tool_embed' => 0,
      'trace_inst_enrich' => 1,
      'trace_scope_instruction' => 2,
      'trace_user_assets' => 3,
      'trace_tool_filter' => 4,
      'trace_prepare' => 5,
      'trace_memory' => 6,
      'llm_vision' => -3,
      _ => 9,
    };

List<TraceBranch> _stageBranchesFromRows(List<TraceLogDoc> rows) {
  final out = <TraceBranch>[];
  for (final r in rows) {
    final raw = r.meta['stages'];
    if (raw is! List) continue;
    final items = raw.whereType<Map>().toList()
      ..sort((a, b) => _asInt(a['start_ms']).compareTo(_asInt(b['start_ms'])));
    for (final s in items) {
      final label = _asStr(s['label']);
      if (label.isEmpty) continue;
      final parallel = s['parallel'] == true;
      out.add(TraceBranch(
        label: label,
        stageKey: _asStr(s['key']),
        durationMs: _asInt(s['ms']),
        parallel: parallel,
        detail: '+${_asInt(s['start_ms'])}ms${parallel ? ' · parallel' : ''}',
      ));
    }
  }
  return out;
}
String traceHopTitle(int hop, List<String> toolBranches, {required bool hasReplyText}) {
  if (toolBranches.isNotEmpty) return 'Tool run · ${toolBranches.join(', ')}';
  if (hasReplyText || hop >= 99) return 'Reply';
  return 'Planning';
}

TraceBranch _branchFromLog(TraceLogDoc log) {
  final meta = log.meta;
  final tool = _asStr(meta['tool']);
  final branch = _asStr(meta['branch']);
  final isLlmVision = log.topic == 'llm_vision';
  final label = isLlmVision
      ? (branch.isNotEmpty ? branch : 'LLM vision')
      : tool.isNotEmpty
          ? traceToolLabelFromLog(log)
          : branch.isNotEmpty
              ? branch
              : log.text.split('\n').first;
  final isTool = tool.isNotEmpty ||
      log.topic == 'tool_result' ||
      log.topic == 'tool_error' ||
      log.kind == 'tool' ||
      isLlmVision;
  return TraceBranch(
    label: label,
    isTool: isTool,
    iconUrl: isTool ? traceToolIconUrlFromLog(log) : '',
    durationMs: log.durationMs > 0 ? log.durationMs : _asInt(meta['duration_ms']),
    costUsd: log.costUsd > 0 ? log.costUsd : _asDouble(meta['cost_retail_usd']),
    tokensIn: log.tokensIn,
    tokensOut: log.tokensOut,
    ok: meta['ok'] as bool? ?? log.topic != 'tool_error',
    detail: log.text.length > 120 ? '${log.text.substring(0, 120)}…' : log.text,
    screenshot: isTool ? traceScreenshotFromLog(log) : null,
  );
}

TraceView buildTraceView(List<TraceLogDoc> logs) {
  final byStep = <int, List<TraceLogDoc>>{};
  TraceTotals totals = const TraceTotals();

  for (final log in logs) {
    final meta = log.meta;
    final topic = log.topic.isNotEmpty ? log.topic : _asStr(meta['topic']);
    if (topic == 'llm_turn' || (log.kind == 'llm' && topic == 'llm_turn')) {
      totals = TraceTotals(
        tokensIn: _asInt(meta['prompt_tokens']).clamp(0, 1 << 30) > 0 ? _asInt(meta['prompt_tokens']) : log.tokensIn,
        tokensOut: _asInt(meta['completion_tokens']).clamp(0, 1 << 30) > 0 ? _asInt(meta['completion_tokens']) : log.tokensOut,
        tokensCached: _asInt(meta['cached_tokens']),
        durationMs: _asInt(meta['duration_ms']) > 0 ? _asInt(meta['duration_ms']) : log.durationMs,
        costUsd: _asDouble(meta['cost_retail_usd']) > 0 ? _asDouble(meta['cost_retail_usd']) : log.costUsd,
        model: traceModelLabel(log.model),
      );
      continue;
    }
    final step = _asInt(meta['step']);
    if (step <= 0) continue;
    byStep.putIfAbsent(step, () => []).add(log);
  }

  final steps = <TraceStep>[];
  final keys = byStep.keys.where((k) => k != 9999).toList()..sort();
  var llmHop = 0;
  for (final stepNum in keys) {
    final rows = byStep[stepNum]!;
    final main = rows.firstWhere((r) => r.topic == 'llm_call' || (r.kind == 'llm' && r.meta['hop'] != null), orElse: () => rows.first);
    final branches = <TraceBranch>[];
    final TraceStep hopStep;
    if (main.topic == 'llm_call' || main.kind == 'llm') {
      llmHop++;
      final meta = main.meta;
      final hop = _asInt(meta['hop']) > 0 ? _asInt(meta['hop']) : llmHop;
      final branchRows = rows.where((r) =>
          r.topic == 'tool_result' ||
          r.topic == 'tool_error' ||
          r.topic == 'llm_vision' ||
          (r.kind == 'tool'));
      for (final b in branchRows) {
        branches.add(_branchFromLog(b));
      }
      final toolBranches = branches.where((b) => b.isTool && b.label.isNotEmpty).map((b) => b.label).toList();
      final replyText = main.text.trim();
      final hopTitle = traceHopTitle(hop, toolBranches, hasReplyText: replyText.isNotEmpty);
      hopStep = TraceStep(
        index: hop,
        title: hopTitle,
        durationMs: main.durationMs > 0 ? main.durationMs : _asInt(meta['duration_ms']),
        costUsd: main.costUsd > 0 ? main.costUsd : _asDouble(meta['cost_retail_usd']),
        tokensIn: main.tokensIn > 0 ? main.tokensIn : _asInt(meta['prompt_tokens']),
        tokensOut: main.tokensOut > 0 ? main.tokensOut : _asInt(meta['completion_tokens']),
        tokensCached: _asInt(meta['cached_tokens']),
        model: traceModelLabel(main.model),
        branches: branches,
        modelReasoning: _asStr(meta['model_reasoning']),
      );
    } else if (stepNum == 9998 || rows.any((r) => r.topic == 'trace_settle')) {
      final settleRow = rows.firstWhere((r) => r.topic == 'trace_settle', orElse: () => rows.first);
      final meta = settleRow.meta;
      final settleMs = settleRow.durationMs > 0 ? settleRow.durationMs : _asInt(meta['duration_ms']);
      final settleStages = _stageBranchesFromRows([settleRow]);
      final branch = TraceBranch(
        label: 'Billing settle & save',
        durationMs: settleMs,
        detail: settleRow.text.split('\n').first,
      );
      hopStep = TraceStep(
        index: steps.length,
        title: 'Settle',
        durationMs: settleMs,
        branches: settleStages.isNotEmpty ? settleStages : [branch],
      );
    } else {
      final stageRows = rows.where((r) => r.topic == 'trace_stages').toList();
      branches.addAll(_stageBranchesFromRows(stageRows));
      final prepRows = rows.where((r) => r.topic != 'trace_stages').toList()
        ..sort((a, b) {
          final ta = a.topic.isNotEmpty ? a.topic : _asStr(a.meta['topic']);
          final tb = b.topic.isNotEmpty ? b.topic : _asStr(b.meta['topic']);
          return _prepareBranchOrder(ta).compareTo(_prepareBranchOrder(tb));
        });
      for (final r in prepRows) {
        if (stageRows.isNotEmpty && (r.topic == 'trace_gate' || r.topic == 'trace_setup' || r.topic == 'trace_prepare')) {
          continue;
        }
        final branch = _asStr(r.meta['branch']);
        final label = switch (r.topic) {
          'trace_gate' => 'Quota & hold gate',
          'trace_setup' => 'Chat & message setup',
          'trace_tool_embed' => 'Prompt embed',
          'trace_memory' => 'Memory',
          'trace_inst_enrich' => 'Inst enrich',
          'trace_scope_instruction' => 'Scope instructions',
          'trace_user_assets' => 'User assets',
          'trace_tool_filter' => 'Tool filter',
          'trace_prepare' => 'Compose',
          'llm_vision' => branch.isNotEmpty ? branch : 'LLM vision',
          _ => branch.isNotEmpty ? branch : r.topic,
        };
        final instIds = r.topic == 'trace_inst_enrich' ? _stringListFromMeta(r.meta['inst_ids']) : const <String>[];
        final enrichKeys = r.topic == 'trace_inst_enrich' ? _stringListFromMeta(r.meta['enrich_keys']) : const <String>[];
        final durMs = r.topic == 'trace_prepare'
            ? (_asInt(r.meta['compose_ms']) > 0 ? _asInt(r.meta['compose_ms']) : _asInt(r.meta['duration_ms']))
            : (r.durationMs > 0 ? r.durationMs : _asInt(r.meta['duration_ms']));
        branches.add(TraceBranch(
          label: label,
          stageKey: r.topic.isNotEmpty ? r.topic : _asStr(r.meta['topic']),
          durationMs: durMs,
          costUsd: r.costUsd > 0 ? r.costUsd : _asDouble(r.meta['cost_retail_usd']),
          tokensIn: r.tokensIn > 0 ? r.tokensIn : _asInt(r.meta['prompt_tokens']),
          detail: r.topic == 'trace_scope_instruction'
              ? _scopeInstructionTraceDetail(r.meta)
              : r.topic == 'trace_user_assets'
                  ? _userAssetsTraceDetail(r.meta)
                  : r.text.split('\n').first,
          screenshot: r.topic == 'llm_vision' ? traceScreenshotFromLog(r) : null,
          isTool: r.topic == 'trace_inst_enrich' && (instIds.isNotEmpty || enrichKeys.isNotEmpty),
          toolCandidates: r.topic == 'trace_tool_filter'
              ? _toolCandidatesFromMeta(r.meta['candidates'])
              : r.topic == 'trace_user_assets'
                  ? _userAssetsCandidatesFromMeta(r.meta)
                  : r.topic == 'trace_inst_enrich'
                      ? [
                          ...instIds.map((id) => TraceToolFilterCandidate(toolId: id, sim: 1, fed: true, isInst: true)),
                          ...enrichKeys.map((k) => TraceToolFilterCandidate(toolId: k, sim: 1, fed: true)),
                        ]
                      : const [],
          droppedGap: r.topic == 'trace_tool_filter' ? _toolCandidatesFromMeta(r.meta['dropped_gap']) : const [],
          ragSkipped: r.topic == 'trace_tool_filter' && r.meta['rag_skipped'] == true,
          ragSkipReason: r.topic == 'trace_tool_filter' ? _asStr(r.meta['rag_skip_reason']) : '',
        ));
      }
      final prepareWallMs = rows
          .where((r) => r.topic == 'trace_stages' || r.topic == 'trace_prepare')
          .map((r) => _asInt(r.meta['prepare_ms']))
          .where((ms) => ms > 0)
          .fold(0, (a, b) => b > a ? b : a);
      hopStep = TraceStep(
        index: 0,
        title: 'Prepare',
        durationMs: prepareWallMs > 0
            ? prepareWallMs
            : branches.fold<int>(0, (best, b) => b.durationMs > best ? b.durationMs : best),
        costUsd: branches.fold(0.0, (a, b) => a + b.costUsd),
        branches: branches,
      );
    }
    steps.add(hopStep);
  }

  // Anything the header total covers but no traced step explains (tool dispatch, streaming,
  // log I/O between hops) is surfaced explicitly so the trace always adds up.
  if (totals.durationMs > 0 && steps.isNotEmpty) {
    var tracked = 0;
    for (final s in steps) {
      final toolMax = s.title == 'Prepare'
          ? 0
          : s.branches.where((b) => b.isTool).fold<int>(0, (m, b) => b.durationMs > m ? b.durationMs : m);
      tracked += s.durationMs + toolMax;
    }
    final gapMs = totals.durationMs - tracked;
    if (gapMs >= 300) {
      final settleIdx = steps.indexWhere((s) => s.title == 'Settle');
      if (settleIdx >= 0) {
        final settle = steps[settleIdx];
        final updatedBranches = [
          ...settle.branches,
          TraceBranch(
            label: 'Other & latency',
            durationMs: gapMs,
            detail: 'Tool dispatch, streaming or background latency',
          ),
        ];
        steps[settleIdx] = TraceStep(
          index: settle.index,
          title: settle.title,
          durationMs: settle.durationMs,
          costUsd: settle.costUsd,
          tokensIn: settle.tokensIn,
          tokensOut: settle.tokensOut,
          model: settle.model,
          branches: updatedBranches,
          detail: settle.detail,
        );
      }
    }
  }
  if (totals.tokensIn == 0 && totals.tokensOut == 0 && steps.isNotEmpty) {
    totals = TraceTotals(
      tokensIn: steps.fold(0, (a, s) => a + s.tokensIn),
      tokensOut: steps.fold(0, (a, s) => a + s.tokensOut),
      durationMs: steps.fold(0, (a, s) => a + s.durationMs),
      costUsd: steps.fold(0.0, (a, s) => a + s.costUsd),
      model: totals.model.isNotEmpty ? totals.model : traceModelLabel(steps.last.model),
    );
  } else if (totals.durationMs > 0) {
    final settleMs = steps.where((s) => s.title == 'Settle').fold<int>(0, (a, s) => a + s.durationMs);
    if (settleMs > 0) {
      totals = TraceTotals(
        tokensIn: totals.tokensIn,
        tokensOut: totals.tokensOut,
        durationMs: totals.durationMs + settleMs,
        costUsd: totals.costUsd,
        model: totals.model,
      );
    }
  }

  return TraceView(steps: steps, totals: totals);
}

String traceSimLabel(double sim) => sim <= 0 ? '—' : sim.toStringAsFixed(2);

String traceStepUsageLine(TraceStep step, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final model = traceModelLabel(step.model);
  final inStr = step.tokensCached > 0
      ? '${uiFmtGroupedInt(step.tokensIn)}↑ (${uiFmtGroupedInt(step.tokensCached)}⚡)'
      : '${uiFmtGroupedInt(step.tokensIn)}↑';
  final parts = <String>[
    if (step.tokensIn > 0) inStr,
    if (step.tokensOut > 0) '${uiFmtGroupedInt(step.tokensOut)}↓',
    if (model.isNotEmpty) model,
    if (step.costUsd > 0) moneyCostLabel(step.costUsd, currency: currency, fxMicroPerUsd: fxMicroPerUsd),
    if (step.durationMs > 0) uiFmtDurationMs(step.durationMs),
  ];
  return parts.join('  ');
}

String traceTotalsLine(TraceTotals totals, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) => traceStepUsageLine(
      TraceStep(index: 0, title: '', tokensIn: totals.tokensIn, tokensOut: totals.tokensOut, tokensCached: totals.tokensCached, durationMs: totals.durationMs, costUsd: totals.costUsd, model: totals.model),
      currency: currency,
      fxMicroPerUsd: fxMicroPerUsd,
    );

List<MsgTraceToolChip> traceToolChipsFromView(TraceView view) {
  final out = <MsgTraceToolChip>[];
  final seen = <String>{};
  for (final step in view.steps) {
    // Prepare (inst enrich, tool filter) stays in trace sheet only — not under the message.
    if (step.title == 'Prepare') continue;
    for (final b in step.branches) {
      if (!b.isTool || b.label.isEmpty) continue;
      if (!seen.add('${step.index}|${b.label}')) continue;
      out.add(MsgTraceToolChip(label: b.label, ok: b.ok, durationMs: b.durationMs, iconUrl: b.iconUrl, screenshot: b.screenshot));
    }
  }
  return out;
}

class MsgTraceToolChip {
  const MsgTraceToolChip({required this.label, this.ok = true, this.durationMs = 0, this.iconUrl = '', this.screenshot});
  final String label;
  final bool ok;
  final int durationMs;
  final String iconUrl;
  final TraceScreenshot? screenshot;

  bool get hasScreenshotPreview => screenshot?.hasPreview ?? false;
}

class Citation {
  const Citation({required this.url, required this.title, this.snippet = ''});
  final String url;
  final String title;
  final String snippet;
}

String citationHost(String url) {
  final h = Uri.tryParse(url)?.host ?? '';
  return h.startsWith('www.') ? h.substring(4) : h;
}

String citationFaviconUrl(String url) =>
    'https://www.google.com/s2/favicons?domain=${Uri.encodeQueryComponent(citationHost(url))}&sz=32';

List<Citation> citationsFromTraceLogs(List<TraceLogDoc> logs) {
  final out = <Citation>[];
  final seenHosts = <String>{};

  void push(String url, String title, String snippet) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return;
    final host = citationHost(cleanUrl);
    if (host.isEmpty || !seenHosts.add(host)) return;
    final cleanTitle = title.trim().isNotEmpty ? title.trim() : host;
    out.add(Citation(url: cleanUrl, title: cleanTitle, snippet: snippet.trim()));
  }

  for (final log in logs) {
    if (log.topic != 'tool_result' && log.topic != 'tool') continue;
    final tool = (log.meta['tool'] ?? log.meta['branch'] ?? '').toString();
    if (tool != 'web.search' &&
        tool != 'web.visit' &&
        tool != 'web.research' &&
        tool != 'web_search' &&
        tool != 'web_visit' &&
        tool != 'web_research') {
      continue;
    }

    final rawJson = traceToolJsonFromLog(log);

    if (rawJson != null) {
      if (rawJson['results'] is List) {
        for (final item in rawJson['results'] as List) {
          if (item is Map) {
            push(
              (item['url'] ?? '').toString(),
              (item['title'] ?? '').toString(),
              (item['snippet'] ?? item['content'] ?? '').toString(),
            );
          }
        }
      }
      if (rawJson['dossier'] is List) {
        for (final item in rawJson['dossier'] as List) {
          if (item is Map) {
            push(
              (item['url'] ?? '').toString(),
              (item['title'] ?? '').toString(),
              (item['summary'] ?? '').toString(),
            );
          }
        }
      }
      if (rawJson.containsKey('url')) {
        push(
          (rawJson['url'] ?? '').toString(),
          (rawJson['title'] ?? '').toString(),
          (rawJson['description'] ?? rawJson['content'] ?? '').toString(),
        );
      }
    }

    if (out.length >= 6) break;
  }
  return out;
}

