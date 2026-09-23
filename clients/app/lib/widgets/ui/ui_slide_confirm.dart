import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Slide-to-confirm — drag the thumb (or slide on the track) fully across to confirm.
class UiSlideConfirm extends StatefulWidget {
  const UiSlideConfirm({
    super.key,
    required this.onConfirm,
    this.label = 'Slide to confirm',
    this.doneLabel = 'Confirmed',
    this.enabled = true,
    this.height = 52,
    this.color,
  });

  final FutureOr<void> Function() onConfirm;
  final String label;
  final String doneLabel;
  final bool enabled;
  final double height;
  final Color? color;

  @override
  State<UiSlideConfirm> createState() => _UiSlideConfirmState();
}

class _UiSlideConfirmState extends State<UiSlideConfirm> with SingleTickerProviderStateMixin {
  static const _inset = 4.0;
  static const _completeAt = 0.9;

  late final AnimationController _snap;
  var _progress = 0.0;
  var _dragging = false;
  var _fired = false;
  var _busy = false;
  var _hapticHalf = false;

  double get _thumb => widget.height - _inset * 2;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addListener(() {
        if (_dragging || _fired) return;
        setState(() => _progress = _snap.value);
      });
  }

  @override
  void didUpdateWidget(covariant UiSlideConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && (_dragging || _progress > 0) && !_busy) _reset(animate: false);
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  double _travel(double width) => (width - _inset * 2 - _thumb).clamp(1.0, double.infinity);

  void _reset({bool animate = true}) {
    _dragging = false;
    _fired = false;
    _busy = false;
    _hapticHalf = false;
    if (!animate) {
      _snap.stop();
      setState(() => _progress = 0);
      return;
    }
    _snap.value = _progress;
    _snap.animateTo(0, curve: Curves.easeOutCubic);
  }

  Future<void> _complete() async {
    if (_fired) return;
    _fired = true;
    _busy = true;
    _dragging = false;
    _progress = 1;
    HapticFeedback.mediumImpact();
    setState(() {});
    try {
      await Future.sync(widget.onConfirm);
    } catch (e, st) {
      lError('slide confirm: $e\n$st');
      if (mounted) _reset(animate: false);
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  void _onDragStart(DragStartDetails _) {
    if (!widget.enabled || _fired) return;
    _snap.stop();
    _dragging = true;
    _hapticHalf = false;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails d, double travel) {
    if (!widget.enabled || _fired || !_dragging) return;
    final next = (_progress + d.delta.dx / travel).clamp(0.0, 1.0);
    if (!_hapticHalf && next >= 0.5) {
      _hapticHalf = true;
      HapticFeedback.lightImpact();
    }
    setState(() => _progress = next);
  }

  void _onDragEnd(DragEndDetails _) {
    if (!widget.enabled || _fired) return;
    if (_progress >= _completeAt) {
      unawaited(_complete());
      return;
    }
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = widget.color ?? cs.primary;
    const onFill = Colors.white;
    final track = cs.surfaceContainerHigh;

    return Opacity(
      opacity: widget.enabled || _fired ? 1 : 0.45,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final travel = _travel(w);
          final thumbLeft = _inset + _progress * travel;
          final fillW = (thumbLeft + _thumb).clamp(0.0, w);
          final labelOpacity = (1.0 - _progress * 1.4).clamp(0.0, 1.0);

          return Semantics(
            button: true,
            enabled: widget.enabled && !_fired,
            label: widget.label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: widget.enabled && !_fired ? _onDragStart : null,
              onHorizontalDragUpdate: widget.enabled && !_fired ? (d) => _onDragUpdate(d, travel) : null,
              onHorizontalDragEnd: widget.enabled && !_fired ? _onDragEnd : null,
              onHorizontalDragCancel: widget.enabled && !_fired ? () => _reset() : null,
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    border: Border.all(color: fill.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.height / 2 - 1),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: fillW,
                          child: ColoredBox(color: fill),
                        ),
                        if (!_fired)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: labelOpacity,
                                child: Row(
                                  children: [
                                    SizedBox(width: _thumb + _inset + 4),
                                    Expanded(
                                      child: Text(
                                        widget.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: cs.onSurface.withValues(alpha: 0.72),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Icon(Icons.keyboard_double_arrow_right_rounded, size: 22, color: fill.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_fired)
                          Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: onFill),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_rounded, size: 22, color: onFill),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.doneLabel,
                                        style: const TextStyle(color: onFill, fontWeight: FontWeight.w800, fontSize: 15),
                                      ),
                                    ],
                                  ),
                          ),
                        if (!_fired)
                          Positioned(
                            left: thumbLeft,
                            top: _inset,
                            child: Material(
                              color: fill,
                              elevation: _dragging ? 8 : 4,
                              shadowColor: Colors.black.withValues(alpha: 0.4),
                              shape: const CircleBorder(),
                              child: SizedBox(
                                width: _thumb,
                                height: _thumb,
                                child: const Icon(Icons.chevron_right_rounded, color: onFill, size: 28),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
