import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';

class TraceToolFilterCandidate {
  const TraceToolFilterCandidate({required this.toolId, this.sim = 0, this.fed = false});
  final String toolId;
  final double sim;
  final bool fed;
}

class TraceBranch {
  const TraceBranch({
    required this.label,
    this.durationMs = 0,
    this.costUsd = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.ok = true,
    this.detail = '',
    this.toolCandidates = const [],
    this.droppedGap = const [],
    this.ragSkipped = false,
    this.ragSkipReason = '',
  });
  final String label;
  final int durationMs;
  final double costUsd;
  final int tokensIn;
  final int tokensOut;
  final bool ok;
  final String detail;
  final List<TraceToolFilterCandidate> toolCandidates;
  final List<TraceToolFilterCandidate> droppedGap;
  final bool ragSkipped;
  final String ragSkipReason;

  bool get hasToolFilterDetail => toolCandidates.isNotEmpty || droppedGap.isNotEmpty;
}

class TraceStep {
  const TraceStep({
    required this.index,
    required this.title,
    this.durationMs = 0,
    this.costUsd = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.model = '',
    this.branches = const [],
    this.detail = '',
  });

  final int index;
  final String title;
  final int durationMs;
  final double costUsd;
  final int tokensIn;
  final int tokensOut;
  final String model;
  final List<TraceBranch> branches;
  final String detail;
}

class TraceTotals {
  const TraceTotals({this.tokensIn = 0, this.tokensOut = 0, this.durationMs = 0, this.costUsd = 0, this.model = ''});
  final int tokensIn;
  final int tokensOut;
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

String traceModelLabel(String model) {
  final m = model.trim().toLowerCase();
  if (m.isEmpty || m == 'auto' || m == 'alien' || m == 'alienai' || m == 'cloud') return 'alienai';
  return model.trim();
}

String traceToolLabel(String toolId) {
  final id = toolId.replaceAll('_', '.');
  return switch (id) {
    'web.search' => catalogT('tool.web.search.calling').replaceAll('…', ''),
    'web.visit' => catalogT('tool.web.visit.calling').replaceAll('…', ''),
    'web.research' => catalogT('tool.web.research.calling').replaceAll('…', ''),
    'img.generate' => catalogT('tool.img.generate.calling').replaceAll('…', ''),
    _ => id.isEmpty ? 'Tool' : id,
  };
}

TraceBranch _branchFromLog(TraceLogDoc log) {
  final meta = log.meta;
  final tool = _asStr(meta['tool']);
  final branch = _asStr(meta['branch']);
  final label = tool.isNotEmpty ? traceToolLabel(tool) : branch.isNotEmpty ? branch : log.text.split('\n').first;
  return TraceBranch(
    label: label,
    durationMs: log.durationMs > 0 ? log.durationMs : _asInt(meta['duration_ms']),
    costUsd: log.costUsd > 0 ? log.costUsd : _asDouble(meta['cost_retail_usd']),
    tokensIn: log.tokensIn,
    tokensOut: log.tokensOut,
    ok: meta['ok'] as bool? ?? log.topic != 'tool_error',
    detail: log.text.length > 120 ? '${log.text.substring(0, 120)}…' : log.text,
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
      final branchRows = rows.where((r) => r.topic == 'tool_result' || r.topic == 'tool_error' || (r.kind == 'tool'));
      for (final b in branchRows) {
        branches.add(_branchFromLog(b));
      }
      hopStep = TraceStep(
        index: hop,
        title: 'LLM hop $hop',
        durationMs: main.durationMs > 0 ? main.durationMs : _asInt(meta['duration_ms']),
        costUsd: main.costUsd > 0 ? main.costUsd : _asDouble(meta['cost_retail_usd']),
        tokensIn: main.tokensIn > 0 ? main.tokensIn : _asInt(meta['prompt_tokens']),
        tokensOut: main.tokensOut > 0 ? main.tokensOut : _asInt(meta['completion_tokens']),
        model: traceModelLabel(main.model),
        branches: branches,
      );
    } else {
      for (final r in rows) {
        final branch = _asStr(r.meta['branch']);
        final label = switch (r.topic) {
          'trace_memory' => 'Memory',
          'trace_tool_filter' => 'Tool filter',
          'trace_prepare' => 'Compose',
          _ => branch.isNotEmpty ? branch : r.topic,
        };
        branches.add(TraceBranch(
          label: label,
          durationMs: r.durationMs,
          costUsd: r.costUsd,
          detail: r.text.split('\n').first,
          toolCandidates: r.topic == 'trace_tool_filter' ? _toolCandidatesFromMeta(r.meta['candidates']) : const [],
          droppedGap: r.topic == 'trace_tool_filter' ? _toolCandidatesFromMeta(r.meta['dropped_gap']) : const [],
          ragSkipped: r.topic == 'trace_tool_filter' && r.meta['rag_skipped'] == true,
          ragSkipReason: r.topic == 'trace_tool_filter' ? _asStr(r.meta['rag_skip_reason']) : '',
        ));
      }
      hopStep = TraceStep(
        index: 0,
        title: 'Prepare',
        durationMs: branches.fold(0, (a, b) => a + b.durationMs),
        costUsd: branches.fold(0.0, (a, b) => a + b.costUsd),
        branches: branches,
      );
    }
    steps.add(hopStep);
  }

