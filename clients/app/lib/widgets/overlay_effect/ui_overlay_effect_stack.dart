import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'overlay_effect_host.dart';
import 'overlay_effect_particle_painter.dart';
import 'overlay_effect_pointer_hub.dart';

/// Full-viewport overlay effect layers behind guest UI chrome.
/// Sim runs on a background isolate (native) / throttled local loop (web).
class UiOverlayEffectStack extends StatefulWidget {
  const UiOverlayEffectStack({
    super.key,
    required this.effects,
    this.pointerHub,
  });

  final List<SiteOverlayEffectDraft> effects;
  final OverlayEffectPointerHub? pointerHub;

  @override
  State<UiOverlayEffectStack> createState() => _UiOverlayEffectStackState();
}

class _UiOverlayEffectStackState extends State<UiOverlayEffectStack> {
  late final OverlayEffectHost _host = OverlayEffectHost();
  var _booted = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await _host.start(effects: widget.effects, pointerHub: widget.pointerHub);
    if (mounted) setState(() => _booted = true);
  }

  @override
  void didUpdateWidget(covariant UiOverlayEffectStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_booted) return;
    if (!identical(oldWidget.pointerHub, widget.pointerHub) ||
        !_effectsEqual(oldWidget.effects, widget.effects)) {
      _host.syncEffects(widget.effects);
    }
  }

  bool _effectsEqual(List<SiteOverlayEffectDraft> a, List<SiteOverlayEffectDraft> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.id != y.id || x.presetId != y.presetId || x.active != y.active) return false;
      if (x.params.length != y.params.length) return false;
      for (final e in x.params.entries) {
        if (y.params[e.key] != e.value) return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.effects.where((e) => e.active && overlayEffectPresetRunnable(e.presetId));
    if (active.isEmpty) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _host.resize(size);
            });
            return IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: OverlayEffectParticlePainter(host: _host),
                  isComplex: true,
                  willChange: true,
                  size: size,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
