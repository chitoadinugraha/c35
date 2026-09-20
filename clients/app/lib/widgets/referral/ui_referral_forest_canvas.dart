import 'dart:math' as math;

import 'package:flutter/material.dart';

class UiReferralForestCanvasController {
  UiReferralForestCanvasState? _state;

  void centerOn(Offset targetInChild, {bool animate = true}) => _state?.centerOn(targetInChild, animate: animate);

  void alignCenter({bool animate = true}) => _state?.alignCenter(animate: animate);

  void fitToView({bool animate = true}) => _state?.fitToView(animate: animate);

  void fitToRect(Rect targetRectInChild, {bool animate = true, double padding = 64}) =>
      _state?.fitToRect(targetRectInChild, animate: animate, padding: padding);

  Offset toChildCoordinates(Offset globalPoint) => _state?.toChildCoordinates(globalPoint) ?? globalPoint;

  Offset? viewportCenterInChild() => _state?.viewportCenterInChild();

  void setPanEnabled(bool enabled) => _state?.setPanEnabled(enabled);

  double viewportScale() => _state?.viewportScale ?? 1.0;
}

class UiReferralForestCanvas extends StatefulWidget {
  const UiReferralForestCanvas({
    super.key,
    required this.child,
    this.fixedChildSize,
    this.initialTargetInChild,
    this.controller,
    this.panEnabled = true,
  });

  final Widget child;
  final Size? fixedChildSize;
  final Offset? initialTargetInChild;
  final UiReferralForestCanvasController? controller;
  final bool panEnabled;

  static const canvasR = 2000000.0;
  static const minScale = 0.1;
  static const maxScale = 10.0;
  static const bg = Color(0xFF08080A);

  @override
  State<UiReferralForestCanvas> createState() => UiReferralForestCanvasState();
}

class UiReferralForestCanvasState extends State<UiReferralForestCanvas> with TickerProviderStateMixin {
  final _transformationCtrl = TransformationController();
  final _childKey = GlobalKey();
  Size? _viewerSize;
  AnimationController? _animCtrl;
  var _panEnabled = true;

