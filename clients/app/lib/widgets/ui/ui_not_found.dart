import 'package:flutter/material.dart';

class UINotFound extends StatelessWidget {
  const UINotFound({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.search_off_rounded,
    this.iconSize = 56,
    this.child,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final double iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}

class UINotFoundScrollable extends StatelessWidget {
  const UINotFoundScrollable({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.search_off_rounded,
    this.iconSize = 56,
    this.child,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final double iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: UINotFound(title: title, subtitle: subtitle, icon: icon, iconSize: iconSize, child: child),
          ),
        ],
      );
}
