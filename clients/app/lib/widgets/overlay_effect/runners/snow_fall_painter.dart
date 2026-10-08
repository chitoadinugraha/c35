import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class SnowFallState {
  SnowFallState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 60;
  late double _speed;
  late double _sizeBase;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 110.0;
  var _gustStrength = 0.5;
  final _flakes = <_Flake>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 60);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 1.5);
    _sizeBase = overlayEffectParamDouble(params, 'size', 5);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#ffffff'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 110);
    _gustStrength = overlayEffectParamDouble(params, 'gust_strength', 50) / 100;
    _flakes.clear();
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
    _flakes.clear();
    for (int i = 0; i < _density; i++) {
      _flakes.add(_spawnFlake(i * 2.33));
    }
  }

  _Flake _spawnFlake(double seed) => _Flake(
        x: effectRand01(seed) * _size.width,
        y: effectRand01(seed + 1) * -_size.height,
        r: effectRand01(seed + 2) * _sizeBase + 1.5,
        speed: effectRand01(seed + 3) * _speed + 0.5,
        swaySpeed: effectRand01(seed + 4) * 0.03 + 0.01,
        swayRange: effectRand01(seed + 5) * 15.0 + 5.0,
        swayOffset: effectRand01(seed + 6) * math.pi * 2,
        opacity: effectRand01(seed + 7) * 0.5 + 0.3,
      );

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_flakes.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;
    final pts = _touchEnabled ? (pointers?.pointers.values ?? const <Offset>[]) : const <Offset>[];

    for (final flake in _flakes) {
      if (pts.isNotEmpty) {
        overlayEffectApplyGust(
          x: flake.x,
          y: flake.y,
          readDriftX: () => flake.driftX,
          writeDriftX: (v) => flake.driftX = v,
          pointers: pts,
          radius: _touchRadius,
          strength: _gustStrength,
        );
      }
      flake
        ..driftX *= 0.94
        ..y += flake.speed
        ..swayOffset += flake.swaySpeed;
      final x = flake.x + math.sin(flake.swayOffset) * flake.swayRange + flake.driftX;
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: x,
        y: flake.y,
        a: flake.r,
        b: flake.r,
        rot: 0,
        opacity: flake.opacity,
        color: _color,
      );
      if (flake.y > h + 20) {
        flake
          ..x = effectRand01(flake.x + flake.swayOffset) * w
          ..y = -20
          ..driftX = 0
          ..speed = effectRand01(flake.y + flake.speed) * _speed + 0.5;
      }
    }
  }
}

class _Flake {
  _Flake({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.swaySpeed,
    required this.swayRange,
    required this.swayOffset,
    required this.opacity,
  });
  double x, y;
  final double r;
  double speed;
  final double swaySpeed;
  final double swayRange;
  double swayOffset;
  final double opacity;
  double driftX = 0;
}
