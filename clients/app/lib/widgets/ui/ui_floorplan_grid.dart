import 'package:alienai_c35/widgets/ui/floorplan_config.dart';
import 'package:flutter/material.dart';

class UiFloorplanGridLayer extends StatelessWidget {
  const UiFloorplanGridLayer({
    super.key,
    required this.transformation,
    required this.viewerSize,
    required this.colorScheme,
  });

  final TransformationController transformation;
  final Size viewerSize;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          painter: _UiFloorplanGridTransformPainter(
            transformation: transformation,
            viewerSize: viewerSize,
            colorScheme: colorScheme,
          ),
          child: const SizedBox.expand(),
        ),
      );
}

class _UiFloorplanGridTransformPainter extends CustomPainter {
  _UiFloorplanGridTransformPainter({
    required this.transformation,
    required this.viewerSize,
    required this.colorScheme,
  }) : super(repaint: transformation);

  final TransformationController transformation;
  final Size viewerSize;
  final ColorScheme colorScheme;

  Rect _worldViewport() {
    final inverse = Matrix4.inverted(transformation.value);
    final a = MatrixUtils.transformPoint(inverse, Offset.zero);
    final b = MatrixUtils.transformPoint(inverse, Offset(viewerSize.width, viewerSize.height));
    return Rect.fromPoints(
      Offset(a.dx < b.dx ? a.dx : b.dx, a.dy < b.dy ? a.dy : b.dy),
      Offset(a.dx > b.dx ? a.dx : b.dx, a.dy > b.dy ? a.dy : b.dy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = _worldViewport();
    final overscan = Rect.fromLTWH(
      viewport.left - FloorplanConfig.overscan,
      viewport.top - FloorplanConfig.overscan,
      viewport.width + FloorplanConfig.overscan * 2,
      viewport.height + FloorplanConfig.overscan * 2,
    );
    canvas.save();
    canvas.translate(overscan.left, overscan.top);
    _floorplanGridDraw(canvas, overscan.size, viewport.topLeft, colorScheme);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UiFloorplanGridTransformPainter oldDelegate) =>
      viewerSize != oldDelegate.viewerSize || colorScheme != oldDelegate.colorScheme;
}

void _floorplanGridDraw(Canvas canvas, Size size, Offset viewportTopLeft, ColorScheme colorScheme) {
  _floorplanGridDrawLines(
    canvas,
    size,
    FloorplanConfig.majorGrid,
    Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1.25,
    _floorplanGridPhase(viewportTopLeft, FloorplanConfig.majorGrid),
  );
  _floorplanGridDrawLines(
    canvas,
    size,
    FloorplanConfig.minorGrid,
    Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.22)
      ..strokeWidth = 0.85,
    _floorplanGridPhase(viewportTopLeft, FloorplanConfig.minorGrid),
  );
}

Offset _floorplanGridPhase(Offset topLeft, double space) {
  final x = topLeft.dx % space;
  final y = topLeft.dy % space;
  return Offset(x < 0 ? x + space : x, y < 0 ? y + space : y);
}

void _floorplanGridDrawLines(Canvas canvas, Size size, double space, Paint paint, Offset translate) {
  for (var x = 0.0; x <= size.width; x += space) {
    canvas.drawLine(Offset(x, 0) - translate, Offset(x, size.height) - translate, paint);
  }
  for (var y = 0.0; y <= size.height; y += space) {
    canvas.drawLine(Offset(0, y) - translate, Offset(size.width, y) - translate, paint);
  }
}
