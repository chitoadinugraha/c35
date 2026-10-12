import 'dart:math' as math;

import 'package:alienai_c35/guest_site/guest_site_preview_handoff.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_phone_preview_frame.dart';
import 'package:alienai_c35/widgets/ui/floorplan_config.dart';
import 'package:alienai_c35/widgets/ui/ui_floorplan_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controls exposed to the preview pane header (CSA toolbar).
class SitePreviewStageControls {
  const SitePreviewStageControls({required this.onRecenter});

  final VoidCallback onRecenter;
}

/// Editor preview surface — pan/pinch canvas with thin grid + centered phone (CSA).
///
/// Guest taps and drags on the phone scroll the site until an edge (or when the
/// page does not scroll); further drag pans the stage. Canvas zoom/pan also uses
/// Ctrl+scroll or Ctrl+drag (mouse), pinch, or two-finger pan; mouse drag on the
/// grid background pans the canvas.
class UiSitePreviewStage extends StatefulWidget {
  const UiSitePreviewStage({
    super.key,
    required this.child,
    this.headerBuilder,
  });

  final Widget child;
  final Widget Function(BuildContext context, SitePreviewStageControls controls)? headerBuilder;

  static const _fitPad = 20.0;
  static const fitPad = _fitPad;

  @override
  State<UiSitePreviewStage> createState() => _UiSitePreviewStageState();
}

void _sitePreviewZoomWheel(
  TransformationController xf,
  Offset viewportPoint,
  double scaleFactor, {
  double minScale = FloorplanConfig.minScale,
  double maxScale = FloorplanConfig.maxScale,
}) {
  final matrix = xf.value.clone();
  final currentScale = matrix.getMaxScaleOnAxis();
  final newScale = (currentScale * scaleFactor).clamp(minScale, maxScale);
  if (newScale == currentScale) return;
  final focal = MatrixUtils.transformPoint(Matrix4.inverted(matrix), viewportPoint);
  final scale = newScale / currentScale;
  matrix
    ..translateByDouble(focal.dx, focal.dy, 0, 1.0)
    ..scaleByDouble(scale, scale, 1.0, 1.0)
    ..translateByDouble(-focal.dx, -focal.dy, 0, 1.0);
  xf.value = matrix;
}

class _UiSitePreviewStageState extends State<UiSitePreviewStage> {
  final _transformationCtrl = TransformationController();
  Size? _viewerSize;

