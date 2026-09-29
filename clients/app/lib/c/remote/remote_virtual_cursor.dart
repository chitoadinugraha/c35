import 'package:flutter/material.dart';

/// On-stream pointer overlay for trackpad mode (hotspot at top-left of widget).
class UiRemoteVirtualCursor extends StatelessWidget {
  const UiRemoteVirtualCursor({super.key, required this.shape});

  final String shape;

  static const _shadow = [
    Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: switch (shape) {
          'text' => const _IBeamCursor(),
          'click' => Icon(
              Icons.back_hand_outlined,
              size: 22,
              color: Colors.white,
              shadows: _shadow,
            ),
          'wait' || 'progress' => Icon(
              Icons.hourglass_top_outlined,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'help' => Icon(
              Icons.help_outline,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'forbidden' => Icon(
              Icons.not_interested,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'move' => Icon(
              Icons.open_with,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'precise' => Icon(
              Icons.center_focus_strong_outlined,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'resize_ns' => Icon(
              Icons.height,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'resize_ew' => Icon(
              Icons.width_normal_outlined,
              size: 20,
              color: Colors.white,
              shadows: _shadow,
            ),
          'resize_nwse' => Transform.rotate(
              angle: 0.785398,
              child: Icon(
                Icons.height,
                size: 20,
                color: Colors.white,
                shadows: _shadow,
              ),
            ),
          'resize_nesw' => Transform.rotate(
              angle: -0.785398,
              child: Icon(
                Icons.height,
                size: 20,
                color: Colors.white,
                shadows: _shadow,
              ),
            ),
          _ => const CustomPaint(
              size: Size(20, 24),
              painter: _ArrowCursorPainter(),
            ),
        },
      );
}

class _IBeamCursor extends StatelessWidget {
  const _IBeamCursor();

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(14, 22),
        painter: _IBeamCursorPainter(),
      );
}

class _IBeamCursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final stroke = Paint()
      ..color = const Color(0xFF18181B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bar = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, size.height / 2), width: 2.5, height: size.height),
      const Radius.circular(1),
    );
    canvas.drawRRect(bar, fill);
    canvas.drawRRect(bar, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowCursorPainter extends CustomPainter {
  const _ArrowCursorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 18.5)
      ..lineTo(4.8, 14.5)
      ..lineTo(8.5, 22.5)
      ..lineTo(11.8, 21.0)
      ..lineTo(8.2, 13.2)
      ..lineTo(14.0, 13.2)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.6), 3.0, true);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF18181B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}