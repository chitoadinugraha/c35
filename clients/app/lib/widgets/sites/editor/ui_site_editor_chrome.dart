import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

/// Top chrome for site editor — back, title, optional preview toggle (CSA layout).
class UiSiteEditorChrome extends StatelessWidget {
  const UiSiteEditorChrome({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.onBack,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);

    return Material(
      color: isDark ? const Color(0xFF18181B) : cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
            child: Row(
              children: [
                if (onBack != null)
                  uiIconButton(tooltip: 'Back', onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                if (onBack != null) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor ?? cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
