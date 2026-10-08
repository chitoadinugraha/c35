import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

/// Shared detail header for catalog editors — identity + active + delete.
class UiSiteCatalogDetailHeader extends StatelessWidget {
  const UiSiteCatalogDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.active,
    this.onActiveChanged,
    this.onDelete,
    this.deleteLabel,
    this.deleteConfirmTitle,
    this.deleteConfirmBody,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;
  final bool? active;
  final ValueChanged<bool>? onActiveChanged;
  final VoidCallback? onDelete;
  final String? deleteLabel;
  final String? deleteConfirmTitle;
  final String? deleteConfirmBody;

  Future<void> _delete(BuildContext context) async {
    if (onDelete == null) return;
    final ok = await siteCatalogConfirmDelete(
      context,
      title: deleteConfirmTitle ?? deleteLabel ?? 'Delete',
      body: deleteConfirmBody,
    );
    if (ok) onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null)
          leading!
        else if (icon != null)
          Icon(icon, size: 22, color: cs.onSurfaceVariant),
        if (leading != null || icon != null) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            tooltip: deleteLabel ?? 'Delete',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: Icon(Icons.delete_outline, size: 22, color: cs.error),
            onPressed: () => _delete(context),
          ),
        if (active != null && onActiveChanged != null)
          UiSiteCatalogActiveSwitch(value: active!, onChanged: onActiveChanged!),
      ],
    );
  }
}

/// List-row / header active toggle — stops parent InkWell selection.
class UiSiteCatalogActiveSwitch extends StatelessWidget {
  const UiSiteCatalogActiveSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: SizedBox(
          height: 40,
          child: Center(
            child: Switch(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ),
        ),
      );
}
