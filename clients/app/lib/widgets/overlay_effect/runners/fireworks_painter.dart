import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';

class FireworksState {
  FireworksState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _particlesPerBurst = 50;
  late double _frequency;
  late double _sizeBase;
  late double _gravity;
  var _touchEnabled = true;
  var _tapParticles = 60;
  final _sparks = <_Spark>[];
  int _frame = 0;
  double _seed = 0.0;

  static const _burstColors = [
    Color(0xFFFF6B81),
    Color(0xFF8AE2FF),
    Color(0xFFFFB347),
    Color(0xFFB388FF),
    Color(0xFF2ECC71),
    Color(0xFFFFD700),
  ];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'particles', 50);
    _particlesPerBurst = (raw * densityScale).round().clamp(1, raw);
    _frequency = overlayEffectParamDouble(params, 'frequency', 3);
    _sizeBase = overlayEffectParamDouble(params, 'size', 3);
    _gravity = overlayEffectParamDouble(params, 'gravity', 0.06);
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _tapParticles = overlayEffectParamInt(params, 'burst_particles', 60);
    _sparks.clear();
    _frame = 0;
    _respawn();
  }

  void resize(Size size) => effectSimResize(
        current: _size,
        next: size,
        onSize: (s) => _size = s,
        respawn: _respawn,
      );

  void _respawn() => _sparks.clear();

  void _spawnBurstAt(double centerX, double centerY, {int? particleCount, Color? color}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    _seed += 1.879;
    final count = particleCount ?? _particlesPerBurst;
    final burstColor = color ?? _burstColors[(effectRand01(_seed + 2.0) * _burstColors.length).floor() % _burstColors.length];

    for (int i = 0; i < count; i++) {
      final angleSeed = i * 2.33 + _seed;
      final speedSeed = i * 3.77 + _seed;
      final angle = effectRand01(angleSeed) * math.pi * 2;
      final vel = effectRand01(speedSeed) * 4.5 + 1.5;
      _sparks.add(_Spark(
        x: centerX,
        y: centerY,
        vx: math.cos(angle) * vel,
        vy: math.sin(angle) * vel,
        size: effectRand01(angleSeed + 8) * _sizeBase + 1.0,
        opacity: 1.0,
        color: burstColor,
      ));
    }
  }

  void _spawnBurst() {
    if (_size.width <= 0 || _size.height <= 0) return;
    _seed += 1.879;
    final centerX = effectRand01(_seed) * (_size.width * 0.8) + _size.width * 0.1;
    final centerY = effectRand01(_seed + 1.0) * (_size.height * 0.5) + _size.height * 0.15;
    _spawnBurstAt(centerX, centerY);
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;

    if (_touchEnabled && pointers != null) {
      for (final pos in pointers.downs) {
        _spawnBurstAt(pos.dx, pos.dy, particleCount: _tapParticles);
      }
    }

    for (int i = 0; i < _sparks.length;) {
      final s = _sparks[i];
      s.x += s.vx;
      s.y += s.vy;
      s.vy += _gravity;
      s.opacity -= 0.015;
      if (s.opacity <= 0.0) {
        _sparks.removeAt(i);
      } else {
        effectEmit(
          out,
          kind: effectKindEllipseFilled,
          x: s.x,
          y: s.y,
          a: s.size,
          b: s.size,
          rot: 0,
          opacity: s.opacity,
          color: s.color,
        );
        i++;
      }
    }

    _frame++;
    final interval = (60.0 / _frequency).clamp(10.0, 180.0).round();
    if (_frame % interval == 0) _spawnBurst();
  }
}

class _Spark {
  _Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
  });
  double x, y;
  double vx, vy;
  final double size;
  double opacity;
  final Color color;
}
