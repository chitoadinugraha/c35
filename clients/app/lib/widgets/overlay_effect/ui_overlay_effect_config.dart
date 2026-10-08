import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/overlay_effect_format.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_param_read.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_preset.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_color.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'ui_overlay_effect_icon.dart';

/// Shared overlay/interaction param editor (site editor + chat effects drawer).
class UiOverlayEffectConfig extends StatefulWidget {
  const UiOverlayEffectConfig({
    super.key,
    required this.effect,
    required this.preset,
    required this.onChanged,
    this.onDelete,
    this.deleteConfirmTitle,
    this.deleteConfirmBody,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 16),
  });

  final SiteOverlayEffectDraft effect;
  final OverlayEffectPreset preset;
  final ValueChanged<SiteOverlayEffectDraft> onChanged;
  final VoidCallback? onDelete;
  final String? deleteConfirmTitle;
  final String? deleteConfirmBody;
  final EdgeInsetsGeometry padding;

  @override
  State<UiOverlayEffectConfig> createState() => _UiOverlayEffectConfigState();
}

class _UiOverlayEffectConfigState extends State<UiOverlayEffectConfig> {
  var _tab = 0;

  void _paramSet(String key, Object? value) {
    final next = Map<String, Object?>.from(widget.effect.params)..[key] = value;
    widget.onChanged(widget.effect.copyWith(params: next));
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.effect;
    final preset = widget.preset;
    final overlayParams = preset.paramsIn(OverlayEffectParamGroup.overlay);
    final interactionParams = preset.paramsIn(OverlayEffectParamGroup.interaction);
    final params = preset.hasInteractionParams ? (_tab == 0 ? overlayParams : interactionParams) : overlayParams;

    return ListView(
      padding: widget.padding,
      children: [
        UiSiteCatalogDetailHeader(
          leading: UiOverlayEffectIcon(icon: preset.icon, size: 22, color: Theme.of(context).colorScheme.primary),
          title: preset.name,
          subtitle: preset.description.isEmpty ? null : preset.description,
          active: effect.active,
          onActiveChanged: (v) => widget.onChanged(effect.copyWith(active: v)),
          onDelete: widget.onDelete,
          deleteConfirmTitle: widget.deleteConfirmTitle,
          deleteConfirmBody: widget.deleteConfirmBody,
        ),
        if (preset.hasInteractionParams) ...[
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Overlay')),
              ButtonSegment(value: 1, label: Text('Interaction')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 12),
        for (final param in params)
          _EffectParamField(
            param: param,
            value: effect.params[param.key] ?? param.defaultValue,
            onChanged: (v) => _paramSet(param.key, v),
          ),
      ],
    );
  }
}

class _EffectParamField extends StatelessWidget {
  const _EffectParamField({
    required this.param,
    required this.value,
    required this.onChanged,
  });

  final OverlayEffectParamDef param;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: switch (param.type) {
          OverlayEffectParamType.boolean => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(param.label),
              value: value == true,
              onChanged: onChanged,
            ),
          OverlayEffectParamType.color => InColor(
              label: param.label,
              value: value is String
                  ? value as String
                  : (param.defaultValue is String ? param.defaultValue as String : '#ffffff'),
              onChanged: onChanged,
            ),
          OverlayEffectParamType.number => Builder(
              builder: (context) {
                final numVal = overlayEffectParamNum(value, fallback: overlayEffectParamNum(param.defaultValue, fallback: 0));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(param.label)),
                        Text(
                          overlayEffectFormatNumber(numVal),
                          style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: numVal.toDouble().clamp((param.min ?? 0).toDouble(), (param.max ?? 100).toDouble()),
                      min: (param.min ?? 0).toDouble(),
                      max: (param.max ?? 100).toDouble(),
                      divisions: param.step != null && param.step! > 0
                          ? (((param.max ?? 100) - (param.min ?? 0)) / param.step!).round().clamp(1, 200)
                          : null,
                      onChanged: (v) => onChanged(
                            param.step != null ? (v / param.step!).round() * param.step! : v,
                          ),
                    ),
                  ],
                );
              },
            ),
        },
      );
}
