import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_agent_tool_accordion.dart';
import 'package:flutter/material.dart';

class MsgTraceView {
  const MsgTraceView({this.chips = const [], this.view = const TraceView()});
  final List<MsgTraceToolChip> chips;
  final TraceView view;
  bool get isEmpty => chips.isEmpty;
}

MsgTraceView msgTraceViewForReq(ChatConn conn, {required String reqId}) {
  final view = buildTraceView(conn.traceCacheGet(reqId));
  return MsgTraceView(chips: traceToolChipsFromView(view), view: view);
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

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty && !live) return const SizedBox.shrink();
    return UiAgentToolAccordion(chips: view.chips, live: live);
  }
}
