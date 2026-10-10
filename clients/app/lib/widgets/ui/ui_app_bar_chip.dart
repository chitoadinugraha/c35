import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const uiAppBarChipHoverBg = Color(0xFF27272A);

/// App bar control with hover fill; clears hover when the desktop window loses focus.
class UiAppBarChip extends StatefulWidget {
  const UiAppBarChip({
    super.key,
    required this.onTap,
    required this.child,
    this.tooltip,
    this.padding = const EdgeInsets.all(6),
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? tooltip;
  final EdgeInsets padding;

  @override
  State<UiAppBarChip> createState() => _UiAppBarChipState();
}

class _UiAppBarChipState extends State<UiAppBarChip> with WindowListener {
  var _hover = false;

  @override
  void initState() {
    super.initState();
    if (uiDesktopWindow) windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (uiDesktopWindow) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() {
    if (_hover) setState(() => _hover = false);
  }

  Widget _body() => MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: _hover && widget.onTap != null ? uiAppBarChipHoverBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashColor: const Color(0x1AFFFFFF),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final body = _body();
    final tip = widget.tooltip?.trim() ?? '';
    if (tip.isEmpty) return body;
    return Tooltip(message: tip, child: body);
  }
}
