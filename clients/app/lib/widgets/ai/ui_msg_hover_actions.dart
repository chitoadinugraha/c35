import 'dart:async';

import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_bad_ai_report.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiMsgHoverActions extends StatefulWidget {
  const UiMsgHoverActions({
    super.key,
    required this.isUser,
    required this.onCopy,
    this.onEdit,
    this.onRetry,
    this.onFork,
    this.onGood,
    this.onReportBad,
  });

  final bool isUser;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final VoidCallback? onFork;
  final VoidCallback? onGood;
  final void Function(String reason)? onReportBad;

  @override
  State<UiMsgHoverActions> createState() => _UiMsgHoverActionsState();
}

class _UiMsgHoverActionsState extends State<UiMsgHoverActions> {
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);

  var _copied = false;
  var _good = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copy() {
    widget.onCopy();
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Widget _actionBtn({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    double size = 15,
  }) {
    if (onPressed == null) return const SizedBox.shrink();
    return uiIconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: size, color: color ?? _muted),
      onPressed: onPressed,
    );
  }

  bool get _hasMoreMenu =>
      (!widget.isUser && (widget.onRetry != null || widget.onFork != null || widget.onGood != null || widget.onReportBad != null)) ||
      (widget.isUser && widget.onEdit != null);

  Future<void> _openMoreMenu() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final global = box.localToGlobal(Offset(box.size.width - 8, box.size.height));
    final items = <ChatMessageMenuItem>[
      if (widget.isUser && widget.onEdit != null)
        ChatMessageMenuAction(label: 'Edit prompt', icon: Icons.edit_outlined, onPressed: widget.onEdit!),
      if (!widget.isUser && widget.onRetry != null)
        ChatMessageMenuAction(label: 'Regenerate response', icon: Icons.refresh_rounded, onPressed: widget.onRetry!),
      if (!widget.isUser && widget.onFork != null)
        ChatMessageMenuAction(label: 'Fork chat from here', icon: Icons.alt_route_rounded, onPressed: widget.onFork!),
      if (!widget.isUser && widget.onGood != null) ...[
        if (widget.onRetry != null || widget.onFork != null) const ChatMessageMenuDivider(),
        ChatMessageMenuAction(
          label: 'Good response',
          icon: _good ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
          onPressed: () {
            setState(() => _good = true);
            widget.onGood?.call();
          },
        ),
      ],
      if (!widget.isUser && widget.onReportBad != null) ...[
        if (widget.onRetry != null || widget.onFork != null || widget.onGood != null) const ChatMessageMenuDivider(),
        ChatMessageMenuAction(
          label: 'Report Bad AI',
          icon: Icons.flag_outlined,
          onPressed: () => unawaited(_reportBadAi(global)),
        ),
      ],
    ];
    if (items.isEmpty) return;
    await showChatListMenu(context: context, global: global, items: items);
  }

  Future<void> _reportBadAi(Offset anchor) async {
    final reason = await showMsgBadAiReportReasonMenu(context: context, global: anchor);
    if (!mounted || reason == null || reason.isEmpty) return;
    widget.onReportBad?.call(reason);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for the report'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionBtn(
            tooltip: _copied ? 'Copied!' : 'Copy',
            icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
            color: _copied ? _accent : null,
            onPressed: _copy,
          ),
          if (_hasMoreMenu) ...[
            const SizedBox(width: 2),
            _actionBtn(
              tooltip: 'More actions',
              icon: Icons.more_horiz_rounded,
              onPressed: _openMoreMenu,
            ),
          ],
        ],
      ),
    );
  }
}
