import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Native desktop embedders (Windows/macOS/Linux) hit AXTree corruption when semantics
/// updates race overlays, [InteractiveViewer], [OverlayPortal], and scrolling lists.
/// See https://github.com/flutter/flutter/issues/182444
bool get uiDesktopEmbedder => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Semantics stay disabled on desktop embedders; tooltips use a hover overlay instead.
bool get uiSemanticsEnabled => !uiDesktopEmbedder;

bool get uiTooltipEnabled => true;

const _uiTooltipTextStyle = TextStyle(
  fontFamily: 'Inter',
  color: Color(0xFFF4F4F5),
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.2,
  decoration: TextDecoration.none,
  inherit: false,
);

const _tipGap = 4.0;
const _tipMargin = 8.0;
const _tipMaxWidth = 320.0;
const _tipPadH = 8.0;
const _tipPadV = 5.0;

double _tipMaxContentWidth(BuildContext ctx) {
  final view = MediaQuery.sizeOf(ctx);
  final pad = MediaQuery.viewPaddingOf(ctx);
  return (view.width - pad.left - pad.right - _tipMargin * 2 - _tipPadH * 2).clamp(0.0, _tipMaxWidth - _tipPadH * 2);
}

Size _tipBubbleSize(BuildContext ctx, String message) {
  final tp = TextPainter(
    text: TextSpan(text: message, style: _uiTooltipTextStyle),
    textDirection: Directionality.of(ctx),
    maxLines: null,
  )..layout(maxWidth: _tipMaxContentWidth(ctx));
  return Size(tp.width + _tipPadH * 2, tp.height + _tipPadV * 2);
}

/// Pass to Material [IconButton]/[PopupMenuButton] `tooltip:` — null on desktop so only [uiTooltip] shows.
String? uiTooltipText(String? message) =>
    uiTooltipEnabled && !uiDesktopEmbedder && message != null && message.isNotEmpty ? message : null;

/// [PopupMenuButton.child] anchor when using `tooltip: uiTooltipText(label)` on desktop.
Widget uiPopupMenuChild({required String tooltip, required Widget child}) =>
    tooltip.isEmpty ? child : uiTooltip(message: tooltip, child: child);

Widget uiTooltip({required String message, required Widget child, bool preferBelow = true, bool preferRight = false}) {
  if (!uiTooltipEnabled || message.isEmpty) return child;
  if (uiDesktopEmbedder) return _UiHoverTooltip(message: message, preferBelow: preferBelow, preferRight: preferRight, child: child);
  return Tooltip(message: message, preferBelow: preferBelow, excludeFromSemantics: true, child: child);
}

/// Desktop-safe [IconButton] — uses hover overlay instead of Material [Tooltip].
Widget uiIconButton({
  Key? key,
  required String tooltip,
  required Widget icon,
  VoidCallback? onPressed,
  double? iconSize,
  Color? color,
  EdgeInsetsGeometry? padding,
  VisualDensity? visualDensity,
  BoxConstraints? constraints,
  ButtonStyle? style,
}) {
  final btn = IconButton(
    key: key,
    tooltip: uiDesktopEmbedder ? null : tooltip,
    icon: icon,
    onPressed: onPressed,
    iconSize: iconSize,
    color: color,
    padding: padding,
    visualDensity: visualDensity,
    constraints: constraints,
    style: style,
  );
  if (!uiDesktopEmbedder || tooltip.isEmpty) return btn;
  return uiTooltip(message: tooltip, child: btn);
}

/// Wrap app roots (or heavy canvases) to skip semantics on desktop embedders.
Widget uiSemanticsGuard(Widget child) => uiSemanticsEnabled ? child : ExcludeSemantics(child: child);

enum _UiTipSide { below, above, right, left }

class _UiHoverTooltip extends StatefulWidget {
  const _UiHoverTooltip({required this.message, required this.child, this.preferBelow = true, this.preferRight = false});

  final String message;
  final Widget child;
  final bool preferBelow;
  final bool preferRight;

  @override
  State<_UiHoverTooltip> createState() => _UiHoverTooltipState();
}

class _UiHoverTooltipState extends State<_UiHoverTooltip> {
  OverlayEntry? _overlay;

