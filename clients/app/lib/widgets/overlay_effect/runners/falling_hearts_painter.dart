import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class FallingHeartsState {
  FallingHeartsState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 35;
  late double _speed;
  late double _maxSize;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 96.0;
  final _hearts = <_Heart>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 35);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 2.5);
    _maxSize = overlayEffectParamDouble(params, 'size', 22);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#ff6b81'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    final collect = overlayEffectParamDouble(params, 'collect_radius', 48);
    _touchRadius = math.max(collect * 2.2, 72);
    _hearts.clear();
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
    _hearts
      ..clear()
      ..addAll(List.generate(_density, (i) => _spawnHeart(i, _maxSize)));
  }

  _Heart _spawnHeart(int i, double maxSize) {
    final seed = i * 1.618;
    final w = _size.width;
    final h = _size.height;
    return _Heart(
      x: effectRand01(seed) * w,
      y: effectRand01(seed + 1) * -h,
      size: effectRand01(seed + 2) * (maxSize - 8) + 10,
      speed: effectRand01(seed + 3) * _speed + 0.8,
      swaySpeed: effectRand01(seed + 4) * 0.02 + 0.01,
      swayRange: effectRand01(seed + 5) * 25 + 10,
      swayOffset: effectRand01(seed + 6) * math.pi * 2,
      opacity: effectRand01(seed + 7) * 0.5 + 0.45,
      rotation: effectRand01(seed + 8) * math.pi * 2,
      spin: (effectRand01(seed + 9) - 0.5) * 0.02,
    );
  }

  double _heartX(_Heart heart) => heart.x + math.sin(heart.swayOffset) * heart.swayRange + heart.driftX;

  void _burstAt(Offset center, _Heart heart, {required double strength}) {
    final x = _heartX(heart);
    final y = heart.y;
    final pullT = overlayEffectTouchPullT(center, x, y, _touchRadius);
    if (pullT == null) return;
    final dx = x - center.dx;
    final dy = y - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final amt = pullT * pullT * strength;
    heart
      ..driftX += (dx / dist) * amt
      ..driftY += (dy / dist) * amt;
  }

  void _applyTouch(_Heart heart, OverlayEffectPointerFrame? frame) {
    if (!_touchEnabled || frame == null) return;
    for (final tap in frame.downs) {
      _burstAt(tap, heart, strength: 14);
    }
    if (frame.pointers.isNotEmpty) {
      overlayEffectApplyRepulse(
        x: _heartX(heart),
        y: heart.y,
        apply: (ax, ay) {
          heart
            ..driftX += ax
            ..driftY += ay;
        },
        pointers: frame.pointers.values,
        radius: _touchRadius,
        strength: 3.2,
      );
    }
    for (final up in frame.ups) {
      _burstAt(up, heart, strength: 6);
    }
  }

  void _simulateHeart(_Heart heart, OverlayEffectPointerFrame? frame) {
    _applyTouch(heart, frame);
    heart
      ..driftX *= 0.9
      ..driftY *= 0.88
      ..y += heart.speed + heart.driftY * 0.1
      ..x += heart.driftX * 0.06
      ..swayOffset += heart.swaySpeed
      ..rotation += heart.spin;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_hearts.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;

    for (final heart in _hearts) {
      _simulateHeart(heart, pointers);
      effectEmit(
        out,
        kind: effectKindGlyph,
        x: _heartX(heart),
        y: heart.y,
        a: heart.size,
        b: 0,
        rot: heart.rotation,
        opacity: heart.opacity,
        color: _color,
      );
      if (heart.y > h + 20) {
        heart
          ..x = effectRand01(heart.x + heart.rotation) * w
          ..y = -20
          ..driftX = 0
          ..driftY = 0
          ..speed = effectRand01(heart.rotation) * _speed + 0.8;
      }
    }
  }
}

class _Heart {
  _Heart({
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

  double x;
  double y;
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
