import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

MsgRow promptRunUsageMsg(PromptRunPush push) => MsgRow(
      id: 0,
      chatId: 0,
      role: 'assistant',
      content: '',
      tokensIn: push.tokensIn,
      tokensOut: push.tokensOut,
      durationMs: push.durationMs,
      costUsd: push.costUsd,
      model: push.kind.isNotEmpty ? push.kind : push.topicId,
    );

class UiSubagentRunCard extends StatefulWidget {
  const UiSubagentRunCard({
    super.key,
    required this.conn,
    required this.push,
    required this.chatId,
    this.onStop,
  });

  final ChatConn conn;
  final PromptRunPush push;
  final int chatId;
  final VoidCallback? onStop;

  @override
  State<UiSubagentRunCard> createState() => _UiSubagentRunCardState();
}

class _UiSubagentRunCardState extends State<UiSubagentRunCard> {
  static const _bg = Color(0xFF141418);
  static const _border = Color(0xFF27272A);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);
  static const _danger = Color(0xFFDC2626);

  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = promptRunStatusLive(widget.push.status);
  }

  @override
  void didUpdateWidget(covariant UiSubagentRunCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (promptRunStatusLive(oldWidget.push.status) && !promptRunStatusLive(widget.push.status)) {
      _expanded = false;
    } else if (!promptRunStatusLive(oldWidget.push.status) && promptRunStatusLive(widget.push.status)) {
      _expanded = true;
    }
  }

  String get _title {
    final label = widget.push.label.trim();
    if (label.isNotEmpty) return label;
    final kind = widget.push.kind.trim();
    if (kind.isNotEmpty) return kind;
    final topic = widget.push.topicId.trim();
    if (topic.isNotEmpty) return topic;
    return 'Subagent';
  }

  Widget _statusBadge() {
    final status = widget.push.status;
    final label = promptRunStatusLabel(status);
    final live = promptRunStatusLive(status);
    final failed = status.trim().toLowerCase() == 'failed';
    final icon = live
        ? SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: failed ? _danger : _accent),
          )
        : Icon(
            failed
                ? Icons.error_outline_rounded
                : status.trim().toLowerCase() == 'cancelled'
                    ? Icons.cancel_outlined
                    : Icons.check_circle_outline_rounded,
            size: 14,
            color: failed ? _danger : _muted,
          );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
    final reason = widget.push.failReason.trim();
    if (failed && reason.isNotEmpty) return uiTooltip(message: reason, child: row);
    return row;
  }

  @override
  Widget build(BuildContext context) {
    final live = promptRunStatusLive(widget.push.status);
    final reqId = widget.push.reqId.trim();
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: reqId.isEmpty ? null : () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        _statusBadge(),
                      ],
                    ),
                  ),
                  if (live && widget.onStop != null)
                    uiIconButton(
                      tooltip: 'Stop subagent',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: widget.onStop,
                      icon: const Icon(Icons.stop_rounded, size: 18, color: _danger),
                    ),
                  if (reqId.isNotEmpty)
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 18,
                      color: _muted,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && reqId.isNotEmpty) ...[
            ListenableBuilder(
              listenable: PromptRunStore.instance,
              builder: (context, _) {
                final thought = PromptRunStore.instance.liveThought(reqId);
                final text = PromptRunStore.instance.liveText(reqId);
                if (thought.isEmpty && text.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (thought.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Text(
                            thought,
                            style: const TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ),
                      if (text.isNotEmpty)
                        Text(
                          text,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: UiMsgTraceLoader(conn: widget.conn, reqId: reqId, live: live),
            ),
          ],
          ListenableBuilder(
            listenable: PromptUsagePrefs.instance,
            builder: (context, _) => UiMsgUsage(
              msg: promptRunUsageMsg(widget.push),
              streaming: live,
              billingCurrency: AppStore.instance.wallet.billingCurrency,
              fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
            ),
          ),
        ],
      ),
    );
  }
}
