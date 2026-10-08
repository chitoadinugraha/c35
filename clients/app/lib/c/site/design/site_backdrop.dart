import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'site_color.dart';
import 'site_design_models.dart';
import 'site_theme.dart';

class SiteBackdropParam {
  const SiteBackdropParam({
    required this.key,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  final String key;
  final String label;
  final double min;
  final double max;
  final double step;
  final double defaultValue;
}

class SiteBackdropPreset {
  const SiteBackdropPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.params,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<SiteBackdropParam> params;
}

const _intensity = SiteBackdropParam(key: 'intensity', label: 'Intensity', min: 0.1, max: 1, step: 0.05, defaultValue: 0.55);
const _softness = SiteBackdropParam(key: 'softness', label: 'Softness', min: 0.2, max: 1, step: 0.05, defaultValue: 0.7);
const _scale = SiteBackdropParam(key: 'scale', label: 'Scale', min: 0.5, max: 1.6, step: 0.05, defaultValue: 1);

const siteBackdropPresets = <SiteBackdropPreset>[
  SiteBackdropPreset(
    id: 'none',
    name: 'None',
    description: 'No ambient layer',
    icon: Icons.block,
    params: [],
  ),
  SiteBackdropPreset(
    id: 'glow',
    name: 'Glow',
    description: 'Soft radial light',
    icon: Icons.wb_sunny_outlined,
    params: [_intensity, _softness, _scale],
  ),
  SiteBackdropPreset(
    id: 'mesh',
    name: 'Mesh',
    description: 'Overlapping color blobs',
    icon: Icons.bubble_chart_outlined,
    params: [_intensity, _scale],
  ),
  SiteBackdropPreset(
    id: 'grain',
    name: 'Grain',
    description: 'Film texture',
    icon: Icons.texture,
    params: [
      SiteBackdropParam(key: 'intensity', label: 'Intensity', min: 0.05, max: 0.6, step: 0.05, defaultValue: 0.22),
    ],
  ),
  SiteBackdropPreset(
    id: 'diamond',
    name: 'Diamond',
    description: 'Faceted crystal light',
    icon: Icons.diamond_outlined,
    params: [_intensity, _softness, _scale],
  ),
  SiteBackdropPreset(
    id: 'aurora',
    name: 'Aurora',
    description: 'Northern light ribbons',
    icon: Icons.nights_stay_outlined,
    params: [_intensity, _softness, _scale],
  ),
];

SiteBackdropPreset siteBackdropPresetGet(String id) =>
    siteBackdropPresets.firstWhere((p) => p.id == id, orElse: () => siteBackdropPresets.first);

String siteBackdropNormalizeId(String? id) {
  if (id == null || id.isEmpty) return 'none';
  return siteBackdropPresets.any((p) => p.id == id) ? id : 'none';
}

Map<String, double> siteBackdropDefaultParams(String presetId) {
  final preset = siteBackdropPresetGet(siteBackdropNormalizeId(presetId));
  return {for (final p in preset.params) p.key: p.defaultValue};
}

Map<String, double> siteBackdropParamsResolve(SiteBackdropDraft style) {
  final id = siteBackdropNormalizeId(style.id);
  final defaults = siteBackdropDefaultParams(id);
  final preset = siteBackdropPresetGet(id);
  return {
    for (final p in preset.params) p.key: (style.params[p.key] ?? defaults[p.key] ?? p.defaultValue).toDouble(),
  };
}

bool siteBackdropIsCustom(SiteBackdropDraft style) {
  final id = siteBackdropNormalizeId(style.id);
  if (style.color.trim().isNotEmpty) return true;
  final defaults = siteBackdropDefaultParams(id);
  final resolved = siteBackdropParamsResolve(style);
  for (final p in siteBackdropPresetGet(id).params) {
    if ((resolved[p.key] ?? p.defaultValue) != (defaults[p.key] ?? p.defaultValue)) return true;
  }
  return false;
}

String siteBackdropSubtitle(SiteBackdropDraft style) {
  final preset = siteBackdropPresetGet(siteBackdropNormalizeId(style.id));
  if (preset.id == 'none') return preset.name;
  if (siteBackdropIsCustom(style)) {
    final intensity = ((siteBackdropParamsResolve(style)['intensity'] ?? 0.55) * 100).round();
    return '${preset.name} · $intensity%';
  }
  return preset.name;
}

Color siteBackdropAccent({required SiteBackdropDraft style, required SiteThemeTokens theme}) {
  final raw = style.color.trim();
  if (raw.isNotEmpty) return siteColorStopsParse(raw).first;
  return theme.primary;
}

/// Ambient backdrop behind guest preview content.
Widget siteBackdropLayer({
  required SiteBackdropDraft style,
  required SiteThemeTokens theme,
  required Widget child,
}) {
  final id = siteBackdropNormalizeId(style.id);
  if (id == 'none') return child;
  final p = siteBackdropParamsResolve(style);
  final intensity = (p['intensity'] ?? 0.55).clamp(0.0, 1.0);
  final softness = (p['softness'] ?? 0.7).clamp(0.0, 1.0);
  final scale = (p['scale'] ?? 1.0).clamp(0.4, 2.0);
  final accent = siteBackdropAccent(style: style, theme: theme);
  final secondary = Color.lerp(accent, theme.onSurfaceVariant, 0.35) ?? theme.onSurfaceVariant;

  return Stack(
    fit: StackFit.expand,
    children: [
      switch (id) {
        'glow' => _BackdropGlow(accent: accent, intensity: intensity, softness: softness, scale: scale),
        'mesh' => _BackdropMesh(accent: accent, secondary: secondary, intensity: intensity, scale: scale),
        'grain' => _BackdropGrain(intensity: intensity, isDark: theme.isDark),
        'diamond' => _BackdropDiamond(accent: accent, secondary: secondary, intensity: intensity, softness: softness, scale: scale),
        'aurora' => _BackdropAurora(accent: accent, secondary: secondary, intensity: intensity, softness: softness, scale: scale),
        _ => const SizedBox.shrink(),
      },
      child,
    ],
  );
}

/// Compact preview for picker tiles / master list swatch.
Widget siteBackdropPreview({
  required SiteBackdropDraft style,
  required SiteThemeTokens theme,
  double height = 72,
}) {
  final stage = theme.isDark ? const Color(0xFF141418) : const Color(0xFFECECF0);
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: ColoredBox(
      color: stage,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: siteBackdropLayer(
          style: style,
          theme: theme,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.accent,
    required this.intensity,
    required this.softness,
    required this.scale,
  });

  final Color accent;
  final double intensity;
  final double softness;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final alpha = 0.12 + intensity * 0.38;
    final radius = 0.75 + softness * 0.7;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.55 / scale),
              radius: radius * scale,
              colors: [accent.withValues(alpha: alpha), Colors.transparent],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.7, 0.85),
              radius: 0.55 * scale,
              colors: [accent.withValues(alpha: alpha * 0.35), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropMesh extends StatelessWidget {
  const _BackdropMesh({
    required this.accent,
    required this.secondary,
    required this.intensity,
    required this.scale,
  });

  final Color accent;
  final Color secondary;
  final double intensity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final a = 0.08 + intensity * 0.28;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.75 * scale, -0.7),
              radius: 0.95 * scale,
              colors: [accent.withValues(alpha: a), Colors.transparent],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.85 * scale, -0.15),
              radius: 0.85 * scale,
              colors: [secondary.withValues(alpha: a * 0.9), Colors.transparent],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2, 0.95),
              radius: 0.9 * scale,
              colors: [accent.withValues(alpha: a * 0.55), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropDiamond extends StatelessWidget {
  const _BackdropDiamond({
    required this.accent,
    required this.secondary,
    required this.intensity,
    required this.softness,
    required this.scale,
  });

  final Color accent;
  final Color secondary;
  final double intensity;
  final double softness;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final a = 0.1 + intensity * 0.32;
    final mid = Color.lerp(accent, secondary, 0.45) ?? accent;
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.rotate(
          angle: -0.35 * scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: a),
                  mid.withValues(alpha: a * softness),
                  Colors.transparent,
                  secondary.withValues(alpha: a * 0.7),
                ],
                stops: const [0, 0.35, 0.65, 1],
              ),
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.55 * scale,
          child: Opacity(
            opacity: 0.55 + softness * 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.transparent,
                    secondary.withValues(alpha: a * 0.65),
                    accent.withValues(alpha: a * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropAurora extends StatelessWidget {
  const _BackdropAurora({
    required this.accent,
    required this.secondary,
    required this.intensity,
    required this.softness,
    required this.scale,
  });

  final Color accent;
  final Color secondary;
  final double intensity;
  final double softness;
  final double scale;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _AuroraPainter(
          accent: accent,
          secondary: secondary,
          intensity: intensity,
          softness: softness,
          scale: scale,
        ),
        child: const SizedBox.expand(),
      );
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.accent,
    required this.secondary,
    required this.intensity,
    required this.softness,
    required this.scale,
  });

  final Color accent;
  final Color secondary;
  final double intensity;
  final double softness;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final a = 0.12 + intensity * 0.38;
    final teal = Color.lerp(accent, const Color(0xFF2EE6A6), 0.55) ?? accent;
    final violet = Color.lerp(secondary, const Color(0xFF7B6CFF), 0.4) ?? secondary;
    final bands = <({double y, double amp, double thick, Color c, double phase})>[
      (y: 0.18, amp: 0.06, thick: 0.22 * scale, c: teal, phase: 0.0),
      (y: 0.32, amp: 0.08, thick: 0.18 * scale, c: accent, phase: 1.2),
      (y: 0.48, amp: 0.05, thick: 0.16 * scale, c: violet, phase: 2.4),
    ];
    for (final b in bands) {
      _band(canvas, size, yFrac: b.y, ampFrac: b.amp, thickFrac: b.thick, color: b.c, alpha: a, phase: b.phase);
    }
    // Soft sky wash so ribbons read as atmosphere, not hard shapes.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: a * 0.22 * softness),
          Colors.transparent,
        ],
        stops: const [0, 0.7],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
  }

  void _band(
    Canvas canvas,
    Size size, {
    required double yFrac,
    required double ampFrac,
    required double thickFrac,
    required Color color,
    required double alpha,
    required double phase,
  }) {
    final w = size.width;
    final h = size.height;
    final y0 = h * yFrac;
    final amp = h * ampFrac * (0.6 + softness * 0.5);
    final thick = h * thickFrac.clamp(0.08, 0.4);
    final path = Path()..moveTo(0, y0);
    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = w * t;
      final y = y0 + math.sin(t * math.pi * 2.2 + phase) * amp + math.sin(t * math.pi * 5 + phase * 0.7) * amp * 0.35;
      path.lineTo(x, y);
    }
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      final x = w * t;
      final y = y0 + thick + math.sin(t * math.pi * 2.2 + phase + 0.4) * amp * 0.7;
      path.lineTo(x, y);
    }
    path.close();
    final bounds = path.getBounds().inflate(thick * 0.6);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withValues(alpha: alpha * softness),
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          Colors.transparent,
        ],
        stops: const [0, 0.2, 0.45, 0.75, 1],
      ).createShader(bounds)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + softness * 18);
    canvas.drawPath(path, paint);

    // Vertical curtain streaks inside the ribbon.
    final streak = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + softness * 6);
    final streakCount = (8 + intensity * 10).round();
    for (var i = 0; i < streakCount; i++) {
      final t = (i + 0.5) / streakCount;
      final x = w * t;
      final yTop = y0 + math.sin(t * math.pi * 2.2 + phase) * amp - thick * 0.15;
      final yBot = yTop + thick * (0.7 + (i % 3) * 0.15);
      streak.color = color.withValues(alpha: alpha * (0.18 + (i % 4) * 0.06));
      canvas.drawLine(Offset(x, yTop), Offset(x, yBot), streak);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.accent != accent ||
      old.secondary != secondary ||
      old.intensity != intensity ||
      old.softness != softness ||
      old.scale != scale;
}

class _BackdropGrain extends StatelessWidget {
  const _BackdropGrain({required this.intensity, required this.isDark});

  final double intensity;
  final bool isDark;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _GrainPainter(intensity: intensity, isDark: isDark),
        child: const SizedBox.expand(),
      );
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.intensity, required this.isDark});

  final double intensity;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (size.width * size.height * 0.018 * (0.4 + intensity)).round().clamp(80, 2200);
    final base = isDark ? Colors.white : Colors.black;
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = (0.04 + rnd.nextDouble() * 0.14) * intensity.clamp(0.05, 1);
      paint.color = base.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.9 + 0.3, paint);
    }
    // Soft vignette so grain reads as a layer, not noise alone.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, (isDark ? Colors.black : Colors.white).withValues(alpha: 0.08 + intensity * 0.12)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.intensity != intensity || old.isDark != isDark;
}
