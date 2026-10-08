import 'dart:math' as math;
import 'dart:ui';

import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import '../overlay_effect_paint_util.dart';
import '../overlay_effect_particle.dart';
import '../overlay_effect_pointer_frame.dart';

class MatrixRainState {
  MatrixRainState(Map<String, Object?> params) {
    reload(params);
  }

  double densityScale = 1.0;
  Size _size = Size.zero;
  var _density = 25;
  late double _speed;
  late double _fontSize;
  late Color _color;
  var _touchEnabled = true;
  var _touchRadius = 120.0;
  var _glitchIntensity = 0.6;
  var _glitchColumns = 3;
  final _cols = <_MatrixColumn>[];
  double _seed = 0.0;

  static const _alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  void reload(Map<String, Object?> params) {
    final raw = overlayEffectParamInt(params, 'density', 25);
    _density = (raw * densityScale).round().clamp(1, raw);
    _speed = overlayEffectParamDouble(params, 'speed', 6);
    _fontSize = overlayEffectParamDouble(params, 'fontSize', 14);
    _color = effectParseColor(overlayEffectParamString(params, 'color', '#00ff41'));
    _touchEnabled = overlayEffectParamBool(params, 'interaction', true);
    _touchRadius = overlayEffectParamDouble(params, 'touch_radius', 120);
    _glitchIntensity = overlayEffectParamDouble(params, 'glitch_intensity', 60) / 100;
    _glitchColumns = overlayEffectParamInt(params, 'glitch_columns', 3);
    _cols.clear();
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
    _cols.clear();
    final step = (_size.width / _density).clamp(12.0, 999.0);
    for (int i = 0; i < _density; i++) {
      final s = i * 4.98 + 1.23;
      _cols.add(_MatrixColumn(
        x: i * step + (effectRand01(s) - 0.5) * 5.0,
        y: effectRand01(s + 1.0) * -_size.height,
        speed: effectRand01(s + 2.0) * _speed + _speed * 0.5 + 2.0,
        ticksSinceLastChar: 0.0,
        trails: [],
      ));
    }
  }

  String _randomChar() {
    _seed += 0.777;
    final idx = (effectRand01(_seed) * _alphabet.length).floor().clamp(0, _alphabet.length - 1);
    return _alphabet[idx];
  }

  double _glitchForColumn(double colX, Iterable<Offset> pts) {
    if (!_touchEnabled || pts.isEmpty) return 0;
    var glitch = 0.0;
    for (final center in pts) {
      final dx = (colX - center.dx).abs();
      if (dx > _touchRadius) continue;
      final pullT = 1 - (dx / _touchRadius).clamp(0.0, 1.0);
      glitch = math.max(glitch, pullT);
    }
    return glitch * _glitchIntensity;
  }

  void tick(List<double> out, {OverlayEffectPointerFrame? pointers}) {
    if (_size.width <= 0 || _size.height <= 0) return;
    if (_cols.isEmpty) _respawn();
    final h = _size.height;
    final pts = pointers?.pointers.values ?? const <Offset>[];

    for (final col in _cols) {
      final glitch = _glitchForColumn(col.x, pts);
      final speedMul = 1 + glitch * (_glitchColumns * 0.35);
      col.y += col.speed * speedMul;
      col.ticksSinceLastChar += 1.0 + glitch * 2.5;

      if (col.ticksSinceLastChar > 1.8 - glitch) {
        col.trails.add(_TrailChar(y: col.y, char: _randomChar(), opacity: 1.0));
        col.ticksSinceLastChar = 0.0;
      }

      for (int i = 0; i < col.trails.length;) {
        final t = col.trails[i];
        t.opacity -= 0.02 + glitch * 0.01;
        if (t.opacity <= 0.0) {
          col.trails.removeAt(i);
        } else {
          final trailColor = glitch > 0.15
              ? (Color.lerp(_color, const Color(0xFFFFFFFF), glitch * 0.6) ?? _color)
              : _color;
          final offsetX = glitch > 0.1 ? (effectRand01(col.y + i) - 0.5) * glitch * 8 : 0.0;
          effectEmit(
            out,
            kind: effectKindGlyph,
            x: col.x + offsetX,
            y: t.y,
            a: _fontSize,
            b: t.char.codeUnitAt(0).toDouble(),
            rot: 0,
            opacity: t.opacity,
            color: trailColor,
          );
          i++;
        }
      }

      final headChar = _randomChar();
      effectEmit(
        out,
        kind: effectKindGlyph,
        x: col.x,
        y: col.y,
        a: _fontSize,
        b: headChar.codeUnitAt(0).toDouble(),
        rot: 0,
        opacity: 0.7 + glitch * 0.3,
        color: const Color(0xFFFFFFFF),
      );

      if (col.y > h + 100.0) {
        col.y = effectRand01(col.x + col.speed) * -100.0;
        col.speed = effectRand01(col.y) * _speed + _speed * 0.5 + 2.0;
        col.trails.clear();
      }
    }
  }
}

class _TrailChar {
  _TrailChar({required this.y, required this.char, required this.opacity});
  final double y;
  final String char;
  double opacity;
}

class _MatrixColumn {
  _MatrixColumn({
    required this.x,
    required this.y,
    required this.speed,
    required this.ticksSinceLastChar,
    required this.trails,
  });
  final double x;
  double y;
  double speed;
  double ticksSinceLastChar;
  final List<_TrailChar> trails;
}
