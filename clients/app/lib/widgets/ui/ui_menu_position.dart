import 'package:flutter/material.dart';

RenderBox? uiMenuOverlayBox(BuildContext context) {
  final state = Overlay.maybeOf(context);
  if (state != null) {
    return state.context.findRenderObject() as RenderBox?;
  }
  if (context.widget is Overlay) {
    return context.findRenderObject() as RenderBox?;
  }
  final nav = Navigator.maybeOf(context);
  final navOverlay = nav?.overlay;
  if (navOverlay != null && navOverlay.mounted) {
    return navOverlay.context.findRenderObject() as RenderBox?;
  }
  return null;
}

RelativeRect uiMenuPositionAt(BuildContext context, Offset global) {
  final overlay = uiMenuOverlayBox(context);
  if (overlay == null) {
    return RelativeRect.fromLTRB(global.dx, global.dy, global.dx, global.dy);
  }
  final local = overlay.globalToLocal(global);
  return RelativeRect.fromLTRB(
    local.dx,
    local.dy,
    overlay.size.width - local.dx,
    overlay.size.height - local.dy,
  );
}

RelativeRect uiMenuPositionBelow(BuildContext context, RenderBox anchor, {double gap = 4}) {
  final overlay = uiMenuOverlayBox(context);
  if (overlay == null) {
    final origin = anchor.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      origin.dx,
      origin.dy + anchor.size.height + gap,
      origin.dx + anchor.size.width,
      0,
    );
  }
  final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
  final top = origin.dy + anchor.size.height + gap;
  return RelativeRect.fromLTRB(
    origin.dx,
    top,
    overlay.size.width - origin.dx - anchor.size.width,
    overlay.size.height - top,
  );
}