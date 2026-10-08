import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_theme.dart';

/// Card style preset picker + optional param sliders.
class InCardStyle extends StatelessWidget {
  const InCardStyle({
    super.key,
    required this.value,
    required this.theme,
    required this.onChanged,
    this.showCustomize = true,
    this.compact = false,
  });

  final SiteCardStyleDraft value;
  final SiteThemeTokens theme;
  final ValueChanged<SiteCardStyleDraft> onChanged;
  final bool showCustomize;
  final bool compact;

  String get _id => siteCardStyleNormalizeId(value.id);
  SiteCardStylePreset get _preset => siteCardStylePresetGet(_id);
  Map<String, double> get _params => siteCardStyleParamsResolve(value);
  bool get _custom => siteCardStyleIsCustom(value);

  void _presetSet(String id) =>
      onChanged(SiteCardStyleDraft(id: siteCardStyleNormalizeId(id), params: siteCardStyleDefaultParams(id)));

  void _paramSet(String key, num v) {
    final next = Map<String, num>.from(value.params)..[key] = v;
    onChanged(value.copyWith(id: _id, params: next));
  }

  void _reset() => onChanged(SiteCardStyleDraft(id: _id));

  String _paramLabel(SiteCardStyleParam param, double v) => switch (param.key) {
        'radius' => '${v.round()}px',
        'opacity' || 'borderOpacity' || 'tintStrength' => '${(v * 100).round()}%',
        _ => '${v.round()}',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileW = compact ? 88.0 : 108.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in siteCardStylePresets)
              _InCardStyleTile(
                preset: p,
                selected: _id == p.id,
                theme: theme,
                width: tileW,
                compact: compact,
                onTap: () => _presetSet(p.id),
              ),
          ],
        ),
        if (showCustomize) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Customize ${_preset.name}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (_custom)
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text('io.reset'.tr()),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _preset.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final param in _preset.params) ...[
            Row(
              children: [
                Expanded(child: Text(param.label, style: const TextStyle(fontSize: 13))),
                Text(
                  _paramLabel(param, _params[param.key] ?? param.defaultValue),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            Slider(
              value: (_params[param.key] ?? param.defaultValue).clamp(param.min, param.max),
              min: param.min,
              max: param.max,
              divisions: ((param.max - param.min) / param.step).round().clamp(1, 100),
              onChanged: (v) => _paramSet(param.key, double.parse(v.toStringAsFixed(2))),
            ),
            const SizedBox(height: 2),
          ],
        ],
      ],
    );
  }
}

class _InCardStyleTile extends StatelessWidget {
  const _InCardStyleTile({
    required this.preset,
    required this.selected,
    required this.theme,
    required this.width,
    required this.compact,
    required this.onTap,
  });

  final SiteCardStylePreset preset;
  final bool selected;
  final SiteThemeTokens theme;
  final double width;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = siteCardDecorationResolve(
      style: SiteCardStyleDraft(id: preset.id, params: siteCardStyleDefaultParams(preset.id)),
      theme: theme,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        padding: EdgeInsets.all(compact ? 6 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: compact ? 56 : 72,
              width: double.infinity,
              child: InCardStylePreview(card: card, theme: theme),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              preset.name,
              style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
            if (!compact)
              Text(
                preset.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mini card surface with sample lines — readable on light and dark themes.
class InCardStylePreview extends StatelessWidget {
  const InCardStylePreview({
    super.key,
    required this.card,
    required this.theme,
    this.showLines = true,
    this.dense = false,
  });

  final SiteCardDecoration card;
  final SiteThemeTokens theme;
  final bool showLines;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final stage = theme.isDark ? const Color(0xFF1A1A1E) : const Color(0xFFE8E8EC);
    final line = theme.isDark ? Colors.white38 : Colors.black38;
    final stagePad = dense ? 3.0 : 6.0;
    final innerPad = dense ? 5.0 : 8.0;
    final lineH = dense ? 3.0 : 4.0;
    final radius = dense ? 8.0 : 10.0;
    final cardRadius = (card.decoration.borderRadius is BorderRadius)
        ? ((card.decoration.borderRadius as BorderRadius).topLeft.x).clamp(4.0, dense ? 8.0 : 16.0)
        : (dense ? 6.0 : 8.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stage,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: EdgeInsets.all(stagePad),
        child: siteCardWrap(
          card: SiteCardDecoration(
            decoration: card.decoration.copyWith(borderRadius: BorderRadius.circular(cardRadius)),
            padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: dense ? 4 : innerPad),
            blurSigma: card.blurSigma,
          ),
          child: showLines
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SampleLine(color: line, widthFactor: 0.85, height: lineH),
                    SizedBox(height: dense ? 2 : 4),
                    _SampleLine(color: line.withValues(alpha: 0.55), widthFactor: 0.55, height: lineH),
                  ],
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SampleLine extends StatelessWidget {
  const _SampleLine({required this.color, required this.widthFactor, this.height = 4});

  final Color color;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
      );
}
