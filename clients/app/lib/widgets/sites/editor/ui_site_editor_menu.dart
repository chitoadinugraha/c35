import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:flutter/material.dart';

class SiteEditorMenuItem {
  const SiteEditorMenuItem(this.id, this.icon, this.label, {this.enabled = true, this.subtitle});

  final String id;
  final IconData icon;
  final String label;
  final bool enabled;
  final String? subtitle;
}

class SiteEditorMenuGroup {
  const SiteEditorMenuGroup(this.label, this.items);

  final String label;
  final List<SiteEditorMenuItem> items;
}

const siteEditorMenuDefaultId = 'info';

/// SiteApi already exposes work-shift and presence-location RPCs.
const siteEditorAttendanceEnabled = true;

List<SiteEditorMenuGroup> siteEditorMenuGroups(SiteEditorCaps caps) => [
      const SiteEditorMenuGroup('Site', [
        SiteEditorMenuItem('info', Icons.info_outline, 'Info'),
        SiteEditorMenuItem('links', Icons.link, 'Links'),
        SiteEditorMenuItem('design', Icons.palette_outlined, 'Design'),
        SiteEditorMenuItem('effects', Icons.auto_awesome_outlined, 'Effects'),
        SiteEditorMenuItem('ai', Icons.smart_toy_outlined, 'AI'),
      ]),
      SiteEditorMenuGroup('Catalog', [
        SiteEditorMenuItem('products', Icons.shopping_bag_outlined, 'Products', enabled: caps.commerce),
        SiteEditorMenuItem('objects', Icons.table_restaurant_outlined, 'Objects', enabled: caps.booking),
        SiteEditorMenuItem('contacts', Icons.people_outline, 'Contacts', enabled: caps.commerce || caps.booking),
        SiteEditorMenuItem('queue', Icons.queue, 'Queue', enabled: caps.queue),
      ]),
      SiteEditorMenuGroup('Settings', [
        const SiteEditorMenuItem('capabilities', Icons.tune_outlined, 'Capabilities'),
        const SiteEditorMenuItem('team', Icons.group_outlined, 'Team'),
        SiteEditorMenuItem(
          'attendance',
          Icons.fingerprint,
          'Attendance',
          enabled: siteEditorAttendanceEnabled,
          subtitle: siteEditorAttendanceEnabled ? null : 'Follows the Team plan',
        ),
        const SiteEditorMenuItem('accounts', Icons.account_balance_wallet_outlined, 'Accounts'),
        const SiteEditorMenuItem('notifications', Icons.notifications_outlined, 'Notifications'),
        const SiteEditorMenuItem('plan', Icons.workspace_premium_outlined, 'Plan'),
        const SiteEditorMenuItem('publish', Icons.rocket_launch_outlined, 'Publish'),
      ]),
    ];

String? siteEditorMenuLabel(String id, {SiteEditorCaps caps = const SiteEditorCaps()}) {
  for (final g in siteEditorMenuGroups(caps)) {
    for (final item in g.items) {
      if (item.id == id) return item.label;
    }
  }
  return null;
}

enum SiteEditorMenuVariant { page, rail }

class UiSiteEditorMenu extends StatelessWidget {
  const UiSiteEditorMenu({
    super.key,
    required this.onSelect,
    required this.caps,
    this.selectedId,
    this.variant = SiteEditorMenuVariant.page,
  });

  final ValueChanged<String> onSelect;
  final SiteEditorCaps caps;
  final String? selectedId;
  final SiteEditorMenuVariant variant;

  bool get _rail => variant == SiteEditorMenuVariant.rail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF3F3F46) : cs.outlineVariant.withValues(alpha: 0.55);

    final groups = siteEditorMenuGroups(caps);
    final list = ListView(
      padding: EdgeInsets.fromLTRB(_rail ? 8 : 16, _rail ? 12 : 8, _rail ? 10 : 16, 24),
      children: [
        for (var gi = 0; gi < groups.length; gi++) ...[
          if (gi > 0)
            Padding(
              padding: EdgeInsets.only(top: _rail ? 10 : 8, bottom: _rail ? 6 : 4),
              child: Divider(height: 1, color: border.withValues(alpha: 0.65)),
            ),
          _MenuGroup(group: groups[gi], selectedId: selectedId, rail: _rail, onSelect: onSelect),
        ],
      ],
    );

    if (!_rail) return list;

    return ColoredBox(
      color: isDark ? const Color(0xFF121216) : cs.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(right: BorderSide(color: border))),
        child: list,
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.group, required this.selectedId, required this.rail, required this.onSelect});

  final SiteEditorMenuGroup group;
  final String? selectedId;
  final bool rail;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(rail ? 10 : 4, 0, 10, 4),
          child: Text(
            group.label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
        ),
        for (final item in group.items)
          _MenuRow(item: item, active: item.id == selectedId, rail: rail, onSelect: onSelect),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.active, required this.rail, required this.onSelect});

  final SiteEditorMenuItem item;
  final bool active;
  final bool rail;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = item.enabled;
    final fg = !enabled ? cs.onSurfaceVariant.withValues(alpha: 0.35) : (active ? cs.onSurface : cs.onSurfaceVariant);
    final bg = active && enabled ? cs.primary.withValues(alpha: 0.12) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: active && enabled ? BorderSide(color: cs.primary.withValues(alpha: 0.22)) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onSelect(item.id) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rail ? 10 : 4, vertical: rail ? 8 : 9),
            child: Row(
              children: [
                Icon(item.icon, size: 16, color: active && enabled ? cs.primary : fg),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: fg)),
                      if (item.subtitle != null && item.subtitle!.isNotEmpty)
                        Text(item.subtitle!, style: TextStyle(fontSize: 11, height: 1.2, color: fg)),
                    ],
                  ),
                ),
                if (!rail && enabled) Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
