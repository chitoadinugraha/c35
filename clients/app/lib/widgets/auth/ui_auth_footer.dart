import 'package:flutter/material.dart';

class UiAuthFooter extends StatelessWidget {
  const UiAuthFooter({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final muted = c.onSurfaceVariant.withValues(alpha: 0.85);
    final chipStyle = theme.textTheme.labelSmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.28)),
          color: c.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(version, style: chipStyle),
        ),
      ),
    );
  }
}
