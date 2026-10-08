import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class MoonlightState {
  MoonlightState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 30;
  late Color _moonColor;
  var _showMoon = true;
  var _glowIntensity = 5.0;
  var _touchEnabled = true;
  var _touchRadius = 150.0;
  var _glowBoost = 0.6;
  final _dust = <_DustParticle>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 30);
    _density = (raw * densityScale).round().clamp(1, raw);
    _moonColor = effectParseColor(overlayEffectParamString(params, 'moonColor', '#fffbe3'));
    _showMoon = overlayEffectParamBool(params, 'showMoon', true);
    _glowIntensity = overlayEffectParamDouble(params, 'glowIntensity', 5);
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 150);
    _glowBoost = overlayEffectParamDouble(params, 'glow_boost', 60) / 100;
    _dust.clear();
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
    _dust.clear();
    for (int i = 0; i < _density; i++) {
      final s = i * 4.19;
      _dust.add(_spawnDust(s, effectRand01(s + 8) * _size.height));
    }
  }

  _DustParticle _spawnDust(double seed, double startY) => _DustParticle(
        x: effectRand01(seed) * _size.width,
        y: startY,
        r: effectRand01(seed + 1) * 2.5 + 1.0,
        speed: effectRand01(seed + 2) * 0.4 + 0.15,
        swaySpeed: effectRand01(seed + 3) * 0.02 + 0.01,
        swayRange: effectRand01(seed + 4) * 12.0 + 4.0,
        swayOffset: effectRand01(seed + 5) * math.pi * 2,
        opacity: effectRand01(seed + 6) * 0.35 + 0.15,
      );

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_dust.isEmpty) _respawn();
    final w = _size.width;
    final h = _size.height;

    final moonX = w * 0.8;
    final moonY = h * 0.25;
    final moonR = math.min(w, h) * 0.12;
    final glowAlpha = 0.16 * (_glowIntensity / 5);

    for (final entry in [(4.0, glowAlpha), (2.2, glowAlpha * 0.55), (1.1, glowAlpha * 0.35)]) {
      final d = moonR * entry.$1;
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: moonX,
        y: moonY,
        a: d,
        b: d,
        rot: 0,
        opacity: entry.$2,
        color: _moonColor,
      );
    }

    if (_touchEnabled && pointers != null && pointers.pointers.isNotEmpty) {
      for (final center in pointers.pointers.values) {
        final pullT = overlayEffectTouchPullT(center, center.dx, center.dy, _touchRadius) ?? 1.0;
        final glowR = _touchRadius * (0.6 + _glowBoost * 0.8);
        effectEmit(
          out,
          kind: effectKindEllipseFilled,
          x: center.dx,
          y: center.dy,
          a: glowR,
          b: glowR,
          rot: 0,
          opacity: 0.12 * _glowBoost * pullT * (_glowIntensity / 5),
          color: _moonColor,
        );
      }
    }

    if (_showMoon) {
      effectEmit(
        out,
        kind: effectKindMoon,
        x: moonX,
        y: moonY,
        a: moonR * 0.4,
        b: 0,
        rot: -math.pi * 0.15,
        opacity: 0.65,
        color: _moonColor,
      );
    }

    for (final d in _dust) {
      d.y -= d.speed;
      d.swayOffset += d.swaySpeed;
      final x = d.x + math.sin(d.swayOffset) * d.swayRange;
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: x,
        y: d.y,
        a: d.r,
        b: d.r,
        rot: 0,
        opacity: d.opacity,
        color: _moonColor,
      );
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: x,
        y: d.y,
        a: d.r * 2.8,
        b: d.r * 2.8,
        rot: 0,
        opacity: d.opacity * 0.35,
        color: _moonColor,
      );
      if (d.y < -20) {
        d.x = effectRand01(d.x + d.y) * w;
        d.y = h + 20;
        d.speed = effectRand01(d.y + d.speed) * 0.4 + 0.15;
      }
    }
  }
}

class _DustParticle {
  _DustParticle({
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
}
