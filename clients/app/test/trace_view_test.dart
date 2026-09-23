import 'dart:convert';

import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:flutter_test/flutter_test.dart';

TraceLogDoc _log({required String topic, String kind = 'system', int step = 1, int durationMs = 0, String branch = ''}) => TraceLogDoc(
      kind: kind,
      topic: topic,
      text: topic,
      durationMs: durationMs,
      metaJson: jsonEncode({'step': step, if (branch.isNotEmpty) 'branch': branch}),
    );

void main() {
  test('traceToolChipsFromView skips prepare traces', () {
    final view = buildTraceView([
      _log(topic: 'trace_tool_filter', branch: 'tools', durationMs: 12),
      _log(topic: 'trace_prepare', branch: 'compose', durationMs: 1000),
      _log(topic: 'trace_memory', branch: 'memory', durationMs: 137),
    ]);
    expect(view.steps, hasLength(1));
    expect(view.steps.first.index, 0);
    expect(view.steps.first.title, 'Prepare');
    expect(traceToolChipsFromView(view), isEmpty);
  });

  test('buildTraceView numbers LLM hops from 1', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: 'reply',
        model: 'alienai',
        durationMs: 800,
        metaJson: jsonEncode({'step': 2, 'hop': 1, 'prompt_tokens': 100, 'completion_tokens': 20, 'cost_retail_usd': 0.0003}),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_turn',
        text: 'done',
        model: 'alienai',
        metaJson: jsonEncode({'prompt_tokens': 100, 'completion_tokens': 20, 'duration_ms': 1200, 'cost_retail_usd': 0.0003}),
      ),
    ]);
    expect(view.steps, hasLength(1));
    expect(view.steps.first.index, 1);
    expect(view.steps.first.title, 'LLM hop 1');
    expect(view.steps.first.model, 'alienai');
    expect(view.totals.model, 'alienai');
  });

  test('buildTraceView parses tool filter candidates', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'system',
        topic: 'trace_tool_filter',
        text: 'Tool filter',
        durationMs: 12,
        metaJson: jsonEncode({
          'step': 1,
          'branch': 'tools',
          'candidates': [
            {'tool_id': 'web.search', 'sim': 0.82, 'fed': true},
            {'tool_id': 'img.generate', 'sim': 0.41, 'fed': false},
          ],
          'dropped_gap': [
            {'tool_id': 'img.generate', 'sim': 0.41, 'fed': false},
          ],
        }),
      ),
    ]);
    final branch = view.steps.first.branches.first;
    expect(branch.label, 'Tool filter');
    expect(branch.toolCandidates, hasLength(2));
    expect(branch.toolCandidates.first.fed, isTrue);
    expect(branch.droppedGap, hasLength(1));
  });

  test('traceToolChipsFromView includes executed tools only', () {
    final view = buildTraceView([
      _log(topic: 'trace_tool_filter', branch: 'tools', durationMs: 12),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: 'reply',
        durationMs: 800,
        metaJson: jsonEncode({'step': 2, 'hop': 1, 'prompt_tokens': 100, 'completion_tokens': 20}),
      ),
      TraceLogDoc(
        kind: 'tool',
        topic: 'tool_result',
        text: '{"ok":true}',
        durationMs: 200,
        metaJson: jsonEncode({'step': 2, 'hop': 1, 'branch': 'web.search', 'tool': 'web.search', 'ok': true}),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_turn',
        text: 'done',
        metaJson: jsonEncode({'prompt_tokens': 100, 'completion_tokens': 20, 'duration_ms': 1200}),
      ),
    ]);
    final chips = traceToolChipsFromView(view);
    expect(chips, hasLength(1));
    expect(chips.first.label, 'Searching web');
    expect(chips.first.ok, isTrue);
  });
}
