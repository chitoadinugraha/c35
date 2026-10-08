import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';

class RainShowerState {
  RainShowerState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 80;
  late double _speed;
  late double _dropScale;
  late bool _hasSplash;
  late Color _color;
  late double _lineWidth;
  late double _lengthBase;
  var _touchEnabled = true;
  var _influenceR = 165.0;
  var _orbitSize = 47.0;
  var _swirlStrength = 0.4;
  var _pullStrength = 0.45;
  var _clearRatio = 0.52;
  var _belowMargin = 10.0;
  final _drops = <_Drop>[];
  final _splashes = <_Splash>[];

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 80);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 14);
    _dropScale = overlayEffectParamDouble(params, 'size', 2.25);
    _hasSplash = overlayEffectParamBool(params, 'splash', true);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#aedbf0'));
    _lineWidth = 1.2 + _dropScale * 0.8;
    _lengthBase = 18 + _dropScale * 12;
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _influenceR = overlayEffectParamDouble(params, 'touch_radius', 165);
    _orbitSize = overlayEffectParamDouble(params, 'orbit_size', 47);
    _swirlStrength = overlayEffectParamDouble(params, 'swirl_speed', 40) / 100;
    _pullStrength = overlayEffectParamDouble(params, 'pull_strength', 45) / 100;
    _clearRatio = overlayEffectParamDouble(params, 'clear_size', 52) / 100;
    _belowMargin = overlayEffectParamDouble(params, 'touch_below', 10);
    _splashes.clear();
    _drops.clear();
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
    _splashes.clear();
    _drops
      ..clear()
      ..addAll(List.generate(_density, _spawnDrop));
  }

  _Drop _spawnDrop(int i) {
    final seed = i * 2.718;
    final w = _size.width;
    final h = _size.height;
    final fall = effectRand01(seed + 3) * _speed + _speed * 0.7;
    return _Drop(
      x: effectRand01(seed) * w,
      y: effectRand01(seed + 1) * -h,
      length: effectRand01(seed + 2) * _lengthBase + _lengthBase * 0.6,
      speed: fall,
      opacity: effectRand01(seed + 4) * 0.35 + 0.2,
      vy: fall,
      vx: -0.35,
    );
  }

  double get _ringR => _orbitSize + _dropScale * 2;
  double get _clearR => _ringR * _clearRatio;

  bool _belowTouch(Offset center, _Drop drop) => drop.y > center.dy + _belowMargin;

  bool _inClearZone(Offset center, _Drop drop) {
    if (_belowTouch(center, drop)) return false;
    final dx = drop.x - center.dx;
    final dy = drop.y - center.dy;
    return dx * dx + dy * dy < _clearR * _clearR;
  }

  void _simulateDrop(_Drop drop, Map<int, Offset> pointerMap) {
    drop.vy += (_speed * 0.82 - drop.vy) * 0.07;
    drop.vx += (-0.35 - drop.vx) * 0.05;

    if (!_touchEnabled || pointerMap.isEmpty) {
      drop
        ..x += drop.vx
        ..y += drop.vy
        ..vx *= 0.96
        ..vy *= 0.985;
      return;
    }

    final influenceR = _influenceR;
    final ringR = _ringR;
    final clearR = _clearR;
    final swirl = _swirlStrength;
    final pull = _pullStrength;

    for (final entry in pointerMap.entries) {
      final spin = entry.key.isEven ? 1.0 : -1.0;
      final center = entry.value;
      if (_belowTouch(center, drop)) continue;

      final dx = center.dx - drop.x;
      final dy = center.dy - drop.y;
      final dist2 = dx * dx + dy * dy;
      if (dist2 < 1 || dist2 > influenceR * influenceR) continue;

      final dist = math.sqrt(dist2);
      final nx = dx / dist;
      final ny = dy / dist;
      final tx = -ny * spin;
      final ty = nx * spin;

      if (dist < clearR) {
        drop
          ..vx += nx * 1.8 * pull + tx * 0.15 * swirl
          ..vy += ny * 0.45 * pull
          ..vy *= 1 - 0.12 * swirl;
        continue;
      }

      final ringPull = (dist - ringR) / ringR;
      final pullT = (1 - (dist / influenceR).clamp(0.0, 1.0));
      final pullAmt = pullT * pullT;
      final swirlAmt = (1 - (ringPull.abs()).clamp(0.0, 1.0));
      final swirl2 = swirlAmt * swirlAmt;

      drop.vx += (-nx * ringPull * 1.1 + tx * swirl2 * 1.4 + nx * pullAmt * 0.5) * pull;
      drop.vy += (-ny * ringPull * 0.35 + ty * swirl2 * 0.85 + ny * pullAmt * 0.15) * pull;

      if (drop.y < center.dy - 6) {
        drop
          ..vx += nx * pullAmt * 0.65 * pull
          ..vy += pullAmt * 0.1 * pull;
      }

      final stick = swirl2 * 0.7 + pullAmt * 0.2;
      drop.vy *= 1 - stick * 0.38 * swirl;
    }

    drop
      ..x += drop.vx
      ..y += drop.vy
      ..vx *= 0.96
      ..vy *= 0.985;
  }

  bool _hideDrop(_Drop drop, Iterable<Offset> pts) {
    if (!_touchEnabled) return false;
    for (final center in pts) {
      if (_inClearZone(center, drop)) return true;
    }
    return false;
  }

  void _emitDrop(List<double> out, _Drop drop) {
    final sp = math.sqrt(drop.vx * drop.vx + drop.vy * drop.vy);
    final tailDx = sp < 0.6 ? -_dropScale * 1.5 : (drop.vx / sp) * drop.length * 0.55;
    final tailDy = sp < 0.6 ? drop.length : (drop.vy / sp) * drop.length * 0.55;
    effectEmit(
      out,
      kind: effectKindLine,
      x: drop.x,
      y: drop.y,
      a: drop.x + tailDx,
      b: drop.y + tailDy,
      rot: _lineWidth,
      opacity: drop.opacity,
      color: _color,
    );
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_drops.isEmpty) _respawn();

    final w = _size.width;
    final h = _size.height;
    final pointerMap = _touchEnabled ? (pointers?.pointers ?? const <int, Offset>{}) : const <int, Offset>{};
    final pts = pointerMap.values;

    for (final drop in _drops) {
      _simulateDrop(drop, pointerMap);
      if (!_hideDrop(drop, pts)) _emitDrop(out, drop);
      if (drop.y > h - 10) {
        if (_hasSplash && _splashes.length < 50) {
          _splashes.add(
            _Splash(
              x: drop.x,
              y: h - 5,
              radius: 1,
              maxRadius: effectRand01(drop.y) * (6 + _dropScale * 3) + 4 + _dropScale * 2,
              opacity: 0.5,
            ),
          );
        }
        final fall = effectRand01(drop.length) * _speed + _speed * 0.7;
        drop
          ..y = effectRand01(drop.x) * -40
          ..x = effectRand01(drop.y) * w
          ..speed = fall
          ..vy = fall
          ..vx = -0.35;
      }
    }

    for (var i = 0; i < _splashes.length;) {
      final splash = _splashes[i];
      effectEmit(
        out,
        kind: effectKindEllipse,
        x: splash.x,
        y: splash.y,
        a: splash.radius,
        b: splash.radius * 0.3,
        rot: 0.8 + _dropScale * 0.4,
        opacity: splash.opacity,
        color: _color,
      );
      splash
        ..radius += 0.5
        ..opacity -= 0.03;
      if (splash.opacity <= 0 || splash.radius >= splash.maxRadius) {
        _splashes.removeAt(i);
      } else {
        i++;
      }
    }
  }
}

class _Drop {
  _Drop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
    required this.vx,
    required this.vy,
  });

  double x;
  double y;
  double length;
  double speed;
  double opacity;
  double vx;
  double vy;
}

class _Splash {
  _Splash({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.opacity,
  });

  final double x;
  final double y;
  double radius;
  final double maxRadius;
  double opacity;
}
