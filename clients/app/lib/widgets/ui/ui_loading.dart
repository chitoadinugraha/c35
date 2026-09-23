import 'dart:async';
import 'dart:math' as math;

import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:flutter/material.dart';

const _loadingFg = Color(0xFFA1A1AA);

String uiLoadingElapsedLabel(int ms, {required bool compact}) {
  final safe = ms < 0 ? 0 : ms;
  if (safe >= 60000) {
    final m = safe ~/ 60000;
    final s = (safe % 60000) ~/ 1000;
    return '${m}m ${s}s';
  }
  if (safe >= 1000) {
    if (compact) return '${safe ~/ 1000}s';
    return '${safe ~/ 1000}.${(safe % 1000).toString().padLeft(3, '0')}s';
  }
  return compact ? '${safe}ms' : '0.${safe.toString().padLeft(3, '0')}s';
}

class UILoadingIndicator extends StatelessWidget {
  const UILoadingIndicator({
    super.key,
    this.size = 44,
    this.strokeWidth = 2.5,
    this.iconSize,
    this.color = _loadingFg,
  });

  final double size;
  final double strokeWidth;
  final double? iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = iconSize ?? (size * 0.41).clamp(12.0, 22.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
          UiAlienIcon(size: mark, color: color),
        ],
      ),
    );
  }
}

class UILoading extends StatefulWidget {
  const UILoading({super.key, this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  State<UILoading> createState() => _UILoadingState();
}

class _UILoadingState extends State<UILoading> {
  late final Stopwatch _sw;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch();
    _timer = Timer.periodic(const Duration(milliseconds: 50), _onTick);
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible) {
      if (!_sw.isRunning) _sw.start();
      setState(() {});
    } else if (_sw.isRunning) {
      _sw
        ..stop()
        ..reset();
    }
  }

  int get _ms => _sw.elapsedMilliseconds;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      color: _loadingFg,
      fontSize: widget.compact ? 12 : 13,
      height: 1.35,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final content = ExcludeSemantics(
      child: RepaintBoundary(
        child: widget.compact ? _compact(muted) : _page(muted),
      ),
    );
    if (widget.compact) return content;
    return Center(child: content);
  }

  Widget _page(TextStyle muted) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UILoadingIndicator(),
          const SizedBox(height: 16),
          Text(uiLoadingElapsedLabel(_ms, compact: false), style: muted),
          if (widget.message != null) ...[
            const SizedBox(height: 8),
            Text(widget.message!, style: muted, textAlign: TextAlign.center),
          ],
        ],
      );

  Widget _compact(TextStyle muted) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LoadingDots(tMs: _ms),
          const SizedBox(height: 8),
          Text('${widget.message ?? 'Loading'} ${uiLoadingElapsedLabel(_ms, compact: true)}', style: muted, textAlign: TextAlign.center),
        ],
      );
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.tMs});

  final int tMs;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final y = math.sin((tMs / 160) + i * 0.9) * 3.5;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.translate(
                offset: Offset(0, y),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: _loadingFg, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        ),
      );
}

/// Animated 3-dot thinking indicator that floats smoothly up and down.
class UiThinkingDots extends StatefulWidget {
  const UiThinkingDots({
    super.key,
    this.color,
    this.size = 3.5,
    this.spacing = 2.0,
    this.bounceHeight = 2.5,
  });

  final Color? color;
  final double size;
  final double spacing;
  final double bounceHeight;

  @override
  State<UiThinkingDots> createState() => _UiThinkingDotsState();
}

class _UiThinkingDotsState extends State<UiThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? _loadingFg;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value * 2 * math.pi;
          return SizedBox(
            height: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(3, (i) {
                final y = math.sin(t + i * 0.9) * widget.bounceHeight;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.spacing),
                  child: Transform.translate(
                    offset: Offset(0, -y),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

