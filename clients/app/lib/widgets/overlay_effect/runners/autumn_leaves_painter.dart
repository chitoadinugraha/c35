import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class AutumnLeavesState {
  AutumnLeavesState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 20;
  late double _speed;
  late double _sizeBase;
  var _touchEnabled = true;
  var _touchRadius = 130.0;
  var _gustStrength = 0.45;
  var _swirlStrength = 0.5;
  final _leaves = <_Leaf>[];

  static const _leafColors = [
    Color(0xFFD35400),
    Color(0xFFE67E22),
    Color(0xFFF1C40F),
    Color(0xFFC0392B),
  ];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 20);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 1.5);
    _sizeBase = overlayEffectParamDouble(params, 'size', 14);
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 130);
    _gustStrength = overlayEffectParamDouble(params, 'gust_strength', 45) / 100;
    _swirlStrength = overlayEffectParamDouble(params, 'swirl_strength', 50) / 100;
    _leaves.clear();
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
    _leaves.clear();
    for (int i = 0; i < _density; i++) {
      final s = i * 2.87;
      _leaves.add(_spawnLeaf(s, effectRand01(s + 8) * -_size.height));
    }
  }

  _Leaf _spawnLeaf(double seed, double startY) {
    final colorIdx = (effectRand01(seed) * _leafColors.length).floor().clamp(0, _leafColors.length - 1);
    return _Leaf(
      x: effectRand01(seed + 1) * _size.width,
      y: startY,
      size: effectRand01(seed + 2) * (_sizeBase - 4) + 6.0,
      speed: effectRand01(seed + 3) * _speed + 0.8,
      swaySpeed: effectRand01(seed + 4) * 0.02 + 0.01,
      swayRange: effectRand01(seed + 5) * 18.0 + 6.0,
      swayOffset: effectRand01(seed + 6) * math.pi * 2,
      opacity: effectRand01(seed + 7) * 0.4 + 0.55,
      rotation: effectRand01(seed + 8) * math.pi * 2,
      spin: (effectRand01(seed + 9) - 0.5) * 0.015,
      color: _leafColors[colorIdx],
    );
  }

  void _simulateLeaf(_Leaf leaf, double x, Iterable<Offset> pointers) {
    if (_touchEnabled && pointers.isNotEmpty) {
      overlayEffectApplyGust(
        x: x,
        y: leaf.y,
        readDriftX: () => leaf.driftX,
        writeDriftX: (v) => leaf.driftX = v,
        pointers: pointers,
        radius: _touchRadius,
        strength: _gustStrength,
      );
      overlayEffectApplySwirl(
        x: x,
        y: leaf.y,
        apply: (ax, ay) {
          leaf.driftX += ax * 2.0;
          leaf.driftY += ay * 1.2;
        },
        pointers: pointers,
        radius: _touchRadius,
        strength: _swirlStrength,
      );
    }
    leaf
      ..driftX *= 0.93
      ..driftY *= 0.9
      ..y += leaf.speed + leaf.driftY * 0.06
      ..swayOffset += leaf.swaySpeed
      ..rotation += leaf.spin;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_leaves.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;
    final pts = _touchEnabled ? (pointers?.pointers.values ?? const <Offset>[]) : const <Offset>[];

    for (final leaf in _leaves) {
      _simulateLeaf(leaf, leaf.x + leaf.driftX, pts);
      final x = leaf.x + math.sin(leaf.swayOffset) * leaf.swayRange + leaf.driftX;
      effectEmit(
        out,
        kind: effectKindLeaf,
        x: x,
        y: leaf.y,
        a: leaf.size,
        b: 0,
        rot: leaf.rotation,
        opacity: leaf.opacity,
        color: leaf.color,
      );
      if (leaf.y > h + 20) {
        leaf.x = effectRand01(leaf.x + leaf.rotation) * w;
        leaf.y = -20;
        leaf.driftX = 0;
        leaf.driftY = 0;
        leaf.speed = effectRand01(leaf.y + leaf.speed) * _speed + 0.8;
      }
    }
  }
}

class _Leaf {
  _Leaf({
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
    required this.color,
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
  final Color color;
  double driftX = 0;
  double driftY = 0;
}
