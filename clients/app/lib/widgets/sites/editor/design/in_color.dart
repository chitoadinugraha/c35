import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_color.dart';

Future<String?> inColorPickerShow(BuildContext context, {required String current}) async {
  var color = siteColorStopsParse(current).first;
  final ok = await ColorPicker(
    color: color,
    onColorChanged: (c) => color = c,
    width: 40,
    height: 40,
    spacing: 8,
    runSpacing: 8,
    borderRadius: 12,
    hasBorder: true,
    enableOpacity: false,
    showColorCode: true,
    colorCodeHasColor: true,
    pickersEnabled: const {
      ColorPickerType.wheel: true,
      ColorPickerType.primary: false,
      ColorPickerType.accent: false,
      ColorPickerType.bw: false,
    },
    heading: Text('io.pickColor'.tr(), style: Theme.of(context).textTheme.titleMedium),
    wheelDiameter: 180,
    wheelWidth: 18,
  ).showPickerDialog(
    context,
    constraints: const BoxConstraints(minWidth: 320, maxWidth: 360, minHeight: 420, maxHeight: 520),
  );
  if (!ok) return null;
  return siteColorFormat(color);
}

/// Single solid color — palette swatches + custom picker.
///
/// For multi-stop / gradient outlines use [InColorStops].
class InColor extends StatelessWidget {
  const InColor({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  String get _solid => siteColorFormat(siteColorStopsParse(value).first);

  bool get _customSelected => !sitePaletteColors.any((s) => siteColorValueEq(s, _solid));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final solid = _solid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final swatch in sitePaletteColors)
              _ColorSwatchDot(
                value: swatch,
                selected: siteColorValueEq(swatch, solid),
                onTap: () => onChanged(swatch),
              ),
            _ColorSwatchDot(
              value: solid,
              selected: _customSelected,
              custom: true,
              onTap: () async {
                final next = await inColorPickerShow(context, current: solid);
                if (next != null) onChanged(next);
              },
              borderColor: cs.outlineVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({
    required this.value,
    required this.selected,
    required this.onTap,
    this.custom = false,
    this.borderColor,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;
  final bool custom;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stops = siteColorStopsParse(value);
    final multi = stops.length > 1;
    final showRainbow = custom && !selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: showRainbow || multi ? null : stops.first,
          gradient: showRainbow
              ? const SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red])
              : multi
                  ? siteColorGradient(value)
                  : null,
          border: Border.all(
            color: selected ? cs.onSurface : (borderColor ?? Colors.transparent),
            width: selected ? 2.5 : (custom ? 1 : 0),
          ),
        ),
        child: showRainbow ? Center(child: Icon(Icons.palette_outlined, size: 16, color: cs.onSurface)) : null,
      ),
    );
  }
}
