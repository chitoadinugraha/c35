import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showMsgTraceSheet(BuildContext context, {required String reqId, required ChatConn conn}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      barrierColor: const Color(0xE6000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _MsgTraceSheet(reqId: reqId, conn: conn),
    );

class _MsgTraceSheet extends StatefulWidget {
  const _MsgTraceSheet({required this.reqId, required this.conn});
  final String reqId;
  final ChatConn conn;

  @override
  State<_MsgTraceSheet> createState() => _MsgTraceSheetState();
}

class _MsgTraceSheetState extends State<_MsgTraceSheet> {
  var _loading = true;
  String? _error;
  TraceView _view = const TraceView();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final view = await widget.conn.traceViewFetch(widget.reqId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _view = view;
      });
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
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF71717A), size: 20),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20)),
                ],
              ),
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
                    for (final b in step.branches) _BranchRow(branch: b),
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
