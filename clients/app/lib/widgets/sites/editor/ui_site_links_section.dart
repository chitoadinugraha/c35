import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_link_platform.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/ui_site_platform_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteLinksSection extends StatelessWidget {
  const UiSiteLinksSection({
    super.key,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.links,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.addBusy,
    required this.onReorder,
    required this.onActiveChanged,
    this.showListActive = false,
  });

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<SiteLink> links;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final bool addBusy;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(String id, bool active) onActiveChanged;
  final bool showListActive;

  List<SiteLink> get _filtered {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return links;
    return links
        .where((l) {
          final icon = siteLinkPlatformNormalize(l.icon);
          return l.label.toLowerCase().contains(q) ||
              l.url.toLowerCase().contains(q) ||
              siteLinkPlatformLabel(icon).toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  bool get _reorderEnabled => search.trim().isEmpty && onReorder != null && links.length > 1;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: searchController,
          hintText: 'Search links',
          onSearchChanged: onSearchChanged,
          onAdd: onAdd,
          addBusy: addBusy,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.link, title: 'No links', subtitle: 'Add a hub link for your storefront')
              : _reorderEnabled
                  ? ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      itemCount: filtered.length,
                      onReorder: (old, newIdx) {
                        final adj = newIdx > old ? newIdx - 1 : newIdx;
                        onReorder!(old, adj);
                      },
                      itemBuilder: (ctx, i) => _tile(
                        context,
                        filtered[i],
                        index: i,
                        reorderable: true,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _tile(context, filtered[i], reorderable: false),
                    ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, SiteLink link, {required bool reorderable, int index = 0}) {
    final id = '${link.linkId}';
    final selected = selectedId == id;
    final icon = siteLinkPlatformNormalize(link.icon);
    final title = link.label.isEmpty ? siteLinkPlatformLabel(icon) : link.label;
    final subtitle = link.url.isEmpty ? '' : siteLinkValueDisplay(icon: icon, stored: link.url);

    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF1A2E28) : const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? _accent.withValues(alpha: 0.45) : _border.withValues(alpha: 0.85),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelect(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                if (_reorderEnabled && reorderable)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.drag_indicator, size: 20, color: _muted),
                    ),
                  ),
                Opacity(opacity: link.active ? 1 : 0.45, child: UiSitePlatformIcon(id: icon, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: link.active ? 1 : 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: _muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (showListActive)
                  UiSiteCatalogActiveSwitch(
                    value: link.active,
                    onChanged: (v) => onActiveChanged(id, v),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
