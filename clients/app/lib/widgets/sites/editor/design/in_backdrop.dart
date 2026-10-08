import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_backdrop.dart';
import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_theme.dart';
import 'in_color.dart';

/// Backdrop preset picker + intensity/color customization.
class InBackdrop extends StatelessWidget {
  const InBackdrop({
    super.key,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  final SiteBackdropDraft value;
  final SiteThemeTokens theme;
  final ValueChanged<SiteBackdropDraft> onChanged;

  String get _id => siteBackdropNormalizeId(value.id);
  SiteBackdropPreset get _preset => siteBackdropPresetGet(_id);
  Map<String, double> get _params => siteBackdropParamsResolve(value);
  bool get _custom => siteBackdropIsCustom(value);
  bool get _hasCustomize => _preset.params.isNotEmpty;

  void _presetSet(String id) =>
      onChanged(SiteBackdropDraft(id: siteBackdropNormalizeId(id), params: siteBackdropDefaultParams(id)));

  void _paramSet(String key, num v) {
    final next = Map<String, num>.from(value.params)..[key] = v;
    onChanged(value.copyWith(id: _id, params: next));
  }

  void _colorSet(String color) => onChanged(value.copyWith(id: _id, color: color));

  void _colorClear() => onChanged(value.copyWith(id: _id, clearColor: true));

  void _reset() => onChanged(SiteBackdropDraft(id: _id));

  String _paramLabel(SiteBackdropParam param, double v) =>
      param.key == 'intensity' || param.key == 'softness' ? '${(v * 100).round()}%' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentFallback = siteColorFormat(theme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in siteBackdropPresets)
              _InBackdropTile(
                preset: p,
                selected: _id == p.id,
                theme: theme,
                onTap: () => _presetSet(p.id),
              ),
          ],
        ),
        if (_hasCustomize) ...[
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
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: cs.primary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_preset.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
          if (_id != 'grain' && _id != 'none') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('io.accentColor'.tr(), style: Theme.of(context).textTheme.labelLarge)),
                if (value.color.trim().isNotEmpty)
                  TextButton(
                    onPressed: _colorClear,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text('io.theme'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InColor(
              label: '',
              value: value.color.trim().isNotEmpty ? value.color : accentFallback,
              onChanged: _colorSet,
            ),
          ],
        ],
      ],
    );
  }
}

class _InBackdropTile extends StatelessWidget {
  const _InBackdropTile({
    required this.preset,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final SiteBackdropPreset preset;
  final bool selected;
  final SiteThemeTokens theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = SiteBackdropDraft(id: preset.id, params: siteBackdropDefaultParams(preset.id));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 100,
        padding: const EdgeInsets.all(8),
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
              height: 64,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  siteBackdropPreview(style: preview, theme: theme, height: 64),
                  if (preset.id == 'none')
                    Center(child: Icon(preset.icon, size: 22, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(preset.name, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
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
