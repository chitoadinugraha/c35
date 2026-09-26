import 'package:flutter/material.dart';

RenderBox? uiMenuOverlayBox(BuildContext context) =>
    Overlay.of(context).context.findRenderObject() as RenderBox?;

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