import 'dart:ui';

import 'package:flutter/material.dart';

import 'site_design_models.dart';
import 'site_theme.dart';

class SiteCardStyleParam {
  const SiteCardStyleParam({
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

class SiteCardStylePreset {
  const SiteCardStylePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.params,
  });

  final String id;
  final String name;
  final String description;
  final List<SiteCardStyleParam> params;
}

const _radius = SiteCardStyleParam(key: 'radius', label: 'Roundness', min: 6, max: 24, step: 1, defaultValue: 8);
const _shadow = SiteCardStyleParam(key: 'shadow', label: 'Shadow', min: 0, max: 3, step: 1, defaultValue: 1);
const _elevShadow = SiteCardStyleParam(key: 'shadow', label: 'Shadow', min: 0, max: 4, step: 1, defaultValue: 3);
const _borderW = SiteCardStyleParam(key: 'borderWidth', label: 'Border width', min: 0, max: 3, step: 0.5, defaultValue: 1);
const _borderOp = SiteCardStyleParam(key: 'borderOpacity', label: 'Border strength', min: 0.15, max: 1, step: 0.05, defaultValue: 0.55);
const _padding = SiteCardStyleParam(key: 'padding', label: 'Padding', min: 8, max: 20, step: 1, defaultValue: 12);
const _opacity = SiteCardStyleParam(key: 'opacity', label: 'Transparency', min: 0.25, max: 0.95, step: 0.01, defaultValue: 0.52);
const _blur = SiteCardStyleParam(key: 'blur', label: 'Frostiness', min: 4, max: 40, step: 1, defaultValue: 14);
const _tintStrength = SiteCardStyleParam(key: 'tintStrength', label: 'Tint strength', min: 0, max: 0.6, step: 0.02, defaultValue: 0);

const siteCardStylePresets = <SiteCardStylePreset>[
  SiteCardStylePreset(
    id: 'solid',
    name: 'Solid',
    description: 'Opaque cards',
    params: [_radius, _shadow, _borderW, _padding],
  ),
  SiteCardStylePreset(
    id: 'outlined',
    name: 'Outlined',
    description: 'Transparent with border',
    params: [
      SiteCardStyleParam(key: 'radius', label: 'Roundness', min: 6, max: 24, step: 1, defaultValue: 10),
      SiteCardStyleParam(key: 'borderWidth', label: 'Border width', min: 0, max: 3, step: 0.5, defaultValue: 1.5),
      _borderOp,
      _padding,
      SiteCardStyleParam(key: 'shadow', label: 'Shadow', min: 0, max: 3, step: 1, defaultValue: 0),
    ],
  ),
  SiteCardStylePreset(
    id: 'elevated',
    name: 'Elevated',
    description: 'Floating shadow',
    params: [
      SiteCardStyleParam(key: 'radius', label: 'Roundness', min: 6, max: 24, step: 1, defaultValue: 12),
      _elevShadow,
      SiteCardStyleParam(key: 'borderWidth', label: 'Border width', min: 0, max: 3, step: 0.5, defaultValue: 0),
      _padding,
    ],
  ),
  SiteCardStylePreset(
    id: 'flat',
    name: 'Flat',
    description: 'Minimal look',
    params: [
      SiteCardStyleParam(key: 'radius', label: 'Roundness', min: 6, max: 24, step: 1, defaultValue: 8),
      SiteCardStyleParam(key: 'borderWidth', label: 'Border width', min: 0, max: 3, step: 0.5, defaultValue: 1),
      SiteCardStyleParam(key: 'borderOpacity', label: 'Border strength', min: 0.15, max: 1, step: 0.05, defaultValue: 0.35),
      _padding,
      SiteCardStyleParam(key: 'shadow', label: 'Shadow', min: 0, max: 3, step: 1, defaultValue: 0),
    ],
  ),
  SiteCardStylePreset(
    id: 'glass',
    name: 'Glass',
    description: 'Frosted glass',
    params: [
      SiteCardStyleParam(key: 'radius', label: 'Roundness', min: 6, max: 24, step: 1, defaultValue: 12),
      _opacity,
      _blur,
      _borderOp,
      _borderW,
      _padding,
      _shadow,
      _tintStrength,
    ],
  ),
];

SiteCardStylePreset siteCardStylePresetGet(String id) =>
    siteCardStylePresets.firstWhere((p) => p.id == id, orElse: () => siteCardStylePresets.first);

String siteCardStyleNormalizeId(String? id) {
  if (id == null || id.isEmpty) return 'solid';
  if (id == 'frost') return 'glass';
  return siteCardStylePresets.any((p) => p.id == id) ? id : 'solid';
}

Map<String, double> siteCardStyleDefaultParams(String presetId) {
  final preset = siteCardStylePresetGet(siteCardStyleNormalizeId(presetId));
  return {for (final p in preset.params) p.key: p.defaultValue};
}

Map<String, double> siteCardStyleParamsResolve(SiteCardStyleDraft style) {
  final id = siteCardStyleNormalizeId(style.id);
  final defaults = siteCardStyleDefaultParams(id);
  final preset = siteCardStylePresetGet(id);
  return {
    for (final p in preset.params) p.key: (style.params[p.key] ?? defaults[p.key] ?? p.defaultValue).toDouble(),
  };
}

bool siteCardStyleIsCustom(SiteCardStyleDraft style) {
  final id = siteCardStyleNormalizeId(style.id);
  final defaults = siteCardStyleDefaultParams(id);
  final resolved = siteCardStyleParamsResolve(style);
  for (final p in siteCardStylePresetGet(id).params) {
    if ((resolved[p.key] ?? p.defaultValue) != (defaults[p.key] ?? p.defaultValue)) return true;
  }
  return false;
}

String siteCardStyleSubtitle(SiteCardStyleDraft style) {
  final preset = siteCardStylePresetGet(siteCardStyleNormalizeId(style.id));
  final p = siteCardStyleParamsResolve(style);
  final radius = p['radius']?.round() ?? 8;
  if (siteCardStyleIsCustom(style)) return '${preset.name} · Roundness $radius';
  return preset.name;
}

List<BoxShadow> _shadowForLevel(int level, bool isDark) {
  if (level <= 0) return const [];
  final base = isDark ? Colors.black : Colors.black26;
  return switch (level) {
    1 => [BoxShadow(color: base.withValues(alpha: isDark ? 0.35 : 0.12), blurRadius: 6, offset: const Offset(0, 2))],
    2 => [BoxShadow(color: base.withValues(alpha: isDark ? 0.4 : 0.14), blurRadius: 12, offset: const Offset(0, 4))],
    3 => [BoxShadow(color: base.withValues(alpha: isDark ? 0.45 : 0.16), blurRadius: 20, offset: const Offset(0, 8))],
    _ => [BoxShadow(color: base.withValues(alpha: isDark ? 0.5 : 0.18), blurRadius: 28, offset: const Offset(0, 12))],
  };
}

class SiteCardDecoration {
  const SiteCardDecoration({
    required this.decoration,
    required this.padding,
    this.blurSigma,
  });

