import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';
import '../overlay_effect_pointer_physics.dart';

class StarryNightState {
  StarryNightState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 50;
  late double _twinkleSpeed;
  late Color _color;
  var _shootingStars = true;
  var _touchEnabled = true;
  var _touchRadius = 140.0;
  var _twinkleBoost = 0.65;
  final _stars = <_Star>[];
  final _shootingStarsList = <_ShootingStar>[];
  double _seed = 0.0;

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 50);
    _density = (raw * densityScale).round().clamp(1, raw);
    _twinkleSpeed = overlayEffectParamDouble(params, 'speed', 0.6);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#ffffff'));
    _shootingStars = overlayEffectParamBool(params, 'shootingStars', true);
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 140);
    _twinkleBoost = overlayEffectParamDouble(params, 'twinkle_boost', 65) / 100;
    _stars.clear();
    _shootingStarsList.clear();
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
    _stars.clear();
    _shootingStarsList.clear();
    for (int i = 0; i < _density; i++) {
      final s = i * 4.56;
      _stars.add(_Star(
        x: effectRand01(s) * _size.width,
        y: effectRand01(s + 1) * _size.height,
        r: effectRand01(s + 2) * 1.5 + 0.8,
        twinkleSpeed: effectRand01(s + 3) * 0.05 * _twinkleSpeed + 0.02 * _twinkleSpeed,
        twinkleOffset: effectRand01(s + 4) * math.pi * 2,
      ));
    }
  }

  void _spawnShootingStar() {
    if (_size.width <= 0 || _size.height <= 0) return;
    _seed += 2.112;
    final startX = effectRand01(_seed) * _size.width;
    final startY = effectRand01(_seed + 1.0) * (_size.height * 0.4);
    final angle = math.pi * 0.15 + effectRand01(_seed + 2.0) * (math.pi * 0.15);
    final speed = effectRand01(_seed + 3.0) * 8.0 + 8.0;
    _shootingStarsList.add(_ShootingStar(
      x: startX,
      y: startY,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed,
      opacity: 1.0,
    ));
  }

  double _touchBoostFor(double x, double y, Iterable<Offset> pts) {
    if (!_touchEnabled || pts.isEmpty) return 0;
    var boost = 0.0;
    for (final center in pts) {
      final pullT = overlayEffectTouchPullT(center, x, y, _touchRadius);
      if (pullT != null) boost = math.max(boost, pullT);
    }
    return boost * _twinkleBoost;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_stars.isEmpty) _respawn();
    final pts = pointers?.pointers.values ?? const <Offset>[];

    for (final star in _stars) {
      final boost = _touchBoostFor(star.x, star.y, pts);
      star.twinkleOffset += star.twinkleSpeed * (1 + boost * 2.5);
      final opacityMod = (math.sin(star.twinkleOffset) * 0.4 + 0.6) * (0.75 + boost * 0.5);
      final size = star.r * (1 + boost * 0.4);
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: star.x,
        y: star.y,
        a: size,
        b: size,
        rot: 0,
        opacity: opacityMod.clamp(0.0, 1.0),
        color: _color,
      );
    }

    for (int i = 0; i < _shootingStarsList.length;) {
      final s = _shootingStarsList[i];
      s.x += s.vx;
      s.y += s.vy;
      s.opacity -= 0.025;
      if (s.opacity <= 0.0) {
        _shootingStarsList.removeAt(i);
      } else {
        effectEmit(
          out,
          kind: effectKindLine,
          x: s.x,
          y: s.y,
          a: s.x - s.vx * 1.5,
          b: s.y - s.vy * 1.5,
          rot: 1.5,
          opacity: s.opacity,
          color: const Color(0xFFFFFFFF),
        );
        i++;
      }
    }

    if (_shootingStars) {
      _seed += 1.48;
      if (effectRand01(_seed) < 0.015 && _shootingStarsList.length < 3) _spawnShootingStar();
    }
  }
}

class _Star {
  _Star({required this.x, required this.y, required this.r, required this.twinkleSpeed, required this.twinkleOffset});
  final double x, y, r, twinkleSpeed;
  double twinkleOffset;
}

class _ShootingStar {
  _ShootingStar({required this.x, required this.y, required this.vx, required this.vy, required this.opacity});
  double x, y;
  final double vx, vy;
  double opacity;
}
