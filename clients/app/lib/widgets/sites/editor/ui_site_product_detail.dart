import 'dart:async';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/io/in_media_list.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/io/in_string_list.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_object_batch_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteProductDetail extends StatefulWidget {
  const UiSiteProductDetail({
    super.key,
    required this.api,
    required this.siteIid,
    required this.product,
    required this.def,
    required this.productsById,
    required this.embeds,
    required this.busy,
    required this.onBusy,
    required this.onProductUpdated,
    required this.onDeleted,
    required this.onEmbedsChanged,
  });

  final SiteApi api;
  final int siteIid;
  final SiteProduct product;
  final TableDef def;
  final Map<String, SiteProduct> productsById;
  final List<SiteProductEmbed> embeds;
  final bool busy;
  final ValueChanged<bool> onBusy;
  final ValueChanged<SiteProduct> onProductUpdated;
  final VoidCallback onDeleted;
  final VoidCallback onEmbedsChanged;

  @override
  State<UiSiteProductDetail> createState() => _UiSiteProductDetailState();
}

class _UiSiteProductDetailState extends State<UiSiteProductDetail> {
  final _debounceTimers = <String, Timer>{};
  var _linkedObjects = <SiteObject>[];
  late final _nameCtrl = TextEditingController(text: widget.product.name);
  late final _descCtrl = TextEditingController(text: widget.product.desc);
  late final _skuCtrl = TextEditingController(text: widget.product.sku);
  late final _unitCtrl = TextEditingController(text: widget.product.unit);
  late final _categoryCtrl = TextEditingController(text: widget.product.category);
  late final _priceCtrl = TextEditingController(text: _priceDisplay(widget.product));

  static String _priceDisplay(SiteProduct p) =>
      p.price <= Int64.ZERO ? '' : moneyFmtIdrGrouped(p.price.toInt());

  @override
  void initState() {
    super.initState();
    unawaited(_loadObjects());
  }

