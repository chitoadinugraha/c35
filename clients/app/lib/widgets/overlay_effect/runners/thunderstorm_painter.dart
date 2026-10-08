import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';

class ThunderstormState {
  ThunderstormState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 100;
  late double _speed;
  late double _dropScale;
  late Color _color;
  late double _flashRate;
  var _touchEnabled = true;
  var _touchRadius = 100.0;
  var _chargeRate = 0.45;
  var _strikeIntensity = 0.75;
  final _drops = <_RainDrop>[];

  bool _flashActive = false;
  double _flashTimer = 0.0;
  final _lightningPoints = <Offset>[];
  double _seed = 0.0;
  var _touchCharge = 0.0;

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 100);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 15);
    _dropScale = overlayEffectParamDouble(params, 'size', 2.5);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#7faec6'));
    _flashRate = overlayEffectParamDouble(params, 'flashFrequency', 4);
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 100);
    _chargeRate = overlayEffectParamDouble(params, 'charge_rate', 45) / 100;
    _strikeIntensity = overlayEffectParamDouble(params, 'strike_intensity', 75) / 100;
    _drops.clear();
    _flashActive = false;
    _lightningPoints.clear();
    _touchCharge = 0;
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
    _drops.clear();
    for (int i = 0; i < _density; i++) {
      final s = i * 2.718;
      _drops.add(_RainDrop(
        x: effectRand01(s) * _size.width,
        y: effectRand01(s + 1) * -_size.height,
        length: effectRand01(s + 2) * 15.0 + 10.0,
        speed: effectRand01(s + 3) * _speed + _speed * 0.7,
        opacity: effectRand01(s + 4) * 0.35 + 0.15,
      ));
    }
  }

  void _generateLightningAt(double startX) {
    _lightningPoints.clear();
    if (_size.width <= 0) return;
    _seed += 2.456;
    var curX = startX.clamp(0.0, _size.width);
    var curY = 0.0;
    _lightningPoints.add(Offset(curX, curY));
    while (curY < _size.height) {
      _seed += 1.15;
      final dx = (effectRand01(_seed) - 0.5) * 60.0;
      final dy = effectRand01(_seed + 1) * 35.0 + 15.0;
      curX += dx;
      curY += dy;
      _lightningPoints.add(Offset(curX, curY));
    }
  }

  void _generateLightning() => _generateLightningAt(effectRand01(_seed) * _size.width);

  void _handleTouch(OverlayEffectPointerFrame frame) {
    if (!_touchEnabled) return;
    if (frame.pointers.isNotEmpty) {
      _touchCharge = (_touchCharge + _chargeRate * 0.08).clamp(0.0, 1.0);
    } else {
      _touchCharge *= 0.96;
    }
    for (final pos in frame.ups) {
      if (_touchCharge > 0.25) {
        _flashActive = true;
        _flashTimer = (8 + _strikeIntensity * 12).clamp(4.0, 20.0);
        _generateLightningAt(pos.dx);
      }
      _touchCharge = 0;
    }
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_drops.isEmpty) _respawn();
    if (pointers != null) _handleTouch(pointers);

    if (_flashActive) {
      _flashTimer -= 1.0;
      if (_flashTimer <= 0.0) {
        _flashActive = false;
        _lightningPoints.clear();
      }
    } else {
      _seed += 1.34;
      final chance = 0.005 * (_flashRate / 4);
      if (effectRand01(_seed) < chance) {
        _flashActive = true;
        _flashTimer = (effectRand01(_seed + 1.0) * 8.0).floorToDouble() + 4.0;
        _generateLightning();
      }
    }

    final w = _size.width;
    final h = _size.height;
    final stroke = 1.0 + _dropScale * 0.5;

    if (_flashActive) {
      _seed += 0.88;
      final flashOpacity = effectRand01(_seed) * 0.15 * _strikeIntensity + 0.05;
      effectEmit(
        out,
        kind: effectKindEllipseFilled,
        x: w * 0.5,
        y: h * 0.5,
        a: w,
        b: h,
        rot: 0,
        opacity: flashOpacity,
        color: const Color(0xFFFFFFFF),
      );
    }

    if (_flashActive && _lightningPoints.length > 1) {
      final boltW = 2.0 + _strikeIntensity * 2;
      final boltOp = 0.5 + _strikeIntensity * 0.4;
      for (int i = 0; i < _lightningPoints.length - 1; i++) {
        final a = _lightningPoints[i];
        final b = _lightningPoints[i + 1];
        effectEmit(
          out,
          kind: effectKindLine,
          x: a.dx,
          y: a.dy,
          a: b.dx,
          b: b.dy,
          rot: boltW,
          opacity: boltOp,
          color: const Color(0xFFE8F5E9),
        );
      }
    }

    if (_touchEnabled && pointers != null && pointers.pointers.isNotEmpty) {
      final chargeOp = 0.04 + _touchCharge * 0.12;
      final d = _touchRadius * 0.5;
      for (final center in pointers.pointers.values) {
        effectEmit(
          out,
          kind: effectKindEllipseFilled,
          x: center.dx,
          y: center.dy,
          a: d,
          b: d,
          rot: 0,
          opacity: chargeOp,
          color: const Color(0xFFFFFFFF),
        );
      }
    }

    for (final drop in _drops) {
      effectEmit(
        out,
        kind: effectKindLine,
        x: drop.x,
        y: drop.y,
        a: drop.x - 2.5,
        b: drop.y + drop.length,
        rot: stroke,
        opacity: drop.opacity,
        color: _color,
      );
      drop.y += drop.speed;
      drop.x -= 0.15;
      if (drop.y > h + 10) {
        drop.x = effectRand01(drop.x + drop.y) * w;
        drop.y = -20;
        drop.speed = effectRand01(drop.length) * _speed + _speed * 0.7;
      }
    }
  }
}

class _RainDrop {
  _RainDrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
  });
  double x, y;
  final double length;
  double speed;
  final double opacity;
}
