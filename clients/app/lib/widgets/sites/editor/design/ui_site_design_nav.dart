import 'package:flutter/material.dart';

import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';

/// Section label in a design master list (e.g. Typography).
class UiSiteDesignSectionHeader extends StatelessWidget {
  const UiSiteDesignSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

/// Selectable row in a design master list.
class UiSiteDesignChoiceRow extends StatelessWidget {
  const UiSiteDesignChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.toggleValue,
    this.onToggleChanged,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;
  /// When set, shows a switch instead of the chevron (e.g. link container on/off).
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showToggle = onToggleChanged != null && toggleValue != null;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? cs.primary.withValues(alpha: 0.28) : cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: cs.primary),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (showToggle)
                Switch(
                  value: toggleValue!,
                  onChanged: onToggleChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              else
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Master + detail shell for catalog design mode.
class UiSiteDesignMasterDetail extends StatelessWidget {
  const UiSiteDesignMasterDetail({
    super.key,
    required this.masterDetail,
    required this.master,
    required this.detail,
    this.detailId,
  });

  final bool masterDetail;
  final Widget master;
  final Widget detail;
  final String? detailId;

  @override
  Widget build(BuildContext context) {
    if (masterDetail) {
      final cs = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final border = isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: master),
          ColoredBox(color: border, child: const SizedBox(width: 1)),
          Expanded(child: detail),
        ],
      );
    }
    if (detailId != null) return detail;
    return master;
  }
}
