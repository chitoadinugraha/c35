import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_product_thumb.dart';
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
                  padding: const EdgeInsets.only(bottom: 4),
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
                    final subtitle = [if (p.category.isNotEmpty) p.category, if (price.isNotEmpty) price].join(' · ');
                    return Material(
                      key: ValueKey(id),
                      color: active ? const Color(0xFF1A1F2E) : Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelect(id),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: active ? _accent : Colors.transparent, width: 3),
                              bottom: BorderSide(color: _border.withValues(alpha: 0.55)),
                            ),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(Icons.drag_indicator, size: 20, color: _muted),
                                ),
                              ),
                              UiSiteProductThumb(product: p, size: 44),
                              const SizedBox(width: 10),
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
                                    if (subtitle.isNotEmpty)
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: _muted, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              if (p.isArchived)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.inventory_2_outlined, size: 14, color: _muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Material(
            color: siteEditorCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.85)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenTaxes,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: siteEditorFieldFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: siteEditorFieldBorder),
                      ),
                      child: const Icon(Icons.percent_outlined, size: 16, color: _accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sales taxes', style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            _activeTaxCount == 0 ? 'None configured' : '$_activeTaxCount active',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Text('Manage', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Icon(Icons.chevron_right, size: 18, color: _muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
