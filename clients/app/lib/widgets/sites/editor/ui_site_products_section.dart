import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteProductsSection extends StatelessWidget {
  const UiSiteProductsSection({
    super.key,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.products,
    required this.selectedId,
    required this.onSelect,
    required this.onReorder,
    required this.onAdd,
    required this.addBusy,
    required this.onPaste,
    required this.onImportImage,
    required this.onOpenTaxes,
    required this.onOpenDesign,
    required this.designPaneActive,
    required this.taxes,
  });

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<SiteProduct> products;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAdd;
  final bool addBusy;
  final VoidCallback onPaste;
  final VoidCallback onImportImage;
  final VoidCallback onOpenTaxes;
  final VoidCallback onOpenDesign;
  final bool designPaneActive;
  final List<SiteTaxDraft> taxes;

  List<SiteProduct> get _filtered {
    final q = search.trim().toLowerCase();
    final items = [...products];
    if (q.isEmpty) return items;
    return items
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.desc.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q))
        .toList(growable: false);
  }

  int get _activeTaxCount => taxes.where((t) => t.active).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: searchController,
          hintText: 'Search products',
          onSearchChanged: onSearchChanged,
          onAdd: onAdd,
          addBusy: addBusy,
          onPaste: onPaste,
          onImportImage: onImportImage,
          designSelected: designPaneActive,
          onDesignToggle: onOpenDesign,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.inventory_2_outlined, title: 'No products', subtitle: 'Add a product to get started')
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: filtered.length,
                  onReorder: (old, newIdx) {
                    final adj = newIdx > old ? newIdx - 1 : newIdx;
                    onReorder(old, adj);
                  },
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final id = '${p.productId}';
                    final active = selectedId == id;
                    final price = p.price <= Int64.ZERO ? '' : moneyFmtIdr(p.price.toInt());
                    return Material(
                      key: ValueKey(id),
                      color: active ? const Color(0xFF1F2937) : Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelect(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6)))),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.drag_handle, size: 20, color: _muted),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name.isEmpty ? 'Product $id' : p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 13,
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                    if (p.category.isNotEmpty || price.isNotEmpty)
                                      Text(
                                        [p.category, price].where((s) => s.isNotEmpty).join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: _muted, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              if (p.isArchived) const Icon(Icons.inventory_2_outlined, size: 14, color: _muted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Material(
          color: const Color(0xFF18181B),
          child: InkWell(
            onTap: onOpenTaxes,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: _border.withValues(alpha: 0.8)))),
              child: Row(
                children: [
                  const Icon(Icons.percent_outlined, size: 18, color: _muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeTaxCount == 0 ? 'No sales taxes' : '$_activeTaxCount active tax${_activeTaxCount == 1 ? '' : 'es'}',
                      style: const TextStyle(color: _text, fontSize: 12),
                    ),
                  ),
                  const Text('Manage', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right, size: 18, color: _muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