  @override
  void didUpdateWidget(covariant UiSiteProductDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId) {
      _syncCtrlsFromProduct();
      unawaited(_loadObjects());
      return;
    }
    if (oldWidget.product.price != widget.product.price) {
      _priceCtrl.text = _priceDisplay(widget.product);
    }
  }

  void _syncCtrlsFromProduct() {
    final p = widget.product;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.desc;
    _skuCtrl.text = p.sku;
    _unitCtrl.text = p.unit;
    _categoryCtrl.text = p.category;
    _priceCtrl.text = _priceDisplay(p);
  }

  List<String> _altNames() => widget.embeds
      .where((e) => e.productId == widget.product.productId)
      .map((e) => e.label)
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadObjects() async {
    try {
      final all = await widget.api.objectList(widget.siteIid);
      if (!mounted) return;
      final pid = widget.product.productId;
      setState(() {
        _linkedObjects = all.where((o) => o.productId == pid).toList()
          ..sort((a, b) {
            final c = a.code.compareTo(b.code);
            return c != 0 ? c : a.name.compareTo(b.name);
          });
      });
    } catch (_) {}
  }

  void _debouncedSave(String key, Future<void> Function() action) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 450), () => unawaited(action()));
  }

  bool _parseBool(String value) =>
      value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';

  Future<void> _saveProduct(SiteProduct draft) async {
    if (widget.busy) return;
    widget.onBusy(true);
    try {
      final updated = await widget.api.productPut(widget.siteIid, draft);
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      widget.onBusy(false);
    }
  }

  void _debouncedDraft(String key, SiteProduct draft) => _debouncedSave(key, () => _saveProduct(draft));

  Future<void> _commitBool(ColDef col, bool value) async {
    final cells = siteProductCells(widget.product);
    await _commitField(widget.product, col, value ? 'yes' : 'no', cells);
  }

  Future<void> _commitField(SiteProduct base, ColDef col, String value, [Map<String, String>? cells]) async {
    if (widget.busy || col.readonly) return;
    widget.onBusy(true);
    try {
      final updated = await widget.api.productPut(widget.siteIid, siteProductApplyCell(base, col, value));
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    } finally {
      widget.onBusy(false);
    }
  }

  Future<void> _commitProductField(SiteProduct product, ColDef col, String value) async {
    if (col.key == 'can_reserve') {
      final enabling = _parseBool(value);
      if (enabling && !product.canReserve && _linkedObjects.isEmpty) {
        final add = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Text('Add reservation units?', style: TextStyle(color: _text)),
            content: const Text(
              'This product has no linked units yet. Add numbered units (rooms, tables, etc.) so guests can reserve.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                child: const Text('Add units'),
              ),
            ],
          ),
        );
        await _commitField(product, col, value, siteProductCells(product));
        if (add == true && mounted) await _openBatchDialog(product);
        return;
      }
    }
    if (col.type == ColType.COL_TYPE_BOOL) {
      await _commitField(product, col, value, siteProductCells(product));
      return;
    }
    _debouncedCommit('${product.productId}:${col.key}', () => _commitField(product, col, value, siteProductCells(product)));
  }

  void _debouncedCommit(String key, Future<void> Function() action) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 450), () => action());
  }

  Future<void> _openBatchDialog(SiteProduct product) async {
    if (widget.busy) return;
    final n = await showSiteObjectBatchDialog(context, api: widget.api, siteIid: widget.siteIid, product: product);
    if (n != null && n > 0) await _loadObjects();
  }

  Future<void> _pickExtraPics(SiteProduct product) async {
    if (widget.busy) return;
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: true, maxCount: 8);
    if (staged == null || staged.isEmpty) return;
    widget.onBusy(true);
    try {
      final paths = [...siteProductPicsRead(product)];
      for (final file in staged) {
        final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
        if (up == null || up.hash.isEmpty) continue;
        paths.add(fileStoragePath(up.hash));
      }
      final updated = await widget.api.productPut(widget.siteIid, siteProductApplyPics(product, paths));
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  void _removeExtraPic(SiteProduct product, int index) {
    final paths = siteProductPicsRead(product);
    if (index < 0 || index >= paths.length) return;
    _debouncedDraft('pics', siteProductApplyPics(product, [...paths]..removeAt(index)));
  }

  Future<void> _saveAltNames(SiteProduct product, List<String> labels) async {
    if (widget.busy) return;
    final mine = widget.embeds.where((e) => e.productId == product.productId).toList();
    final clean = labels.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    final next = <SiteProductEmbed>[];
    for (var i = 0; i < clean.length; i++) {
      if (i < mine.length) {
        next.add(mine[i].clone()..label = clean[i]);
      } else {
        next.add(widget.api.productEmbedNew(widget.siteIid, product.productId)..label = clean[i]);
      }
    }
    widget.onBusy(true);
    try {
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      widget.onEmbedsChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  Future<void> _pickPic(SiteProduct product) async {
    if (widget.busy) return;
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
    if (staged == null || staged.isEmpty) return;
    widget.onBusy(true);
    try {
      final file = staged.first;
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) throw 'upload failed';
      final pic = fileStoragePath(up.hash);
      final updated = await widget.api.productPut(widget.siteIid, product.clone()..pic = pic);
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete product?', style: TextStyle(color: _text)),
        content: Text('Remove "${widget.product.name}" from the catalog.', style: const TextStyle(color: _muted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.onBusy(true);
    try {
      await widget.api.productDelete(widget.siteIid, widget.product.productId);
      widget.onDeleted();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  ColDef? _col(String key) => widget.def.columns.where((c) => c.key == key).firstOrNull;

  Widget _reservationUnitsSection(SiteProduct product) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_linkedObjects.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'No units linked to this product. Add rooms, tables, or other bookable units.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            )
          else
            ..._linkedObjects.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(o.name.isEmpty ? o.code : o.name, style: const TextStyle(color: _text, fontSize: 13)),
                    ),
                    if (o.kind.isNotEmpty)
                      Text(siteObjectKindLabel(o.kind), style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.busy ? null : () => unawaited(_openBatchDialog(product)),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add units'),
            ),
          ),
        ],
      );

  Widget _heroRow(SiteProduct product) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductPicTile(pic: product.pic, busy: widget.busy, onTap: () => _pickPic(product)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameCtrl,
                  enabled: !widget.busy,
                  style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: siteEditorInputDecoration(hintText: 'Product name'),
                  onChanged: (v) => _debouncedDraft('name', product.clone()..name = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  enabled: !widget.busy,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(color: _text, fontSize: 13, height: 1.35),
                  decoration: siteEditorInputDecoration(hintText: 'Description'),
                  onChanged: (v) => _debouncedDraft('desc', product.clone()..desc = v),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _extraPicsSection(SiteProduct product) => UiSiteEditorLabeledField(
        label: 'More photos',
        child: InMediaList(
          paths: siteProductPicsRead(product),
          enabled: !widget.busy,
          onAdd: () => unawaited(_pickExtraPics(product)),
          onRemove: (i) => _removeExtraPic(product, i),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productId = '${product.productId}';
    final cells = siteProductCells(product);
    final boolCols = widget.def.columns
        .where((c) => !c.readonly && c.inlineEditable && c.type == ColType.COL_TYPE_BOOL)
        .toList(growable: false);

    return UiSiteEditorFormScroll(
      children: [
        Row(
          children: [
            Expanded(child: Text('ID $productId', style: const TextStyle(color: _muted, fontSize: 11))),
            TextButton.icon(
              onPressed: widget.busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
              label: const Text('Delete', style: TextStyle(color: Color(0xFFF87171))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _heroRow(product),
        const SizedBox(height: 12),
        _extraPicsSection(product),
        const SizedBox(height: 16),
        UiSiteEditorFormSection(
          title: 'Pricing',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: UiSiteEditorLabeledField(
                    label: 'Price',
                    child: TextField(
                      controller: _priceCtrl,
                      enabled: !widget.busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: moneyIdrInputFormatters,
                      style: const TextStyle(color: _text, fontSize: 13),
                      decoration: siteEditorInputDecoration(hintText: '0').copyWith(
                        suffixText: 'IDR',
                        suffixStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 12),
                      ),
                      onChanged: (v) {
                        final n = moneyParseIdrInt(v) ?? 0;
                        _debouncedDraft('price', product.clone()..price = Int64(n));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: UiSiteEditorLabeledField(
                    label: 'Unit',
                    child: TextField(
                      controller: _unitCtrl,
                      enabled: !widget.busy,
                      style: const TextStyle(color: _text, fontSize: 13),
                      decoration: siteEditorInputDecoration(hintText: 'pcs, plate…'),
                      onChanged: (v) => _debouncedDraft('unit', product.clone()..unit = v),
                    ),
                  ),
                ),
              ],
            ),
            UiSiteEditorLabeledField(
              label: 'Category',
              child: TextField(
                controller: _categoryCtrl,
                enabled: !widget.busy,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: siteEditorInputDecoration(hintText: 'Optional category'),
                onChanged: (v) => _debouncedDraft('category', product.clone()..category = v),
              ),
            ),
          ],
        ),
        UiSiteEditorFormSection(
          title: 'SKU & barcode',
          children: [
            UiSiteEditorLabeledField(
              label: 'SKU',
              child: TextField(
                controller: _skuCtrl,
                enabled: !widget.busy,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: siteEditorInputDecoration(hintText: 'Internal code'),
                onChanged: (v) => _debouncedDraft('sku', product.clone()..sku = v),
              ),
            ),
            UiSiteEditorLabeledField(
              label: 'Barcodes',
              child: InStringList(
                values: siteProductBarcodesRead(product),
                enabled: !widget.busy,
                hintText: 'Scan / EAN',
                monospace: true,
                onChanged: (codes) => _debouncedDraft('barcodes', siteProductApplyBarcodes(product, codes)),
              ),
            ),
          ],
        ),
        UiSiteEditorFormSection(
          title: 'Alternative names',
          children: [
            InStringList(
              values: _altNames(),
              enabled: !widget.busy,
              hintText: 'Another name guests may search',
              onChanged: (names) => _debouncedSave('alt_names', () => _saveAltNames(product, names)),
            ),
          ],
        ),
        UiSiteEditorFormSection(
          title: 'Inventory',
          children: [
            UiSiteEditorSwitchRow(
              label: 'Track stock',
              value: product.trackStock,
              onChanged: widget.busy
                  ? null
                  : (v) {
                      final col = _col('track_stock');
                      if (col != null) unawaited(_commitBool(col, v));
                    },
            ),
            if (product.trackStock) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text('On hand', style: TextStyle(color: siteEditorFormText, fontSize: 13)),
                  ),
                  _StockStepper(
                    value: product.stockQty,
                    enabled: !widget.busy,
                    onChanged: (qty) => _saveProduct(product.clone()..stockQty = qty),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (boolCols.isNotEmpty)
          UiSiteEditorFormSection(
            title: 'Catalog options',
            children: [
              for (final col in boolCols)
                if (col.key != 'track_stock')
                  UiSiteEditorSwitchRow(
                    label: col.label,
                    value: _parseBool(cells[col.key] ?? ''),
                    onChanged: widget.busy ? null : (v) => _commitProductField(product, col, v ? 'yes' : 'no'),
                  ),
            ],
          ),
        if (product.canReserve)
          UiSiteEditorFormSection(title: 'Reservation units', children: [_reservationUnitsSection(product)]),
        if (widget.busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
      ],
    );
  }
}

class _ProductPicTile extends StatelessWidget {
  const _ProductPicTile({required this.pic, required this.busy, required this.onTap});

  final String pic;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: siteEditorFieldFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (pic.isEmpty)
                  const Center(child: Icon(Icons.add_photo_alternate_outlined, color: _muted, size: 28))
                else
                  UiImg(src: pic, fit: BoxFit.cover, fallback: const Icon(Icons.broken_image_outlined, color: _muted)),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StockStepper extends StatelessWidget {
  const _StockStepper({required this.value, required this.enabled, required this.onChanged});

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: siteEditorFieldFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: siteEditorFieldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepBtn(Icons.remove, enabled && value > 0 ? () => onChanged(value - 1) : null),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('$value', style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            _stepBtn(Icons.add, enabled ? () => onChanged(value + 1) : null),
          ],
        ),
      );

  Widget _stepBtn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, size: 18, color: onTap == null ? siteEditorFormMuted : _accent),
        ),
      );
}