  void setPanEnabled(bool enabled) {
    if (_panEnabled == enabled) return;
    setState(() => _panEnabled = enabled);
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFocus());
  }

  @override
  void didUpdateWidget(covariant UiReferralForestCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _animCtrl?.dispose();
    _transformationCtrl.dispose();
    super.dispose();
  }

  void _applyInitialFocus() {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.isEmpty) return;
    if (widget.initialTargetInChild != null) {
      centerOn(widget.initialTargetInChild!, animate: false);
    } else {
      alignCenter(animate: false);
    }
  }

  void centerOn(Offset targetInChild, {bool animate = false}) {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.isEmpty) return;
    const canvasR = UiReferralForestCanvas.canvasR;
    final targetMatrix = Matrix4.translationValues(
      viewerSize.width / 2 - (canvasR + targetInChild.dx),
      viewerSize.height / 2 - (canvasR + targetInChild.dy),
      0,
    );
    if (animate && mounted) {
      _animateToMatrix(targetMatrix);
    } else {
      _transformationCtrl.value = targetMatrix;
    }
  }

  void alignCenter({bool animate = false}) {
    final viewerSize = _viewerSize;
    final childSize = widget.fixedChildSize ?? (_childKey.currentContext?.findRenderObject() as RenderBox?)?.size;
    if (viewerSize == null || viewerSize.isEmpty || childSize == null || childSize.isEmpty) return;
    const canvasR = UiReferralForestCanvas.canvasR;
    final targetMatrix = Matrix4.translationValues(
      viewerSize.width / 2 - (canvasR + childSize.width / 2),
      viewerSize.height / 2 - (canvasR + childSize.height / 2),
      0,
    );
    if (animate && mounted) {
      _animateToMatrix(targetMatrix);
    } else {
      _transformationCtrl.value = targetMatrix;
    }
  }

  void fitToView({bool animate = false, double padding = 48}) {
    final viewerSize = _viewerSize;
    final childSize = widget.fixedChildSize ?? (_childKey.currentContext?.findRenderObject() as RenderBox?)?.size;
    if (viewerSize == null || childSize == null) return;
    const canvasR = UiReferralForestCanvas.canvasR;
    final scale = math
        .min(
          math.max(viewerSize.width - padding * 2, 1.0) / childSize.width,
          math.max(viewerSize.height - padding * 2, 1.0) / childSize.height,
        )
        .clamp(UiReferralForestCanvas.minScale, UiReferralForestCanvas.maxScale);
    final centerX = canvasR + childSize.width / 2;
    final centerY = canvasR + childSize.height / 2;
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(viewerSize.width / 2 - scale * centerX, viewerSize.height / 2 - scale * centerY, 0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
    if (animate && mounted) {
      _animateToMatrix(targetMatrix);
    } else {
      _transformationCtrl.value = targetMatrix;
    }
  }

  void fitToRect(Rect targetRectInChild, {bool animate = false, double padding = 64}) {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.isEmpty) return;
    const canvasR = UiReferralForestCanvas.canvasR;
    final rectW = math.max(targetRectInChild.width, 100.0);
    final rectH = math.max(targetRectInChild.height, 100.0);
    final availableW = math.max(viewerSize.width - padding * 2, 1.0);
    final availableH = math.max(viewerSize.height - padding * 2, 1.0);
    final scale = math
        .min(availableW / rectW, availableH / rectH)
        .clamp(UiReferralForestCanvas.minScale, UiReferralForestCanvas.maxScale);
    final centerX = canvasR + targetRectInChild.center.dx;
    final centerY = canvasR + targetRectInChild.center.dy;
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(viewerSize.width / 2 - scale * centerX, viewerSize.height / 2 - scale * centerY, 0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
    if (animate && mounted) {
      _animateToMatrix(targetMatrix);
    } else {
      _transformationCtrl.value = targetMatrix;
    }
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _animCtrl?.dispose();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    final anim = Matrix4Tween(begin: _transformationCtrl.value, end: targetMatrix).animate(
      CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOutCubic),
    );
    anim.addListener(() => _transformationCtrl.value = anim.value);
    _animCtrl!.forward();
  }

  Offset toChildCoordinates(Offset globalPoint) {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.globalToLocal(globalPoint);
    return globalPoint;
  }

  Offset? viewportCenterInChild() {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.isEmpty) return null;
    const canvasR = UiReferralForestCanvas.canvasR;
    final inverse = Matrix4.inverted(_transformationCtrl.value);
    final onCanvas = MatrixUtils.transformPoint(inverse, Offset(viewerSize.width / 2, viewerSize.height / 2));
    return Offset(onCanvas.dx - canvasR, onCanvas.dy - canvasR);
  }

  double get viewportScale => _transformationCtrl.value.getMaxScaleOnAxis();

  @override
  Widget build(BuildContext context) {
    const canvasR = UiReferralForestCanvas.canvasR;
    return ExcludeSemantics(
      child: ClipRect(
        child: ColoredBox(
          color: UiReferralForestCanvas.bg,
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final viewerSize = Size(viewportConstraints.maxWidth, viewportConstraints.maxHeight);
              if (_viewerSize != viewerSize) {
                final prev = _viewerSize;
                _viewerSize = viewerSize;
                if ((prev == null || prev.isEmpty) && !viewerSize.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _applyInitialFocus();
                  });
                }
              }
              return SizedBox(
                width: viewerSize.width,
                height: viewerSize.height,
                child: InteractiveViewer(
                  panEnabled: widget.panEnabled && _panEnabled,
                  scaleEnabled: widget.panEnabled && _panEnabled,
                  transformationController: _transformationCtrl,
                  minScale: UiReferralForestCanvas.minScale,
                  maxScale: UiReferralForestCanvas.maxScale,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: canvasR * 2,
                    height: canvasR * 2,
                    child: Stack(
                      children: [
                        RepaintBoundary(child: _ForestGridLayer(transformation: _transformationCtrl, viewerSize: viewerSize)),
                        Positioned(
                          left: canvasR,
                          top: canvasR,
                          child: KeyedSubtree(
                            key: _childKey,
                            child: widget.fixedChildSize == null
                                ? widget.child
                                : SizedBox(
                                    width: widget.fixedChildSize!.width,
                                    height: widget.fixedChildSize!.height,
                                    child: widget.child,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ForestGridLayer extends StatelessWidget {
  const _ForestGridLayer({required this.transformation, required this.viewerSize});

  final TransformationController transformation;
  final Size viewerSize;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ForestGridPainter(transformation: transformation, viewerSize: viewerSize),
        child: const SizedBox.expand(),
      );
}

class _ForestGridPainter extends CustomPainter {
  _ForestGridPainter({required this.transformation, required this.viewerSize}) : super(repaint: transformation);

  final TransformationController transformation;
  final Size viewerSize;

  static const _overscan = 2000.0;
  static const _major = 200.0;
  static const _minor = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final inverse = Matrix4.inverted(transformation.value);
    final a = MatrixUtils.transformPoint(inverse, Offset.zero);
    final b = MatrixUtils.transformPoint(inverse, Offset(viewerSize.width, viewerSize.height));
    final viewport = Rect.fromPoints(
      Offset(a.dx < b.dx ? a.dx : b.dx, a.dy < b.dy ? a.dy : b.dy),
      Offset(a.dx > b.dx ? a.dx : b.dx, a.dy > b.dy ? a.dy : b.dy),
    );
    final overscan = Rect.fromLTWH(
      viewport.left - _overscan,
      viewport.top - _overscan,
      viewport.width + _overscan * 2,
      viewport.height + _overscan * 2,
    );
    canvas.save();
    canvas.translate(overscan.left, overscan.top);
    _drawLines(canvas, overscan.size, viewport.topLeft, _major, Paint()
      ..color = const Color(0xFF1F1F24)
      ..strokeWidth = 1.1);
    _drawLines(canvas, overscan.size, viewport.topLeft, _minor, Paint()
      ..color = const Color(0xFF141418)
      ..strokeWidth = 0.7);
    canvas.restore();
  }

  void _drawLines(Canvas canvas, Size size, Offset topLeft, double space, Paint paint) {
    var xPhase = topLeft.dx % space;
    var yPhase = topLeft.dy % space;
    if (xPhase < 0) xPhase += space;
    if (yPhase < 0) yPhase += space;
    final origin = Offset(xPhase, yPhase);
    for (var x = 0.0; x <= size.width; x += space) {
      canvas.drawLine(Offset(x, 0) - origin, Offset(x, size.height) - origin, paint);
    }
    for (var y = 0.0; y <= size.height; y += space) {
      canvas.drawLine(Offset(0, y) - origin, Offset(size.width, y) - origin, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ForestGridPainter oldDelegate) => viewerSize != oldDelegate.viewerSize;
}