  if (totals.tokensIn == 0 && totals.tokensOut == 0 && steps.isNotEmpty) {
    totals = TraceTotals(
      tokensIn: steps.fold(0, (a, s) => a + s.tokensIn),
      tokensOut: steps.fold(0, (a, s) => a + s.tokensOut),
      durationMs: steps.fold(0, (a, s) => a + s.durationMs),
      costUsd: steps.fold(0.0, (a, s) => a + s.costUsd),
      model: totals.model.isNotEmpty ? totals.model : traceModelLabel(steps.last.model),
    );
  }

  return TraceView(steps: steps, totals: totals);
}

String traceSimLabel(double sim) => sim <= 0 ? '—' : sim.toStringAsFixed(2);

String traceStepUsageLine(TraceStep step, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final model = traceModelLabel(step.model);
  final parts = <String>[
    if (step.tokensIn > 0) '${uiFmtGroupedInt(step.tokensIn)}↑',
    if (step.tokensOut > 0) '${uiFmtGroupedInt(step.tokensOut)}↓',
    if (step.durationMs > 0) uiFmtDurationMs(step.durationMs),
    if (step.costUsd > 0) moneyCostLabel(step.costUsd, currency: currency, fxMicroPerUsd: fxMicroPerUsd),
    if (model.isNotEmpty) model,
  ];
  return parts.join('  ');
}

String traceTotalsLine(TraceTotals totals, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) => traceStepUsageLine(
      TraceStep(index: 0, title: '', tokensIn: totals.tokensIn, tokensOut: totals.tokensOut, durationMs: totals.durationMs, costUsd: totals.costUsd, model: totals.model),
      currency: currency,
      fxMicroPerUsd: fxMicroPerUsd,
    );

List<MsgTraceToolChip> traceToolChipsFromView(TraceView view) {
  final out = <MsgTraceToolChip>[];
  for (final step in view.steps) {
    // Prepare traces (tool filter, compose, memory) are for the trace sheet only.
    if (step.title == 'Prepare') continue;
    for (final b in step.branches) {
      if (b.label.isEmpty) continue;
      out.add(MsgTraceToolChip(label: b.label, ok: b.ok, durationMs: b.durationMs));
    }
  }
  return out;
}

class MsgTraceToolChip {
  const MsgTraceToolChip({required this.label, this.ok = true, this.durationMs = 0});
  final String label;
  final bool ok;
  final int durationMs;
}
