import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_color.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_font.dart';
import 'package:alienai_c35/widgets/sites/editor/design/in_size.dart';
import 'package:alienai_c35/widgets/ui/ui_dropdown_item.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

/// Typography toolbar:
/// ```
/// [ Font                             ] [ Size ]
/// Bold▾   I   U   [Color]
/// ```
class InTextStyle extends StatelessWidget {
  const InTextStyle({
    super.key,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.italic,
    required this.underline,
    required this.color,
    required this.onFontFamily,
    required this.onFontSize,
    required this.onFontWeight,
    required this.onItalic,
    required this.onUnderline,
    required this.onColor,
    this.sizeMin = 10,
    this.sizeMax = 28,
  });

  final String fontFamily;
  final double fontSize;
  final String fontWeight;
  final bool italic;
  final bool underline;
  final String color;
  final ValueChanged<String> onFontFamily;
  final ValueChanged<double> onFontSize;
  final ValueChanged<String> onFontWeight;
  final ValueChanged<bool> onItalic;
  final ValueChanged<bool> onUnderline;
  final ValueChanged<String> onColor;
  final double sizeMin;
  final double sizeMax;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = siteFontWeightNormalize(fontWeight);
    final swatch = color.trim().isEmpty ? cs.onSurface : siteColorParse(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: InFont(value: fontFamily, onChanged: onFontFamily)),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: InSize(
                value: fontSize,
                min: sizeMin,
                max: sizeMax,
                onChanged: onFontSize,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('text-weight-$w'),
                initialValue: w,
                isExpanded: true,
                decoration: UiInputDecoration.of(context, labelText: 'io.bold'.tr()),
                selectedItemBuilder: (context) => [
                  for (final id in siteFontWeightIds)
                    UiDropdownItem(icon: Icons.format_bold, label: siteFontWeightLabel(id)),
                ],
                items: [
                  for (final id in siteFontWeightIds)
                    DropdownMenuItem(
                      value: id,
                      child: UiDropdownItem(icon: Icons.format_bold, label: siteFontWeightLabel(id)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onFontWeight(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            _FormatToggle(
              tooltip: 'io.italic'.tr(),
              selected: italic,
              icon: Icons.format_italic,
              onPressed: () => onItalic(!italic),
            ),
            const SizedBox(width: 4),
            _FormatToggle(
              tooltip: 'io.underline'.tr(),
              selected: underline,
              icon: Icons.format_underlined,
              onPressed: () => onUnderline(!underline),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: color.trim().isEmpty ? 'Color' : color.toUpperCase(),
              child: Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: InkWell(
                  onTap: () async {
                    final picked = await inColorPickerShow(
                      context,
                      current: color.trim().isEmpty ? siteColorFormat(cs.onSurface) : color,
                    );
                    if (picked != null) onColor(picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: swatch,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatToggle extends StatelessWidget {
  const _FormatToggle({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? cs.primary.withValues(alpha: 0.18) : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? cs.primary.withValues(alpha: 0.45) : cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 48,
            child: Icon(icon, size: 20, color: selected ? cs.primary : cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
