import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_id.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

Future<void> showMsgTraceSheet(BuildContext context, {required String reqId, required ChatConn conn, int msgId = 0}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      barrierColor: const Color(0xE6000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _MsgTraceSheet(reqId: reqId, conn: conn, msgId: msgId),
    );

class _MsgTraceSheet extends StatefulWidget {
  const _MsgTraceSheet({required this.reqId, required this.conn, this.msgId = 0});
  final String reqId;
  final ChatConn conn;
  final int msgId;

  @override
  State<_MsgTraceSheet> createState() => _MsgTraceSheetState();
}

class _MsgTraceSheetState extends State<_MsgTraceSheet> {
  var _loading = true;
  String? _error;
  TraceView _view = const TraceView();
  Timer? _poll;
  var _pollTicks = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool _traceLooksComplete(TraceView view) =>
      view.steps.any((s) => s.index > 0) || view.totals.durationMs > 0;

  void _syncPoll() {
    if (_traceLooksComplete(_view)) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (++_pollTicks > 25) {
        _poll?.cancel();
        _poll = null;
        return;
      }
      unawaited(_load(silent: true));
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final view = await widget.conn.traceViewFetch(widget.reqId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _view = view;
      });
      _syncPoll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.82;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Trace', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600))),
                  uiIconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF71717A), size: 20),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20)),
                ],
              ),
            ),
            if (widget.msgId > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: UiMsgId(id: widget.msgId),
              ),
            if (_view.totals.tokensIn > 0 || _view.totals.tokensOut > 0 || _view.totals.durationMs > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(traceTotalsLine(_view.totals), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
              ),
            const Divider(height: 1, color: Color(0xFF27272A)),
            Expanded(
              child: _loading
                  ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF71717A))))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFF71717A))))
                      : _view.isEmpty
                          ? const Center(child: Text('No trace logs yet', style: TextStyle(color: Color(0xFF71717A))))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _view.steps.length,
                              itemBuilder: (_, i) => _StepTile(step: _view.steps[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});
  final TraceStep step;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${step.index}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(width: 8),
                Expanded(child: Text(step.title, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 13, fontWeight: FontWeight.w600))),
                Text(traceStepUsageLine(step), style: const TextStyle(color: Color(0xFF71717A), fontSize: 11)),
              ],
            ),
            if (step.branches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final b in step.branches)
                      b.hasToolFilterDetail ? _ToolFilterBranchRow(branch: b) : _BranchRow(branch: b),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch});
  final TraceBranch branch;

  @override
  Widget build(BuildContext context) {
    final ms = uiFmtDurationMs(branch.durationMs);
    final price = branch.costUsd > 0 ? moneyCostLabel(branch.costUsd) : '';
    final usage = [if (branch.tokensIn > 0) '${uiFmtGroupedInt(branch.tokensIn)}↑', if (branch.tokensOut > 0) '${uiFmtGroupedInt(branch.tokensOut)}↓', if (ms.isNotEmpty) ms, if (price.isNotEmpty) price].join('  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('|-', style: TextStyle(color: branch.ok ? const Color(0xFF52525B) : Colors.orange, fontSize: 12, fontFamily: 'Consolas')),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${branch.label}${usage.isNotEmpty ? '  $usage' : ''}',
              style: TextStyle(color: branch.ok ? const Color(0xFFA1A1AA) : Colors.orange, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolFilterBranchRow extends StatefulWidget {
  const _ToolFilterBranchRow({required this.branch});
  final TraceBranch branch;

  @override
  State<_ToolFilterBranchRow> createState() => _ToolFilterBranchRowState();
}

class _ToolFilterBranchRowState extends State<_ToolFilterBranchRow> {
  static const _droppedMax = 5;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    final ms = uiFmtDurationMs(branch.durationMs);
    final fed = branch.toolCandidates.where((c) => c.fed).length;
    final scored = branch.toolCandidates.where((c) => c.sim > 0).length;
    final eligible = branch.toolCandidates.length;
    final fedTools = branch.toolCandidates.where((c) => c.fed).toList();
    final otherEligible = branch.toolCandidates.where((c) => !c.fed && c.sim <= 0).toList();
    final summary = [
      if (fed > 0) '$fed fed',
      if (scored > 0) '$scored scored',
      if (eligible > scored) '${eligible - scored} other',
      if (branch.ragSkipped && branch.ragSkipReason.isNotEmpty) branch.ragSkipReason,
      if (ms.isNotEmpty) ms,
    ].join(' · ');
    final dropped = (branch.droppedGap.isNotEmpty
            ? branch.droppedGap
            : branch.toolCandidates.where((c) => !c.fed && c.sim > 0))
        .take(_droppedMax)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('|-', style: const TextStyle(color: Color(0xFF52525B), fontSize: 12, fontFamily: 'Consolas')),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 14, color: const Color(0xFF71717A)),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${branch.label}${summary.isNotEmpty ? ' · $summary' : ''}',
                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            for (final c in fedTools) _ToolFilterCandidateRow(candidate: c),
            if (dropped.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 28, top: 6, bottom: 2),
                child: Text('Dropped (similarity gap)', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              for (final c in dropped) _ToolFilterCandidateRow(candidate: c, dropped: true),
            ],
            if (otherEligible.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(left: 28, top: dropped.isNotEmpty ? 6 : 2, bottom: 2),
                child: Text(
                  'Other eligible (${otherEligible.length})',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              for (final c in otherEligible) _ToolFilterCandidateRow(candidate: c),
            ],
          ],
        ],
      ),
    );
  }
}

class _ToolFilterCandidateRow extends StatelessWidget {
  const _ToolFilterCandidateRow({required this.candidate, this.dropped = false});
  final TraceToolFilterCandidate candidate;
  final bool dropped;

  @override
  Widget build(BuildContext context) {
    final label = candidate.toolId;
    final sim = traceSimLabel(candidate.sim);
    final fed = !dropped && candidate.fed;
    final color = dropped
        ? const Color(0xFF71717A)
        : fed
            ? const Color(0xFF22C55E)
            : const Color(0xFFA1A1AA);
    final simColor = dropped
        ? const Color(0xFF52525B)
        : fed
            ? const Color(0xFF22C55E)
            : const Color(0xFF71717A);
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 11, height: 1.3))),
          Text(sim, style: TextStyle(color: simColor, fontSize: 11, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
