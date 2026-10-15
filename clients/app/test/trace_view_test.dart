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
  test('buildTraceView shows llm vision prefetch under Prepare with screenshot', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'trace',
        topic: 'llm_vision',
        text: 'Turn-start desktop (SoM) · 1280x720 · SoM',
        metaJson: jsonEncode({
          'step': 1,
          'hop': 0,
          'branch': 'Turn-start desktop (SoM)',
          'topic': 'llm_vision',
          'screenshot': {
            'hash': 'abc123',
            'width': 1280,
            'height': 720,
            'som': true,
          },
        }),
      ),
      _log(topic: 'trace_prepare', branch: 'compose', durationMs: 1000),
    ]);
    expect(view.steps.first.title, 'Prepare');
    final vision = view.steps.first.branches.where((b) => b.label.contains('Turn-start')).toList();
    expect(vision, hasLength(1));
    expect(vision.first.hasScreenshotPreview, isTrue);
    expect(vision.first.screenshot?.som, isTrue);
  });

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
    expect(view.steps.first.title, 'Reply');
    expect(view.steps.first.model, 'alienai');
    expect(view.totals.model, 'alienai');
  });

  test('buildTraceView orders prepare branches with prompt embed first', () {
    final view = buildTraceView([
      _log(topic: 'trace_inst_enrich', branch: 'inst', durationMs: 5),
      TraceLogDoc(
        kind: 'system',
        topic: 'trace_tool_embed',
        text: 'Prompt embed',
        model: 'gemini-embedding-2@768',
        tokensIn: 42,
        durationMs: 4600,
        costUsd: 0.00001,
        metaJson: jsonEncode({'step': 1, 'branch': 'embed', 'embed_cached': false}),
      ),
      _log(topic: 'trace_tool_filter', branch: 'tools', durationMs: 2),
    ]);
    expect(view.steps.first.branches.first.label, 'Prompt embed');
    expect(view.steps.first.branches.first.tokensIn, 42);
    expect(view.steps.first.branches.first.durationMs, 4600);
  });

  test('buildTraceView marks inst enrich ids as inst candidates', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'system',
        topic: 'trace_inst_enrich',
        text: 'Inst enrich',
        durationMs: 5,
        metaJson: jsonEncode({
          'step': 1,
          'branch': 'inst',
          'inst_ids': ['inst.core.assistant', 'inst.site.catalog.stock'],
          'enrich_keys': ['memory.user'],
        }),
      ),
    ]);
    final branch = view.steps.first.branches.firstWhere((b) => b.label == 'Inst enrich');
    expect(branch.toolCandidates.where((c) => c.isInst).map((c) => c.toolId), ['inst.core.assistant', 'inst.site.catalog.stock']);
    expect(branch.toolCandidates.where((c) => !c.isInst).map((c) => c.toolId), ['memory.user']);
  });

  test('buildTraceView parses trace_user_assets prepare branch', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'system',
        topic: 'trace_user_assets',
        text: 'User assets',
        durationMs: 8,
        metaJson: jsonEncode({
          'step': 1,
          'branch': 'user_assets',
          'injected': true,
          'block_chars': 120,
          'sites': [
            {'name': 'Guci Cha', 'asset_iid': 123, 'alien_id': 'guci-cha', 'sim': 0.91, 'injected': true},
            {'name': 'Other Site', 'asset_iid': 124, 'alien_id': 'other', 'sim': 0.42, 'injected': false},
          ],
          'bots': [],
        }),
      ),
    ]);
    final branch = view.steps.first.branches.firstWhere((b) => b.label == 'User assets');
    expect(branch.detail, 'Sites: Guci Cha · 0.91');
    expect(branch.toolCandidates, hasLength(2));
    expect(branch.toolCandidates.first.toolId, 'Guci Cha');
    expect(branch.toolCandidates.first.fed, isTrue);
    expect(branch.toolCandidates.first.sim, 0.91);
    expect(branch.toolCandidates.last.fed, isFalse);
    expect(branch.hasToolFilterDetail, isTrue);
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

  test('traceToolLabelFromLog prefers subagent meta over generic tool label', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true}',
      metaJson: jsonEncode({
        'tool': 'delegate.run',
        'subagent': {'child_req_id': '12345678901234567', 'kind': 'research', 'status': 'done', 'topic_id': 'research'},
      }),
    );
    expect(traceToolLabelFromLog(log), 'Subagent · research · done · …01234567');
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
    expect(chips.first.label, 'Searched web');
    expect(chips.first.ok, isTrue);
  });

  test('traceToolIconUrlFromLog uses visit url favicon', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true,"url":"https://jadwalnonton.com/bioskop/di-malang/"}',
      metaJson: jsonEncode({
        'tool': 'web.visit',
        'args': {'url': 'https://jadwalnonton.com/bioskop/di-malang/'},
      }),
    );
    expect(traceToolIconUrlFromLog(log), contains('google.com/s2/favicons'));
    expect(traceToolIconUrlFromLog(log), contains('jadwalnonton.com'));
  });

  test('traceToolLabelFromLog uses source host for web.visit', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true,"url":"https://jadwalnonton.com/bioskop/di-malang/"}',
      metaJson: jsonEncode({
        'tool': 'web.visit',
        'args': {'url': 'https://jadwalnonton.com/bioskop/di-malang/'},
      }),
    );
    expect(traceToolLabelFromLog(log), 'Visited jadwalnonton.com');
  });

  test('traceToolLabelFromLog labels device.input shortcut from args', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true}',
      metaJson: jsonEncode({
        'tool': 'device.input',
        'args': {'event_type': 'shortcut', 'text': 'ctrl+b'},
      }),
    );
    expect(traceToolLabelFromLog(log), 'Pressed ctrl+b');
  });

  test('traceToolLabelFromLog labels device.input batch actions', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true}',
      metaJson: jsonEncode({
        'tool': 'device.input',
        'args': {
          'actions': [
            {'event_type': 'shortcut', 'text': 'ctrl+g'},
            {'event_type': 'type_text', 'text': 'A2'},
          ],
        },
      }),
    );
    expect(traceToolLabelFromLog(log), '2 actions on device');
  });

  test('toolLabelFromTemplate substitutes source host', () {
    expect(
      toolLabelFromTemplate('Visited {{source}}', {'source': 'jadwalnonton.com'}),
      'Visited jadwalnonton.com',
    );
  });

  test('buildTraceView labels multi-hop tool loop and final reply', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: '',
        durationMs: 1200,
        metaJson: jsonEncode({'step': 2, 'hop': 1, 'prompt_tokens': 355, 'completion_tokens': 32}),
      ),
      TraceLogDoc(
        kind: 'tool',
        topic: 'tool_result',
        text: '{"ok":true,"url":"https://jadwalnonton.com/bioskop/di-malang/"}',
        durationMs: 2500,
        metaJson: jsonEncode({'step': 2, 'hop': 1, 'tool': 'web.visit', 'args': {'url': 'https://jadwalnonton.com/bioskop/di-malang/'}, 'ok': true}),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: '',
        durationMs: 1300,
        metaJson: jsonEncode({'step': 3, 'hop': 2, 'prompt_tokens': 1196, 'completion_tokens': 28}),
      ),
      TraceLogDoc(
        kind: 'tool',
        topic: 'tool_result',
        text: '{"ok":true,"url":"https://jadwalnonton.com/now-playing/"}',
        durationMs: 360,
        metaJson: jsonEncode({'step': 3, 'hop': 2, 'tool': 'web.visit', 'args': {'url': 'https://jadwalnonton.com/now-playing/'}, 'ok': true}),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: 'Saat ini beberapa film sedang tayang di bioskop Malang.',
        durationMs: 2000,
        metaJson: jsonEncode({'step': 4, 'hop': 3, 'prompt_tokens': 2127, 'completion_tokens': 274}),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_turn',
        text: 'done',
        metaJson: jsonEncode({'prompt_tokens': 3678, 'completion_tokens': 334, 'duration_ms': 7972}),
      ),
    ]);
    expect(view.steps, hasLength(3));
    expect(view.steps[0].title, 'Tool run · Visited jadwalnonton.com');
    expect(view.steps[1].title, 'Tool run · Visited jadwalnonton.com');
    expect(view.steps[2].title, 'Reply');
    expect(view.steps[2].branches, isEmpty);
    final chips = traceToolChipsFromView(view);
    expect(chips, hasLength(2));
    expect(chips.every((c) => c.label.contains('jadwalnonton.com')), isTrue);
  });

  test('traceScreenshotFromLog prefers meta.screenshot', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: '{"ok":true}',
      metaJson: jsonEncode({
        'tool': 'device.screenshot',
        'screenshot': {'hash': 'abc123def', 'url': 'https://cdn.example/cas/abc', 'width': 1280, 'height': 782, 'som': true, 'marker': false},
      }),
    );
    final shot = traceScreenshotFromLog(log);
    expect(shot, isNotNull);
    expect(shot!.hash, 'abc123def');
    expect(shot.url, 'https://cdn.example/cas/abc');
    expect(shot.width, 1280);
    expect(shot.som, isTrue);
    expect(shot.imageSrc, 'https://cdn.example/cas/abc');
  });

  test('traceScreenshotFromLog falls back to output_preview image fields', () {
    final log = TraceLogDoc(
      kind: 'tool',
      topic: 'tool_result',
      text: 'device.screenshot ok',
      metaJson: jsonEncode({
        'tool': 'device.screenshot',
        'output_preview': '{"ok":true,"image_hash":"deadbeef","image_url":"","width":800,"height":600}',
      }),
    );
    final shot = traceScreenshotFromLog(log);
    expect(shot?.hash, 'deadbeef');
    expect(shot?.imageSrc, '/fs/deadbeef');
  });

  test('buildTraceView attaches screenshot to device tool branch and chip', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: '',
        durationMs: 500,
        metaJson: jsonEncode({'step': 2, 'hop': 1}),
      ),
      TraceLogDoc(
        kind: 'tool',
        topic: 'tool_result',
        text: '{"ok":true}',
        durationMs: 1200,
        metaJson: jsonEncode({
          'step': 2,
          'tool': 'device.screenshot',
          'screenshot': {'hash': 'snap1', 'url': '', 'width': 100, 'height': 50},
        }),
      ),
      TraceLogDoc(kind: 'llm', topic: 'llm_turn', text: 'done', metaJson: jsonEncode({})),
    ]);
    final branch = view.steps.first.branches.first;
    expect(branch.hasScreenshotPreview, isTrue);
    expect(branch.screenshot?.hash, 'snap1');
    final chips = traceToolChipsFromView(view);
    expect(chips, hasLength(1));
    expect(chips.first.hasScreenshotPreview, isTrue);
  });

  test('groupTraceStepBranches puts turn-start vision first in Desktop vision group', () {
    final step = TraceStep(
      index: 0,
      title: 'Prepare',
      branches: [
        const TraceBranch(label: 'User context', stageKey: 'user_context', durationMs: 121),
        TraceBranch(
          label: 'Turn-start desktop (SoM)',
          stageKey: 'llm_vision',
          durationMs: 0,
          screenshot: const TraceScreenshot(hash: 'abc', width: 1280, height: 720, som: true),
        ),
      ],
    );
    final groups = groupTraceStepBranches(step);
    expect(groups.first.title, 'Desktop vision');
    expect(groups.first.branches.first.label, contains('Turn-start'));
    expect(groups.first.branches.first.hasScreenshotPreview, isTrue);
  });

  test('buildTraceView attaches model_reasoning to LLM hop step', () {
    final view = buildTraceView([
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_call',
        text: 'reply',
        model: 'alienai',
        durationMs: 800,
        metaJson: jsonEncode({
          'step': 2,
          'hop': 1,
          'prompt_tokens': 100,
          'completion_tokens': 20,
          'model_reasoning': 'Plan: click bold button.',
        }),
      ),
      TraceLogDoc(
        kind: 'llm',
        topic: 'llm_turn',
        text: 'done',
        metaJson: jsonEncode({'prompt_tokens': 100, 'completion_tokens': 20, 'duration_ms': 1200}),
      ),
    ]);
    expect(view.steps.single.modelReasoning, 'Plan: click bold button.');
  });

  test('traceStepUsageLine and traceTotalsLine display cached tokens with ⚡', () {
    const stepWithCache = TraceStep(
      index: 1,
      title: 'Hop 1',
      tokensIn: 8192,
      tokensOut: 256,
      tokensCached: 4096,
      model: 'gemini-3.5-flash-lite',
      durationMs: 450,
      costUsd: 0.0012,
    );
    final line = traceStepUsageLine(stepWithCache);
    expect(line, contains('8,192↑ (4,096⚡)'));
    expect(line, contains('256↓'));

    const totalsWithCache = TraceTotals(
      tokensIn: 10000,
      tokensOut: 500,
      tokensCached: 8000,
      model: 'gemini-3.5-flash-lite',
      durationMs: 1200,
      costUsd: 0.002,
    );
    final totalsLine = traceTotalsLine(totalsWithCache);
    expect(totalsLine, contains('10,000↑ (8,000⚡)'));
    expect(totalsLine, contains('500↓'));
  });
}
