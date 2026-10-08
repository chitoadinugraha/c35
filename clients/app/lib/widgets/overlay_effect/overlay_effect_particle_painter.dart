import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'overlay_effect_host.dart';
import 'overlay_effect_particle.dart';

/// Draw-only painter — reads the live particle buffer from [host] each paint.
class OverlayEffectParticlePainter extends CustomPainter {
  OverlayEffectParticlePainter({
    required this.host,
  }) : super(repaint: host);

  final OverlayEffectHost host;

  static final _leafPath = _buildLeafPath();
  static final _heartPath = _buildHeartPath();
  static final _sakuraPath = _buildSakuraPath();
  static final _moonPath = _buildMoonPath();
  static final _glyphCache = <String, TextPainter>{};

  TextPainter _glyph(String ch, double size, Color color) {
    final qAlpha = (color.a * 5).round();
    final key = '$ch-${size.round()}-${color.toARGB32() & 0xFFFFFF}-$qAlpha';
    return _glyphCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: size,
            color: color.withValues(alpha: (qAlpha / 5).clamp(0.0, 1.0)),
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final particles = host.particles;
    final count = host.count;
    final simplifyShapes = host.simplifyShapes;
    if (count <= 0) return;
    if (_glyphCache.length > 256) _glyphCache.clear();
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final n = count.clamp(0, particles.length ~/ effectParticleStride);
    for (var i = 0; i < n; i++) {
      final o = i * effectParticleStride;
      final kind = particles[o];
      final x = particles[o + 1];
      final y = particles[o + 2];
      final a = particles[o + 3];
      final b = particles[o + 4];
      final rot = particles[o + 5];
      final opacity = particles[o + 6].clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;
      final color = _colorFromWire(particles[o + 7]).withValues(alpha: opacity);

      if (kind == effectKindLine) {
        stroke
          ..color = color
          ..strokeWidth = (rot > 0 ? rot : 1.5).clamp(0.5, 8.0);
        canvas.drawLine(Offset(x, y), Offset(a, b), stroke);
        continue;
      }

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(
        kind == effectKindEllipse || kind == effectKindEllipseFilled ? _ellipseAngle(a, b, rot) : rot,
      );

      if (kind == effectKindMoon) {
        fill.color = color;
        canvas.scale((a > 0 ? a : 12) / 12.0);
        canvas.drawPath(_moonPath, fill);
      } else if (kind == effectKindGlyph) {
        final code = b.round();
        if (code >= 32 && code < 0x110000) {
          final tp = _glyph(String.fromCharCode(code), (a > 0 ? a : 14).clamp(8.0, 48.0).toDouble(), color);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        } else {
          fill.color = color;
          canvas.scale((a > 0 ? a : 14) / 14.0);
          canvas.drawPath(_heartPath, fill);
        }
      } else if (kind == effectKindEllipse || kind == effectKindEllipseFilled) {
        final ra = (a / 2).clamp(0.5, 400.0);
        final rb = ((b > 0 ? b : a) / 2).clamp(0.5, 400.0);
        final rect = Rect.fromCenter(center: Offset.zero, width: ra * 2, height: rb * 2);
        if (kind == effectKindEllipseFilled) {
          fill.color = color;
          canvas.drawOval(rect, fill);
        } else {
          stroke
            ..color = color
            ..strokeWidth = _ellipseStroke(a, b, rot);
          canvas.drawOval(rect, stroke);
        }
      } else if (kind == effectKindSakura) {
        fill.color = color;
        canvas.scale((a > 0 ? a : 10) / 10.0);
        canvas.drawPath(_sakuraPath, fill);
      } else if (kind == effectKindLeaf) {
        fill.color = color;
        canvas.scale((a > 0 ? a : 14) / 14.0);
        canvas.drawPath(_leafPath, fill);
        if (!simplifyShapes) {
          stroke
            ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity * 0.25)
            ..strokeWidth = 0.7;
          canvas.drawLine(const Offset(0, 10.5), const Offset(0, -11.2), stroke);
        }
      } else {
        fill.color = color;
        canvas.drawCircle(Offset.zero, (a / 2).clamp(0.5, 200.0), fill);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant OverlayEffectParticlePainter oldDelegate) => oldDelegate.host != host;

  static double _ellipseAngle(double a, double b, double rot) {
    final circleLike = (a - b).abs() <= (a > b ? a : b) * 0.12;
    if (circleLike && rot > 0 && rot <= 6) return 0;
    return rot;
  }

  static double _ellipseStroke(double a, double b, double rot) {
    final circleLike = (a - b).abs() <= (a > b ? a : b) * 0.12;
    if (circleLike && rot > 0 && rot <= 6) return rot.clamp(0.5, 6.0);
    return 1.2;
  }

  static Color _colorFromWire(double f) {
    final n = f.round();
    if (n <= 0) return const Color(0xFFFFFFFF);
    final r = (n >> 16) & 0xff;
    final g = (n >> 8) & 0xff;
    final b = n & 0xff;
    if (r + g + b < 12) return const Color(0xFFFFFFFF);
    return Color.fromARGB(255, r, g, b);
  }

  static Path _buildLeafPath() {
    const r = 14.0;
    return Path()
      ..moveTo(0, -r)
      ..lineTo(-r * 0.2, -r * 0.5)
      ..lineTo(-r * 0.4, -r * 0.65)
      ..lineTo(-r * 0.3, -r * 0.35)
      ..lineTo(-r * 0.75, -r * 0.3)
      ..lineTo(-r * 0.45, -r * 0.05)
      ..lineTo(-r * 0.65, r * 0.15)
      ..lineTo(-r * 0.35, r * 0.3)
      ..lineTo(-r * 0.15, r * 0.5)
      ..lineTo(0, r * 0.75)
      ..lineTo(r * 0.15, r * 0.5)
      ..lineTo(r * 0.35, r * 0.3)
      ..lineTo(r * 0.65, r * 0.15)
      ..lineTo(r * 0.45, -r * 0.05)
      ..lineTo(r * 0.75, -r * 0.3)
      ..lineTo(r * 0.3, -r * 0.35)
      ..lineTo(r * 0.4, -r * 0.65)
      ..lineTo(r * 0.2, -r * 0.5)
      ..close();
  }

  static Path _buildHeartPath() {
    const s = 7.0;
    return Path()
      ..moveTo(0, -s * 0.3)
      ..cubicTo(-s * 0.8, -s * 1.0, -s * 1.6, -s * 0.2, 0, s * 0.9)
      ..cubicTo(s * 1.6, -s * 0.2, s * 0.8, -s * 1.0, 0, -s * 0.3)
      ..close();
  }

  static Path _buildSakuraPath() {
    const r = 5.0;
    final path = Path();
    for (var p = 0; p < 5; p++) {
      final ang = (p / 5) * math.pi * 2;
      path.addOval(Rect.fromCenter(
        center: Offset(math.cos(ang) * r * 0.35, math.sin(ang) * r * 0.35),
        width: r * 0.9,
        height: r * 0.44,
      ));
    }
    return path;
  }

  static Path _buildMoonPath() {
    const r = 12.0;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(r * 1.1, 0, 0, r)
      ..quadraticBezierTo(r * 0.35, 0, 0, -r)
      ..close();
  }
}