  Rect? _targetRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final overlay = Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox?;
    final origin = overlay == null || !overlay.attached ? box.localToGlobal(Offset.zero) : box.localToGlobal(Offset.zero, ancestor: overlay);
    return origin & box.size;
  }

  _UiTipSide _side(BuildContext ctx, Rect target) {
    final view = MediaQuery.sizeOf(ctx);
    final pad = MediaQuery.viewPaddingOf(ctx);
    final tip = _tipBubbleSize(ctx, widget.message);
    if (widget.preferRight) {
      final spaceRight = view.width - pad.right - target.right;
      final spaceLeft = target.left - pad.left;
      if (spaceRight >= tip.width + _tipGap) return _UiTipSide.right;
      if (spaceLeft >= tip.width + _tipGap) return _UiTipSide.left;
      return spaceRight >= spaceLeft ? _UiTipSide.right : _UiTipSide.left;
    }
    if (!widget.preferBelow) return _UiTipSide.above;
    final spaceBelow = view.height - pad.bottom - target.bottom;
    final spaceAbove = target.top - pad.top;
    if (spaceBelow >= tip.height + _tipGap) return _UiTipSide.below;
    if (spaceAbove >= tip.height + _tipGap) return _UiTipSide.above;
    return spaceBelow >= spaceAbove ? _UiTipSide.below : _UiTipSide.above;
  }

  void _show() {
    if (_overlay != null || !mounted) return;
    _overlay = OverlayEntry(builder: _overlayBuild);
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _overlay?.markNeedsBuild());
  }

  Widget _overlayBuild(BuildContext ctx) {
    final rect = _targetRect();
    if (rect == null) return const SizedBox.shrink();
    return _UiTooltipBubble(message: widget.message, target: rect, side: _side(ctx, rect));
  }

  void _hide() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
      );
}

class _UiTooltipBubble extends StatefulWidget {
  const _UiTooltipBubble({required this.message, required this.target, required this.side});

  final String message;
  final Rect target;
  final _UiTipSide side;

  @override
  State<_UiTooltipBubble> createState() => _UiTooltipBubbleState();
}

class _UiTooltipBubbleState extends State<_UiTooltipBubble> {
  final _bubbleKey = GlobalKey();
  Size? _size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  @override
  void didUpdateWidget(covariant _UiTooltipBubble old) {
    super.didUpdateWidget(old);
    if (old.message != widget.message || old.target != widget.target || old.side != widget.side) {
      _size = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    }
  }

  void _remeasure() {
    if (!mounted) return;
    final box = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final next = box.size;
    if (_size != next) setState(() => _size = next);
  }

  @override
  Widget build(BuildContext ctx) {
    final view = MediaQuery.sizeOf(ctx);
    final pad = MediaQuery.viewPaddingOf(ctx);
    final maxW = _tipMaxContentWidth(ctx) + _tipPadH * 2;
    final bubble = ExcludeSemantics(
      child: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF3F3F46),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _tipPadH, vertical: _tipPadV),
              child: Text(widget.message, style: _uiTooltipTextStyle, softWrap: true),
            ),
          ),
        ),
      ),
    );

    final size = _size ?? _tipBubbleSize(ctx, widget.message);
    final minLeft = pad.left + _tipMargin;
    final maxLeft = view.width - pad.right - _tipMargin - size.width;
    final minTop = pad.top + _tipMargin;
    final maxTop = view.height - pad.bottom - _tipMargin - size.height;
    double clamp(double v, double a, double b) => b < a ? a : v.clamp(a, b);
    final (left, top) = switch (widget.side) {
      _UiTipSide.below => (
          clamp(widget.target.center.dx - size.width / 2, minLeft, maxLeft),
          clamp(widget.target.bottom + _tipGap, minTop, maxTop),
        ),
      _UiTipSide.above => (
          clamp(widget.target.center.dx - size.width / 2, minLeft, maxLeft),
          clamp(widget.target.top - _tipGap - size.height, minTop, maxTop),
        ),
      _UiTipSide.right => (
          clamp(widget.target.right + _tipGap, minLeft, maxLeft),
          clamp(widget.target.center.dy - size.height / 2, minTop, maxTop),
        ),
      _UiTipSide.left => (
          clamp(widget.target.left - _tipGap - size.width, minLeft, maxLeft),
          clamp(widget.target.center.dy - size.height / 2, minTop, maxTop),
        ),
    };

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [Positioned(left: left, top: top, child: KeyedSubtree(key: _bubbleKey, child: bubble))],
      ),
    );
  }
}
