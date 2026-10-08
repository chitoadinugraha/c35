import 'dart:async';

import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_product_detail.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_product_design_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_product_import_image.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_product_paste_dialog.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_products_section.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_tax_list.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
enum SiteProductsPane { list, taxes, design }

String siteProductsPaneLabel(SiteProductsPane pane) => switch (pane) {
      SiteProductsPane.list => 'Products',
      SiteProductsPane.taxes => 'Taxes',
      SiteProductsPane.design => 'Design',
    };

class UiSiteProductsEditor extends StatefulWidget {
  const UiSiteProductsEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    required this.pane,
    this.onPaneChanged,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final SiteProductsPane pane;
  final ValueChanged<SiteProductsPane>? onPaneChanged;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteProductsEditor> createState() => _UiSiteProductsEditorState();
}

class _UiSiteProductsEditorState extends State<UiSiteProductsEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  TableDef? _def;
  final _productsById = <String, SiteProduct>{};
  var _embeds = <SiteProductEmbed>[];
  var _taxes = <SiteTaxDraft>[];
  var _design = const SiteProductDesignDraft();
  Timer? _metaSaveTimer;

  @override
  void initState() {
    super.initState();
    _pickDefault();
    _load();
  }

  @override
  void dispose() {
    _metaSaveTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteProductsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) _load();
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _productsById[_selectedId] == null) _pickDefault();
  }

  String? get _activeId => widget.masterDetail ? (_selectedId ?? _firstId) : widget.detailId;

  String? get _firstId => _orderedProducts.isEmpty ? null : '${_orderedProducts.first.productId}';

  List<SiteProduct> get _orderedProducts {
    final items = _productsById.values.toList();
    items.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.productId.compareTo(b.productId);
    });
    return items;
  }

  void _pickDefault() {
    if (_productsById.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || _productsById[_selectedId] == null) _selectedId = _firstId;
      return;
    }
    if (widget.detailId != null && _productsById[widget.detailId] == null) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  void _setPane(SiteProductsPane pane) => widget.onPaneChanged?.call(pane);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final defs = await widget.api.collectionDefs(siteIid: widget.siteIid);
      _def = widget.api.tableDefFor(defs, 'site.product') ?? collectionDefForFallback('site.product');
      final items = await widget.api.productList(widget.siteIid);
      _embeds = await widget.api.productEmbedList(widget.siteIid);
      final meta = await widget.api.draftGetMeta(widget.siteIid);
      _taxes = meta.taxes;
      _design = meta.productDesign;
      _syncProducts(items);
      _pickDefault();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncProducts(List<SiteProduct> items) {
    _productsById
      ..clear()
      ..addEntries(items.map((p) => MapEntry('${p.productId}', p)));
  }

  Future<void> _addProduct() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sort = _orderedProducts.isEmpty ? 0 : _orderedProducts.last.sortOrder + 1;
      final p = await widget.api.productPut(
        widget.siteIid,
        widget.api.productNew(widget.siteIid)..sortOrder = sort,
      );
      _syncProducts([..._productsById.values, p]);
      _searchCtrl.clear();
      setState(() => _search = '');
      _select('${p.productId}');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteProducts() async {
    final rows = await uiSiteProductPasteDialogShow(context);
    if (rows == null || rows.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      var sort = _orderedProducts.isEmpty ? 0 : _orderedProducts.last.sortOrder + 1;
      final created = <SiteProduct>[];
      for (final row in rows) {
        final p = SiteProduct(siteIid: Int64(widget.siteIid), name: row.name, canSell: true, sortOrder: sort++);
        if (row.description.isNotEmpty) p.desc = row.description;
        if (row.price > 0) p.price = Int64(row.price);
        created.add(await widget.api.productPut(widget.siteIid, p));
      }
      _syncProducts([..._productsById.values, ...created]);
      if (created.isNotEmpty) _select('${created.last.productId}');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sort = _orderedProducts.isEmpty ? 0 : _orderedProducts.last.sortOrder + 1;
      final created = await uiSiteProductImportFromImage(context, api: widget.api, siteIid: widget.siteIid, sortOrderStart: sort);
      if (created == null || created.isEmpty) return;
      _syncProducts([..._productsById.values, ...created]);
      if (created.isNotEmpty) _select('${created.last.productId}');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_busy || _search.trim().isNotEmpty) return;
    final items = [..._orderedProducts];
    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) return;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _busy = true);
    try {
      final entries = <({Int64 id, int sortOrder})>[];
      for (var i = 0; i < items.length; i++) {
        items[i].sortOrder = i;
        entries.add((id: items[i].productId, sortOrder: i));
        _productsById['${items[i].productId}'] = items[i];
      }
      await widget.api.productReorder(widget.siteIid, entries);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleMetaSave() {
    _metaSaveTimer?.cancel();
    _metaSaveTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_saveMeta()));
  }

  Future<void> _saveMeta() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.draftPutMeta(widget.siteIid, taxes: _taxes, productDesign: _design);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onTaxesChanged(List<SiteTaxDraft> taxes) {
    setState(() => _taxes = taxes);
    _scheduleMetaSave();
  }

  void _onDesignChanged(SiteProductDesignDraft design) {
    setState(() => _design = design);
    _scheduleMetaSave();
  }

  void _addTax() {
    final id = 'tax_${DateTime.now().millisecondsSinceEpoch}';
    _onTaxesChanged([..._taxes, SiteTaxDraft(id: id, type: kSiteTaxTypePpn, name: siteTaxDefaultName(kSiteTaxTypePpn))]);
  }

  Widget _taxesPane() => UiSiteEditorFormScroll(
        children: [
          UiSiteTaxList(taxes: _taxes, busy: _busy, onChanged: _onTaxesChanged, onAdd: _addTax),
        ],
      );

  Widget _designPane() => UiSiteEditorFormScroll(
        children: [
          UiSiteProductDesignEditor(design: _design, busy: _busy, onChanged: _onDesignChanged),
        ],
      );

  Widget _listPane({required String? selectedId}) => UiSiteProductsSection(
        searchController: _searchCtrl,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
        products: _orderedProducts,
        selectedId: selectedId,
        onSelect: _select,
        onReorder: _reorder,
        onAdd: _addProduct,
        addBusy: _busy,
        onPaste: _pasteProducts,
        onImportImage: _importImage,
        onOpenTaxes: () => _setPane(SiteProductsPane.taxes),
        onOpenDesign: () => _setPane(SiteProductsPane.design),
        designPaneActive: widget.pane == SiteProductsPane.design,
        taxes: _taxes,
      );

  Widget _detailPane(String productId) {
    final product = _productsById[productId];
    final def = _def;
    if (product == null || def == null) {
      return const Center(child: Text('Product not found', style: TextStyle(color: _muted)));
    }
    return UiSiteProductDetail(
      api: widget.api,
      siteIid: widget.siteIid,
      product: product,
      def: def,
      productsById: _productsById,
      embeds: _embeds,
      busy: _busy,
      onBusy: (v) => setState(() => _busy = v),
      onProductUpdated: (p) => setState(() => _productsById['${p.productId}'] = p),
      onDeleted: () {
        _productsById.remove(productId);
        _pickDefault();
        if (widget.masterDetail) {
          setState(() {});
        } else {
          widget.onDetailIdChanged?.call(_firstId);
        }
      },
      onEmbedsChanged: () async {
        _embeds = await widget.api.productEmbedList(widget.siteIid);
        if (mounted) setState(() {});
      },
    );
  }

  Widget _paneBody({String? selectedId}) {
    return switch (widget.pane) {
      SiteProductsPane.taxes => _taxesPane(),
      SiteProductsPane.design => _designPane(),
      SiteProductsPane.list => widget.masterDetail
          ? _listPane(selectedId: selectedId)
          : (selectedId != null ? _detailPane(selectedId) : _listPane(selectedId: null)),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    if (_error != null && _productsById.isEmpty && widget.pane == SiteProductsPane.list) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final detailId = widget.pane == SiteProductsPane.list ? _activeId : null;
    final Widget body;
    if (widget.masterDetail && widget.pane == SiteProductsPane.list && _productsById.isNotEmpty) {
      final selected = detailId ?? _firstId!;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detailPane(selected)),
        ],
      );
    } else if (widget.pane != SiteProductsPane.list) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onPaneChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _setPane(SiteProductsPane.list),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to products'),
                ),
              ),
            ),
          Expanded(child: _paneBody(selectedId: detailId)),
        ],
      );
    } else {
      body = _paneBody(selectedId: detailId);
    }

    if (_error == null || _error!.isEmpty) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0x33F87171),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
