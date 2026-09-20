import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Cosmic starry night background with twinkling stars and shooting comets.
class UiStarryBackground extends StatefulWidget {
  const UiStarryBackground({
    super.key,
    this.starCount = 85,
    this.nebulaCenter = const Alignment(0.0, -0.35),
    this.child,
  });

  final int starCount;
  final Alignment nebulaCenter;
  final Widget? child;

  @override
  State<UiStarryBackground> createState() => _UiStarryBackgroundState();
}

class _UiStarryBackgroundState extends State<UiStarryBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _starCycleMs = 8000;

  late final Ticker _repaintTicker;
  late final AnimationController _cometController;
  late final List<_Star> _stars;
  final _rng = math.Random();
  Timer? _cometTimer;
  var _foreground = true;

  _Comet? _currentComet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stars = _generateStars(widget.starCount);

    _repaintTicker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();

    _cometController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _cometController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _scheduleNextComet();
    });

    _scheduleNextComet(initialDelayMs: 800);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_foreground) {
          _foreground = true;
          _scheduleNextComet(initialDelayMs: 600 + _rng.nextInt(1400));
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_foreground) {
          _foreground = false;
          _pauseComets();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _pauseComets() {
    _cometTimer?.cancel();
    _cometTimer = null;
    _cometController.stop();
    _cometController.reset();
    if (_currentComet != null) setState(() => _currentComet = null);
  }

  void _scheduleNextComet({int? initialDelayMs}) {
    _cometTimer?.cancel();
    if (!_foreground) return;
    final delay = initialDelayMs ?? (1600 + _rng.nextInt(3200));
    _cometTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_foreground) return;
      _spawnComet();
    });
  }

  void _spawnComet() {
    if (!_foreground) return;
    final fromLeft = _rng.nextBool();
    final startX = fromLeft ? -0.15 + _rng.nextDouble() * 0.45 : 0.65 + _rng.nextDouble() * 0.45;
    final startY = -0.08 + _rng.nextDouble() * 0.4;
    final angle = fromLeft
        ? (0.5 + _rng.nextDouble() * 0.4) * math.pi / 4
        : (2.35 + _rng.nextDouble() * 0.4) * math.pi / 4;

    final distance = 0.55 + _rng.nextDouble() * 0.4;
    final endX = startX + math.cos(angle) * distance;
    final endY = startY + math.sin(angle) * distance;

    final streakDurationMs = 450 + _rng.nextInt(350);
    _cometController.duration = Duration(milliseconds: streakDurationMs);

    setState(() {
      _currentComet = _Comet(
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        trailLength: 120.0 + _rng.nextDouble() * 90.0,
        thickness: 1.8 + _rng.nextDouble() * 0.8,
      );
    });

    _cometController.forward(from: 0.0);
  }

  List<_Star> _generateStars(int count) {
    final rng = math.Random(42);
    final stars = <_Star>[];
    for (var i = 0; i < count; i++) {
      stars.add(
        _Star(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          size: 0.65 + rng.nextDouble() * 1.15,
          baseAlpha: 0.15 + rng.nextDouble() * 0.55,
          twinkleSpeed: 1 + rng.nextInt(3),
          phase: rng.nextDouble() * 2 * math.pi,
          isHero: rng.nextDouble() < 0.15,
        ),
      );
    }
    return stars;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cometTimer?.cancel();
    _repaintTicker.dispose();
    _cometController.dispose();
    super.dispose();
  }

  double get _starProgress =>
      (DateTime.now().millisecondsSinceEpoch % _starCycleMs) / _starCycleMs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF08080A)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: widget.nebulaCenter,
              radius: 0.95,
              colors: const [
                Color(0x18303848),
                Color(0x0C181822),
                Color(0x0008080A),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _cometController,
          builder: (context, _) {
            return CustomPaint(
              painter: _StarfieldPainter(
                stars: _stars,
                starProgress: _starProgress,
                comet: _cometController.isAnimating ? _currentComet : null,
                cometProgress: _cometController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseAlpha,
    required this.twinkleSpeed,
    required this.phase,
    required this.isHero,
  });

  final double x;
  final double y;
  final double size;
  final double baseAlpha;
  final int twinkleSpeed;
  final double phase;
  final bool isHero;
}

class _Comet {
  const _Comet({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.trailLength,
    required this.thickness,
  });

  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double trailLength;
  final double thickness;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.stars,
    required this.starProgress,
    this.comet,
    this.cometProgress = 0.0,
  });

  final List<_Star> stars;
  final double starProgress;
  final _Comet? comet;
  final double cometProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = starProgress * 2 * math.pi;

    for (final star in stars) {
      final dx = star.x * size.width;
      final dy = star.y * size.height;
      final twinkle = math.sin(t * star.twinkleSpeed + star.phase);
      final alpha = (star.baseAlpha * (0.65 + 0.35 * twinkle)).clamp(0.05, 0.95);
      final color = Colors.white.withValues(alpha: alpha);

      if (star.isHero && alpha > 0.35) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawCircle(Offset(dx, dy), star.size * 1.8, glowPaint);
      }

      final starPaint = Paint()..color = color;
      canvas.drawCircle(Offset(dx, dy), star.size, starPaint);
    }

    if (comet != null && cometProgress > 0.0 && cometProgress < 1.0) {
      _paintComet(canvas, size, comet!, cometProgress);
    }
  }

  void _paintComet(Canvas canvas, Size size, _Comet comet, double progress) {
    final start = Offset(comet.startX * size.width, comet.startY * size.height);
    final end = Offset(comet.endX * size.width, comet.endY * size.height);
    final currentHead = Offset.lerp(start, end, progress)!;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;

    final unitX = dx / length;
    final unitY = dy / length;
    final tailLength = comet.trailLength;
    final tailEnd = Offset(
      currentHead.dx - unitX * tailLength,
      currentHead.dy - unitY * tailLength,
    );

    double overallOpacity = 1.0;
    if (progress < 0.18) {
      overallOpacity = progress / 0.18;
    } else if (progress > 0.72) {
      overallOpacity = (1.0 - progress) / 0.28;
    }
    overallOpacity = overallOpacity.clamp(0.0, 1.0);
    if (overallOpacity <= 0.01) return;

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = comet.thickness
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white.withValues(alpha: 0.95 * overallOpacity),
          const Color(0xFFE0E7FF).withValues(alpha: 0.7 * overallOpacity),
          const Color(0xFF818CF8).withValues(alpha: 0.25 * overallOpacity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(Rect.fromPoints(currentHead, tailEnd));

    canvas.drawLine(tailEnd, currentHead, trailPaint);

    final headGlowPaint = Paint()
      ..color = const Color(0xFFC7D2FE).withValues(alpha: 0.75 * overallOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(currentHead, comet.thickness * 2.5, headGlowPaint);

    final headCorePaint = Paint()
      ..color = Colors.white.withValues(alpha: 1.0 * overallOpacity);
    canvas.drawCircle(currentHead, comet.thickness * 1.05, headCorePaint);
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => true;
}
