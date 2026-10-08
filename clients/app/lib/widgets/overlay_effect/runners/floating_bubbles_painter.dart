import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';

class FloatingBubblesState {
  FloatingBubblesState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 25;
  late double _speed;
  late double _sizeBase;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 90.0;
  var _popStrength = 0.7;
  final _bubbles = <_Bubble>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 25);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 1.2);
    _sizeBase = overlayEffectParamDouble(params, 'size', 16);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#aedbf0'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 90);
    _popStrength = overlayEffectParamDouble(params, 'pop_strength', 70) / 100;
    _bubbles.clear();
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
    _bubbles.clear();
    for (int i = 0; i < _density; i++) {
      final seed = i * 3.14;
      _bubbles.add(_spawnBubble(seed, effectRand01(seed + 8) * _size.height));
    }
  }

  _Bubble _spawnBubble(double seed, double startY) => _Bubble(
        x: effectRand01(seed) * _size.width,
        y: startY,
        r: effectRand01(seed + 1) * _sizeBase + 5.0,
        speed: effectRand01(seed + 2) * _speed + 0.4,
        wobbleSpeed: effectRand01(seed + 3) * 0.04 + 0.02,
        wobbleRange: effectRand01(seed + 4) * 10.0 + 3.0,
        wobbleOffset: effectRand01(seed + 5) * math.pi * 2,
        opacity: effectRand01(seed + 6) * 0.4 + 0.15,
      );

  bool _shouldPop(_Bubble b, double x, Iterable<Offset> pointers) {
    final popR = _touchRadius * _popStrength;
    for (final center in pointers) {
      final dx = x - center.dx;
      final dy = b.y - center.dy;
      if (dx * dx + dy * dy < (popR + b.r) * (popR + b.r)) return true;
    }
    return false;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_bubbles.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;
    final pts = _touchEnabled ? (pointers?.pointers.values ?? const <Offset>[]) : const <Offset>[];

    for (final b in _bubbles) {
      b.y -= b.speed;
      b.wobbleOffset += b.wobbleSpeed;
      final x = b.x + math.sin(b.wobbleOffset) * b.wobbleRange;

      if (pts.isNotEmpty && _shouldPop(b, x, pts)) {
        b.x = effectRand01(b.x + b.y) * w;
        b.y = h + b.r + 20;
        b.speed = effectRand01(b.y + b.speed) * _speed + 0.4;
        continue;
      }

      effectEmit(
        out,
        kind: effectKindEllipse,
        x: x,
        y: b.y,
        a: b.r,
        b: b.r,
        rot: 1.0,
        opacity: b.opacity,
        color: _color,
      );
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: x - b.r * 0.3,
        y: b.y - b.r * 0.3,
        a: b.r * 0.15,
        b: b.r * 0.15,
        rot: 0,
        opacity: b.opacity * 0.6,
        color: const Color(0xFFFFFFFF),
      );

      if (b.y < -b.r - 20) {
        b.x = effectRand01(b.x + b.y) * w;
        b.y = h + b.r + 20;
        b.speed = effectRand01(b.y + b.speed) * _speed + 0.4;
      }
    }
  }
}

class _Bubble {
  _Bubble({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.wobbleSpeed,
    required this.wobbleRange,
    required this.wobbleOffset,
    required this.opacity,
  });
  double x, y;
  final double r;
  double speed;
  final double wobbleSpeed;
  final double wobbleRange;
  double wobbleOffset;
  final double opacity;
}