  final Map<int, Offset> _pointers = {};
  bool _absorbGuest = false;
  bool _ctrlPan = false;
  bool _gridPan = false;
  Offset? _panLast;
  double? _pinchDistance;
  Offset? _pinchFocal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToScreen();
    });
  }

  @override
  void dispose() {
    _transformationCtrl.dispose();
    super.dispose();
  }

  void _fitToScreen() {
    final viewerSize = _viewerSize;
    if (viewerSize == null || viewerSize.width <= 0 || viewerSize.height <= 0) return;
    final pad = UiSitePreviewStage._fitPad;
    final availW = math.max(1.0, viewerSize.width - pad * 2);
    final availH = math.max(1.0, viewerSize.height - pad * 2);
    final scale = math
        .min(availW / UiSitePhonePreviewFrame.phoneW, availH / UiSitePhonePreviewFrame.phoneH)
        .clamp(FloorplanConfig.minScale, 1.0);
    final canvasR = FloorplanConfig.canvasR;
    final dx = viewerSize.width / 2 - (canvasR + UiSitePhonePreviewFrame.phoneW / 2) * scale;
    final dy = viewerSize.height / 2 - (canvasR + UiSitePhonePreviewFrame.phoneH / 2) * scale;
    _transformationCtrl.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  SitePreviewStageControls get _controls => SitePreviewStageControls(onRecenter: _fitToScreen);

  Rect get _phoneSceneRect {
    final r = FloorplanConfig.canvasR;
    return Rect.fromLTWH(r, r, UiSitePhonePreviewFrame.phoneW, UiSitePhonePreviewFrame.phoneH);
  }

  Offset _viewportToScene(Offset viewportLocal) {
    final inverse = Matrix4.inverted(_transformationCtrl.value);
    return MatrixUtils.transformPoint(inverse, viewportLocal);
  }

  bool _pointOnPhone(Offset viewportLocal) => _phoneSceneRect.contains(_viewportToScene(viewportLocal));

  /// Screen-space pan (pre-multiply) so movement stays 1:1 at any zoom.
  void _translateViewport(Offset delta) {
    final pan = Matrix4.identity()..translateByDouble(delta.dx, delta.dy, 0, 1);
    _transformationCtrl.value = pan * _transformationCtrl.value;
  }

  bool _isMouse(PointerEvent event) => event.kind == PointerDeviceKind.mouse;

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;
    final scaleChange = math.exp(-event.scrollDelta.dy * 0.01);
    _sitePreviewZoomWheel(_transformationCtrl, event.localPosition, scaleChange);
  }

  void _syncAbsorbGuest() {
    final absorb = _pointers.length >= 2 || _ctrlPan;
    if (absorb != _absorbGuest) setState(() => _absorbGuest = absorb);
  }

  void _resetPinch() {
    _pinchDistance = null;
    _pinchFocal = null;
  }

  void _applyPinchPan() {
    if (_pointers.length < 2) return;
    final pts = _pointers.values.toList(growable: false);
    final focal = Offset((pts[0].dx + pts[1].dx) / 2, (pts[0].dy + pts[1].dy) / 2);
    final distance = (pts[0] - pts[1]).distance.clamp(1.0, double.infinity);
    if (_pinchDistance != null && _pinchFocal != null) {
      _sitePreviewZoomWheel(_transformationCtrl, focal, distance / _pinchDistance!);
      _translateViewport(focal - _pinchFocal!);
    }
    _pinchDistance = distance;
    _pinchFocal = focal;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      _ctrlPan = false;
      _gridPan = false;
      _panLast = null;
      _resetPinch();
    } else if (_pointers.length == 1 && _isMouse(event)) {
      if (HardwareKeyboard.instance.isControlPressed) {
        _ctrlPan = true;
        _gridPan = false;
        _panLast = event.localPosition;
      } else if (!_pointOnPhone(event.localPosition)) {
        _gridPan = true;
        _ctrlPan = false;
        _panLast = event.localPosition;
      }
    }
    _syncAbsorbGuest();
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      _applyPinchPan();
      return;
    }
    if ((_ctrlPan || _gridPan) && _panLast != null) {
      if (_ctrlPan && !_isMouse(event)) return;
      final delta = event.localPosition - _panLast!;
      _translateViewport(delta);
      _panLast = event.localPosition;
    }
  }

  void _releasePointer(int pointer) {
    _pointers.remove(pointer);
    _resetPinch();
    if (_pointers.isEmpty) {
      _ctrlPan = false;
      _gridPan = false;
      _panLast = null;
    } else if (_pointers.length == 1) {
      // Pinch ended — require a fresh down for single-finger / Ctrl pan.
      _ctrlPan = false;
      _gridPan = false;
      _panLast = null;
    }
    _syncAbsorbGuest();
  }

  void _onPointerUp(PointerUpEvent event) => _releasePointer(event.pointer);

  void _onPointerCancel(PointerCancelEvent event) => _releasePointer(event.pointer);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final header = widget.headerBuilder?.call(context, _controls);
    return ColoredBox(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  final viewerSize = Size(viewportConstraints.maxWidth, viewportConstraints.maxHeight);
                  if (_viewerSize != viewerSize) {
                    _viewerSize = viewerSize;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitToScreen();
                    });
                  }
                  final canvasR = FloorplanConfig.canvasR;
                  return Listener(
                    onPointerSignal: _onPointerSignal,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    onPointerCancel: _onPointerCancel,
                    behavior: HitTestBehavior.translucent,
                    child: AbsorbPointer(
                      absorbing: _absorbGuest,
                      child: SizedBox(
                        width: viewerSize.width,
                        height: viewerSize.height,
                        child: InteractiveViewer(
                          transformationController: _transformationCtrl,
                          panEnabled: false,
                          scaleEnabled: false,
                          minScale: FloorplanConfig.minScale,
                          maxScale: FloorplanConfig.maxScale,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          constrained: false,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: canvasR * 2,
                            height: canvasR * 2,
                            child: Stack(
                              children: [
                                UiFloorplanGridLayer(
                                  transformation: _transformationCtrl,
                                  viewerSize: viewerSize,
                                  colorScheme: cs,
                                ),
                                Positioned(
                                  left: canvasR,
                                  top: canvasR,
                                  child: SitePreviewViewportHandoff(
                                    onPan: _translateViewport,
                                    child: ScrollConfiguration(
                                      behavior: const SitePreviewHandoffScrollBehavior(),
                                      child: SitePreviewScrollHandoffListener(
                                        child: UiSitePhonePreviewFrame(child: widget.child),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
