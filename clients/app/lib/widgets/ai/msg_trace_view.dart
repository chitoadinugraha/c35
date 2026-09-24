import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter/material.dart';

import 'package:alienai_c35/widgets/ai/ui_citation_chips.dart';

class MsgTraceView {
  const MsgTraceView({this.chips = const [], this.view = const TraceView(), this.citations = const []});
  final List<MsgTraceToolChip> chips;
  final TraceView view;
  final List<Citation> citations;
  bool get isEmpty => chips.isEmpty && citations.isEmpty;
}

MsgTraceView msgTraceViewForReq(ChatConn conn, {required String reqId}) {
  final logs = conn.traceCacheGet(reqId);
  final view = buildTraceView(logs);
  final citations = citationsFromTraceLogs(logs);
  return MsgTraceView(chips: traceToolChipsFromView(view), view: view, citations: citations);
}

class UiMsgTraceLoader extends StatefulWidget {
  const UiMsgTraceLoader({super.key, required this.conn, required this.reqId, this.compact = true, this.live = false});
  final ChatConn conn;
  final String reqId;
  final bool compact;
  final bool live;

  @override
  State<UiMsgTraceLoader> createState() => _UiMsgTraceLoaderState();
}

class _UiMsgTraceLoaderState extends State<UiMsgTraceLoader> {
  MsgTraceView? _view;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _syncPoll();
  }

  @override
  void didUpdateWidget(covariant UiMsgTraceLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reqId != widget.reqId || oldWidget.live != widget.live) unawaited(_load());
    _syncPoll();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _syncPoll() {
    if (widget.live) {
      _poll ??= Timer.periodic(const Duration(milliseconds: 500), (_) => unawaited(_load()));
      return;
    }
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _load() async {
    final reqId = widget.reqId.trim();
    if (reqId.isEmpty) return;
    var view = msgTraceViewForReq(widget.conn, reqId: reqId);
    if (view.isEmpty) {
      await widget.conn.tracePrefetch(reqId);
      view = msgTraceViewForReq(widget.conn, reqId: reqId);
    }
    if (!mounted) return;
    if (view.isEmpty && !widget.live) {
      setState(() => _view = view);
      return;
    }
    if (view.isEmpty) return;
    setState(() => _view = view);
  }

  @override
  Widget build(BuildContext context) {
    final v = _view;
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    return UiMsgTraceView(view: v, compact: widget.compact, live: widget.live);
  }
}

class UiMsgTraceView extends StatelessWidget {
  const UiMsgTraceView({super.key, required this.view, this.compact = true, this.live = false});
  final MsgTraceView view;
  final bool compact;
  final bool live;

  static const _muted = Color(0xFF71717A);
  static const _text = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: view.chips.map((t) => _ToolChip(chip: t, compact: compact)).toList(),
            ),
          ),
        if (view.citations.isNotEmpty)
          UiCitationChips(citations: view.citations),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.chip, required this.compact});
  final MsgTraceToolChip chip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ms = uiFmtDurationMs(chip.durationMs);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UiMsgTraceView._border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.ok ? Icons.check_circle_outline : Icons.error_outline, size: 14, color: chip.ok ? const Color(0xFF22C55E) : Colors.orange),
          const SizedBox(width: 6),
          Text(chip.label, style: const TextStyle(color: UiMsgTraceView._text, fontSize: 12)),
          if (ms.isNotEmpty) ...[const SizedBox(width: 6), Text(ms, style: const TextStyle(color: UiMsgTraceView._muted, fontSize: 11))],
        ],
      ),
    );
  }
}
