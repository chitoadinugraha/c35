import 'dart:math' as math;

import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:flutter/material.dart';

class UiAuthLogo extends StatefulWidget {
  const UiAuthLogo({
    super.key,
    this.size = 104,
    this.compact = false,
    this.onTap,
  });

  final double size;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<UiAuthLogo> createState() => _UiAuthLogoState();
}

class _UiAuthLogoState extends State<UiAuthLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _waveStrength;
  final _rng = math.Random();

  static const _cycle = Duration(milliseconds: 2800);
  static const _holdW = 2600.0;
  static const _riseW = 60.0;
  static const _peakW = 40.0;
  static const _fallW = 100.0;

  double _phaseOffset = 0;
  double _spikeScale = 1;
  double _spikeReach = 1;
  int _waveCount = 6;
  double _lastControllerValue = 0;
  var _hovered = false;
  var _pressed = false;

  double get _iconGlow {
    if (_pressed) return 1;
    if (_hovered) return 0.6;
    return 0;
  }

  double get _cycleTotal => _holdW + _riseW + _peakW + _fallW;
  double get _spikeStart => _holdW / _cycleTotal;

  @override
  void initState() {
    super.initState();
    _randomizeWave();
    _controller = AnimationController(vsync: this, duration: _cycle);

    _waveStrength = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: _holdW),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _riseW,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: _peakW),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: _fallW,
      ),
    ]).animate(_controller);

    _controller.addListener(_onTick);
    _controller.repeat();
  }

  void _onTick() {
    final value = _controller.value;
    if (value < _lastControllerValue) _randomizeWave();
    _lastControllerValue = value;
  }

  void _randomizeWave({bool fromTap = false}) {
    _phaseOffset = _rng.nextDouble() * 2 * math.pi;
    _spikeScale = 0.85 + _rng.nextDouble() * 0.55;
    _waveCount = 3 + _rng.nextInt(6);
    const minReach = 0.55;
    final maxReach = fromTap ? 2.5 : 1.85;
    _spikeReach = minReach + _rng.nextDouble() * (maxReach - minReach);
  }

  void _onTap() {
    _spikeOnTap();
    widget.onTap?.call();
  }

  void _spikeOnTap() {
    setState(() => _randomizeWave(fromTap: true));
    _controller.forward(from: _spikeStart);
  }

  Widget _alienIcon(ColorScheme c, double s, double glow) {
    final iconSize = s * 0.58;
    final iconColor = Color.lerp(c.onSurface, c.primary, glow * 0.9)!;

    return UiAlienIcon(size: iconSize, color: iconColor);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final s = widget.size;
    final pad = widget.compact ? 2.0 : 12.0;

    return SizedBox(
      width: s + pad * 2,
      height: s + pad * 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _iconGlow),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, glow, _) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final strength = _waveStrength.value;
              final phase = _phaseOffset;

              return CustomPaint(
                painter: _WavyRingPainter(
                  waveStrength: strength,
                  wavePhase: phase,
                  spikeScale: _spikeScale,
                  spikeReach: _spikeReach,
                  waveCount: _waveCount,
                  color: c.primary,
                ),
                child: Center(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hovered = true),
                    onExit: (_) => setState(() => _hovered = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _pressed = true),
                      onTapUp: (_) => setState(() => _pressed = false),
                      onTapCancel: () => setState(() => _pressed = false),
                      onTap: _onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: s,
                        height: s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surfaceContainerHigh.withValues(alpha: 0.85),
                          border: Border.all(
                            color: Color.lerp(
                              c.outlineVariant.withValues(alpha: 0.45),
                              c.primary.withValues(alpha: 0.8),
                              glow,
                            )!,
                            width: 1 + glow * 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.12 + strength * 0.16 * _spikeScale),
                              blurRadius: 24 + strength * 8 * _spikeScale,
                              spreadRadius: 1,
                            ),
                            if (glow > 0.01)
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.28 * glow),
                                blurRadius: 20 * glow,
                                spreadRadius: 3 * glow,
                              ),
                          ],
                        ),
                        child: Center(child: _alienIcon(c, s, glow)),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WavyRingPainter extends CustomPainter {
  const _WavyRingPainter({
    required this.waveStrength,
    required this.wavePhase,
    required this.spikeScale,
    required this.spikeReach,
    required this.waveCount,
    required this.color,
  });

  final double waveStrength;
  final double wavePhase;
  final double spikeScale;
  final double spikeReach;
  final int waveCount;
  final Color color;

  static const _strokeWidth = 1.4;
  static const _waveAmplitude = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth - 1;
    final strength = waveStrength;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.14 + strength * 0.18 * spikeScale * spikeReach)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth + 5 + strength * 3 * spikeScale * spikeReach
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + strength * 4 * spikeScale * spikeReach);

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.6 + strength * 0.2 * spikeScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = strength > 0.01 ? StrokeCap.butt : StrokeCap.round;

    if (strength < 0.001) {
      canvas.drawCircle(center, radius, glow);
      canvas.drawCircle(center, radius, stroke);
      return;
    }

    final path = _ringPath(center: center, radius: radius, phase: wavePhase, strength: strength);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  Path _ringPath({
    required Offset center,
    required double radius,
    required double phase,
    required double strength,
  }) {
    final segments = math.max(240, waveCount * 18);
    final amp = _waveAmplitude * spikeScale * spikeReach * strength;
    final path = Path();

    for (var i = 0; i <= segments; i++) {
      final angle = i / segments * 2 * math.pi;
      final wave = _spikeHeight(angle, waveCount, phase) * amp;
      final point = Offset(
        center.dx + (radius + wave) * math.cos(angle),
        center.dy + (radius + wave) * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  double _spikeHeight(double angle, int count, double phase) {
    final t = (angle * count / (2 * math.pi) + phase / (2 * math.pi)) % 1.0;
    final peak = 1.0 - (t * 2 - 1).abs();
    return math.pow(peak, 6.5).toDouble();
  }

  @override
  bool shouldRepaint(covariant _WavyRingPainter old) =>
      old.waveStrength != waveStrength ||
      old.wavePhase != wavePhase ||
      old.spikeScale != spikeScale ||
      old.spikeReach != spikeReach ||
      old.waveCount != waveCount ||
      old.color != color;
}
