import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class SakuraPetalsState {
  SakuraPetalsState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 30;
  late double _speed;
  late double _sizeBase;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 130.0;
  var _gustStrength = 0.45;
  var _swirlStrength = 0.5;
  final _petals = <_SakuraPetal>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 30);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 2);
    _sizeBase = overlayEffectParamDouble(params, 'size', 12);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#ffb3c6'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 130);
    _gustStrength = overlayEffectParamDouble(params, 'gust_strength', 45) / 100;
    _swirlStrength = overlayEffectParamDouble(params, 'swirl_strength', 50) / 100;
    _petals.clear();
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
    _petals.clear();
    for (int i = 0; i < _density; i++) {
      final s = i * 2.618;
      _petals.add(_spawnPetal(s, effectRand01(s + 8) * -_size.height));
    }
  }

  _SakuraPetal _spawnPetal(double seed, double startY) => _SakuraPetal(
        x: effectRand01(seed) * _size.width,
        y: startY,
        size: effectRand01(seed + 1) * (_sizeBase - 4) + 6.0,
        speed: effectRand01(seed + 2) * _speed + 1.0,
        swaySpeed: effectRand01(seed + 3) * 0.03 + 0.015,
        swayRange: effectRand01(seed + 4) * 20.0 + 8.0,
        swayOffset: effectRand01(seed + 5) * math.pi * 2,
        opacity: effectRand01(seed + 6) * 0.4 + 0.5,
        rotation: effectRand01(seed + 7) * math.pi * 2,
        spin: (effectRand01(seed + 8) - 0.5) * 0.02,
      );

  void _simulatePetal(_SakuraPetal p, double x, Iterable<Offset> pointers) {
    if (_touchEnabled && pointers.isNotEmpty) {
      overlayEffectApplyGust(
        x: x,
        y: p.y,
        readDriftX: () => p.driftX,
        writeDriftX: (v) => p.driftX = v,
        pointers: pointers,
        radius: _touchRadius,
        strength: _gustStrength,
      );
      overlayEffectApplySwirl(
        x: x,
        y: p.y,
        apply: (ax, ay) {
          p.driftX += ax * 2.2;
          p.driftY += ay * 1.4;
        },
        pointers: pointers,
        radius: _touchRadius,
        strength: _swirlStrength,
      );
    }
    p
      ..driftX *= 0.93
      ..driftY *= 0.9
      ..y += p.speed + p.driftY * 0.06
      ..swayOffset += p.swaySpeed
      ..rotation += p.spin;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_petals.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;
    final pts = _touchEnabled ? (pointers?.pointers.values ?? const <Offset>[]) : const <Offset>[];

    for (final p in _petals) {
      _simulatePetal(p, p.x + p.driftX, pts);
      final x = p.x + math.sin(p.swayOffset) * p.swayRange + p.driftX;
      effectEmit(
        out,
        kind: effectKindSakura,
        x: x,
        y: p.y,
        a: p.size,
        b: math.sin(p.swayOffset),
        rot: p.rotation,
        opacity: p.opacity,
        color: _color,
      );
      if (p.y > h + 20) {
        p.x = effectRand01(p.x + p.rotation) * w;
        p.y = -20;
        p.driftX = 0;
        p.driftY = 0;
        p.speed = effectRand01(p.y + p.speed) * _speed + 1.0;
      }
    }
  }
}

class _SakuraPetal {
  _SakuraPetal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swaySpeed,
    required this.swayRange,
    required this.swayOffset,
    required this.opacity,
    required this.rotation,
    required this.spin,
  });
  double x, y;
  final double size;
  double speed;
  final double swaySpeed;
  final double swayRange;
  double swayOffset;
  final double opacity;
  double rotation;
  final double spin;
  double driftX = 0;
  double driftY = 0;
}
