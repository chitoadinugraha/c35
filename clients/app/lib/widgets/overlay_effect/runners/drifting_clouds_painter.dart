import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class DriftingCloudsState {
  DriftingCloudsState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 4;
  late double _speed;
  late double _opacity;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 180.0;
  var _gustStrength = 0.4;
  var _dragStrength = 0.55;
  final _clouds = <_Cloud>[];
  final _prevPointers = <int, Offset>{};
  double _seed = 0.0;

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 4);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 0.4);
    _opacity = overlayEffectParamDouble(params, 'opacity', 0.15);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#ffffff'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 180);
    _gustStrength = overlayEffectParamDouble(params, 'gust_strength', 40) / 100;
    _dragStrength = overlayEffectParamDouble(params, 'drag_strength', 55) / 100;
    _clouds.clear();
    _respawn();
  }

  void resize(Size size) => effectSimResize(
        current: _size,
        next: size,
        onSize: (s) => _size = s,
        respawn: _respawn,
      );

  void _respawn() {
    if (_size.width <= 0 || _size.height <= 0) return;
    _clouds.clear();
    for (int i = 0; i < _density; i++) {
      final startX = effectRand01(i * 3.42) * (_size.width + 300.0) - 150.0;
      _clouds.add(_createCloud(i * 5.48, startX));
    }
  }

  _Cloud _createCloud(double seed, double startX) {
    final y = effectRand01(seed) * (_size.height * 0.4) + 40.0;
    final numCircles = (effectRand01(seed + 1.0) * 3.0).floor() + 4;
    final circles = <_CloudCircle>[];
    double currentDx = 0.0;
    for (int j = 0; j < numCircles; j++) {
      final circleSeed = seed + j * 2.33;
      final r = effectRand01(circleSeed) * 25.0 + 20.0;
      circles.add(_CloudCircle(dx: currentDx, dy: (effectRand01(circleSeed + 1.0) - 0.5) * 12.0, r: r));
      currentDx += r * 0.6;
    }
    return _Cloud(
      x: startX,
      y: y,
      w: currentDx + 40.0,
      speed: (effectRand01(seed + 2.0) * 0.4 + 0.8) * _speed,
      circles: circles,
    );
  }

  Offset _pointerDelta(int id, Offset cur) {
    final prev = _prevPointers[id];
    return prev == null ? Offset.zero : cur - prev;
  }

  void _simulateCloud(_Cloud cloud, OverlayEffectPointerFrame? frame) {
    if (!_touchEnabled || frame == null || frame.pointers.isEmpty) {
      cloud.x += cloud.speed;
      return;
    }
    final cloudCenter = Offset(cloud.x + cloud.w * 0.5, cloud.y);
    for (final entry in frame.pointers.entries) {
      final pullT = overlayEffectTouchPullT(entry.value, cloudCenter.dx, cloudCenter.dy, _touchRadius);
      if (pullT == null) continue;
      final delta = _pointerDelta(entry.key, entry.value);
      cloud.x += cloud.speed + pullT * _gustStrength * 1.8 + delta.dx * _dragStrength * 0.12;
      cloud.y += delta.dy * _dragStrength * 0.06;
      return;
    }
    cloud.x += cloud.speed;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_clouds.isEmpty) _respawn();

    for (final cloud in _clouds) {
      _simulateCloud(cloud, pointers);
      if (cloud.x > _size.width + 50.0) {
        _seed += 1.489;
        final newCloud = _createCloud(_seed, -cloud.w - 50.0);
        cloud.x = newCloud.x;
        cloud.y = newCloud.y;
        cloud.w = newCloud.w;
        cloud.speed = newCloud.speed;
        cloud.circles
          ..clear()
          ..addAll(newCloud.circles);
      }
      for (final c in cloud.circles) {
        effectEmit(
          out,
          kind: effectKindEllipseFilled,
          x: cloud.x + c.dx,
          y: cloud.y + c.dy,
          a: c.r,
          b: c.r,
          rot: 0,
          opacity: _opacity,
          color: _color,
        );
      }
    }

    _prevPointers
      ..clear()
      ..addAll(pointers?.pointers ?? const {});
  }
}

class _CloudCircle {
  _CloudCircle({required this.dx, required this.dy, required this.r});
  final double dx, dy, r;
}

class _Cloud {
  _Cloud({required this.x, required this.y, required this.w, required this.speed, required this.circles});
  double x, y, w, speed;
  final List<_CloudCircle> circles;
}
