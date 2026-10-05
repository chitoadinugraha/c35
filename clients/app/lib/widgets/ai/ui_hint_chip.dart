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
  }) : assert(icon != null || leading != null, 'icon or leading required');

  final Widget label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final HintChipTheme theme;
  final bool enabled;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? theme.icon : HintChipTheme.defaultTheme.icon;
    final textColor = enabled ? theme.label : HintChipTheme.defaultTheme.icon;
    final lead = leading ??
        Icon(icon, size: 15, color: iconColor);
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lead,
          const SizedBox(width: 8),
          DefaultTextStyle.merge(style: TextStyle(color: textColor, fontSize: 13), child: label),
          if (showChevron && enabled) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: HintChipTheme.defaultTheme.icon),
          ],
        ],
      ),
      backgroundColor: theme.background,
      side: BorderSide(color: theme.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      onPressed: enabled ? onPressed : null,
    );
  }
}
