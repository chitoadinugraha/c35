import 'package:alienai_c35/c/hint/hint_chip_theme.dart';
import 'package:flutter/material.dart';

class UiHintChip extends StatelessWidget {
  const UiHintChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.theme = HintChipTheme.defaultTheme,
    this.enabled = true,
    this.showChevron = false,
    this.expand = false,
  }) : assert(icon != null || leading != null, 'icon or leading required');

  final Widget label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final HintChipTheme theme;
  final bool enabled;
  final bool showChevron;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? theme.icon : HintChipTheme.defaultTheme.icon;
    final textColor = enabled ? theme.label : HintChipTheme.defaultTheme.icon;
    final lead = leading ?? Icon(icon, size: 15, color: iconColor);
    final text = DefaultTextStyle.merge(style: TextStyle(color: textColor, fontSize: 13), child: label);
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        lead,
        const SizedBox(width: 8),
        if (expand) Expanded(child: text) else text,
        if (showChevron && enabled) ...[
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 16, color: HintChipTheme.defaultTheme.icon),
        ],
      ],
    );
    if (!expand) {
      return ActionChip(
        label: row,
        backgroundColor: theme.background,
        side: BorderSide(color: theme.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        onPressed: enabled ? onPressed : null,
      );
    }
    return Material(
      color: theme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.border)),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: row),
      ),
    );
  }
}
