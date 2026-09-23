import 'dart:async';

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
  });

  final bool isUser;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final VoidCallback? onFork;

  @override
  State<UiMsgHoverActions> createState() => _UiMsgHoverActionsState();
}

class _UiMsgHoverActionsState extends State<UiMsgHoverActions> {
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);

  var _copied = false;
  var _thumbsUp = false;
  var _thumbsDown = false;
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
          if (widget.isUser && widget.onEdit != null) ...[
            const SizedBox(width: 2),
            _actionBtn(
              tooltip: 'Edit prompt',
              icon: Icons.edit_outlined,
              onPressed: widget.onEdit,
            ),
          ],
          if (!widget.isUser) ...[
            if (widget.onRetry != null) ...[
              const SizedBox(width: 2),
              _actionBtn(
                tooltip: 'Regenerate response',
                icon: Icons.refresh_rounded,
                onPressed: widget.onRetry,
              ),
            ],
            if (widget.onFork != null) ...[
              const SizedBox(width: 2),
              _actionBtn(
                tooltip: 'Fork chat from here',
                icon: Icons.alt_route_rounded,
                onPressed: widget.onFork,
              ),
            ],
            const SizedBox(width: 2),
            _actionBtn(
              tooltip: 'Good response',
              icon: _thumbsUp ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
              color: _thumbsUp ? _accent : null,
              onPressed: () {
                setState(() {
                  _thumbsUp = !_thumbsUp;
                  if (_thumbsUp) _thumbsDown = false;
                });
              },
            ),
            const SizedBox(width: 2),
            _actionBtn(
              tooltip: 'Bad response',
              icon: _thumbsDown ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
              color: _thumbsDown ? const Color(0xFFEF4444) : null,
              onPressed: () {
                setState(() {
                  _thumbsDown = !_thumbsDown;
                  if (_thumbsDown) _thumbsUp = false;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