  final BoxDecoration decoration;
  final EdgeInsets padding;
  final double? blurSigma;
}

SiteCardDecoration siteCardDecorationResolve({
  required SiteCardStyleDraft style,
  required SiteThemeTokens theme,
  SiteCardStyleDraft? globalFallback,
}) {
  final id = siteCardStyleNormalizeId(style.id.isEmpty && globalFallback != null ? globalFallback.id : style.id);
  final merged = style.id.isEmpty && globalFallback != null
      ? SiteCardStyleDraft(id: globalFallback.id, params: globalFallback.params)
      : style;
  final p = siteCardStyleParamsResolve(SiteCardStyleDraft(id: id, params: merged.params));
  final radius = p['radius'] ?? 8;
  final borderW = p['borderWidth'] ?? 1;
  final borderOp = p['borderOpacity'] ?? 0.35;
  final pad = p['padding'] ?? 12;
  final shadowLevel = (p['shadow'] ?? 1).round();
  final border = theme.outline.withValues(alpha: borderOp.clamp(0, 1));

  Color surfaceColor(SiteThemeTokens t) => id == 'glass'
      ? t.surface.withValues(alpha: (p['opacity'] ?? 0.52).clamp(0.2, 1))
      : id == 'outlined' || id == 'flat'
          ? Colors.transparent
          : t.surface;

  var color = surfaceColor(theme);
  final tintStrength = p['tintStrength'] ?? 0;
  if (tintStrength > 0) {
    color = Color.lerp(color, theme.primary, tintStrength.clamp(0, 1)) ?? color;
  }

  final blurSigma = id == 'glass' ? (p['blur'] ?? 14) / 3 : null;

  return SiteCardDecoration(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: borderW > 0 ? Border.all(color: border, width: borderW) : null,
      boxShadow: _shadowForLevel(shadowLevel, theme.isDark),
    ),
    padding: EdgeInsets.all(pad),
    blurSigma: blurSigma,
  );
}

Widget siteCardWrap({
  required SiteCardDecoration card,
  required Widget child,
}) {
  if (card.blurSigma == null || card.blurSigma! <= 0) {
    return Container(decoration: card.decoration, padding: card.padding, child: child);
  }
  return ClipRRect(
    borderRadius: card.decoration.borderRadius ?? BorderRadius.zero,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: card.blurSigma!, sigmaY: card.blurSigma!),
      child: Container(decoration: card.decoration.copyWith(color: card.decoration.color), padding: card.padding, child: child),
    ),
  );
}

String siteBlockDesignSubtitle(SiteBlockDesignDraft? block, SiteCardStyleDraft global) {
  if (block == null || block.inheritsGlobal) return 'Using theme defaults';
  if (block.isBare) return 'No container';
  return siteCardStyleSubtitle(SiteCardStyleDraft(id: block.cardStyleId, params: block.params));
}
