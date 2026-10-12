import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

/// One tappable breadcrumb segment under the site title.
class SiteEditorBreadcrumbSegment {
  const SiteEditorBreadcrumbSegment({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

/// Top chrome for site editor — back, title, breadcrumb path, actions.
class UiSiteEditorChrome extends StatelessWidget {
  const UiSiteEditorChrome({
    super.key,
    required this.title,
    this.statusLine,
    this.statusColor,
    this.breadcrumb = const [],
    this.onBack,
    this.actions,
  });

  final String title;
  final String? statusLine;
  final Color? statusColor;
  final List<SiteEditorBreadcrumbSegment> breadcrumb;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);
    final muted = cs.onSurfaceVariant;

    return Material(
      color: isDark ? const Color(0xFF18181B) : cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 6),
            child: Row(
              children: [
                if (onBack != null)
                  uiIconButton(tooltip: 'Back', onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                if (onBack != null) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (statusLine != null && statusLine!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          statusLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: statusColor ?? muted),
                        ),
                      ] else if (breadcrumb.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _BreadcrumbRow(segments: breadcrumb, muted: muted, accent: cs.primary),
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

class _BreadcrumbRow extends StatelessWidget {
  const _BreadcrumbRow({required this.segments, required this.muted, required this.accent});

  final List<SiteEditorBreadcrumbSegment> segments;
  final Color muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 14, color: muted.withValues(alpha: 0.65)),
              ),
            _SegmentChip(segment: segments[i], muted: muted, accent: accent, isLast: i == segments.length - 1),
          ],
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.segment,
    required this.muted,
    required this.accent,
    required this.isLast,
  });

  final SiteEditorBreadcrumbSegment segment;
  final Color muted;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isLast ? muted : accent.withValues(alpha: 0.95),
          fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
          height: 1.15,
        );
    final label = segment.label;
    if (segment.onTap == null || isLast) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
      ),
    );
  }
}
