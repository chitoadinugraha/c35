import 'dart:async';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_object_batch_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_col_cell.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadObjects());
  }

  @override
  void didUpdateWidget(covariant UiSiteProductDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId || oldWidget.siteIid != widget.siteIid) {
      unawaited(_loadObjects());
    }
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
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

  void _debouncedCommit(String key, Future<void> Function() action) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 450), () => action());
  }

  bool _parseBool(String value) =>
      value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';

  Future<void> _commitField(SiteProduct base, ColDef col, String value) async {
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
        await _commitField(product, col, value);
        if (add == true && mounted) await _openBatchDialog(product);
        return;
      }
    }
    if (col.type == ColType.COL_TYPE_BOOL) {
      await _commitField(product, col, value);
      return;
    }
    _debouncedCommit('${product.productId}:${col.key}', () => _commitField(product, col, value));
  }

  Future<void> _openBatchDialog(SiteProduct product) async {
    if (widget.busy) return;
    final n = await showSiteObjectBatchDialog(context, api: widget.api, siteIid: widget.siteIid, product: product);
    if (n != null && n > 0) await _loadObjects();
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

  Future<void> _commitEmbed(SiteProduct product, String embedRowKey, ColDef col, String value) async {
    if (widget.busy) return;
    widget.onBusy(true);
    try {
      final mine = widget.embeds.where((e) => e.productId == product.productId).toList();
      final idx = mine.indexWhere((e) => e.embedId.toString() == embedRowKey);
      final base = idx >= 0 ? mine[idx] : widget.api.productEmbedNew(widget.siteIid, product.productId);
      final updated = siteProductEmbedApplyCell(base, col, value);
      final next = [...mine];
      if (idx >= 0) {
        next[idx] = updated;
      } else {
        next.add(updated);
      }
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      widget.onEmbedsChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  Future<void> _addEmbed(SiteProduct product) async {
    if (widget.busy) return;
    widget.onBusy(true);
    try {
      final mine = widget.embeds.where((e) => e.productId == product.productId).toList();
      final next = [...mine, widget.api.productEmbedNew(widget.siteIid, product.productId)];
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      widget.onEmbedsChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }


  Future<void> _deleteEmbed(SiteProduct product, SiteProductEmbed embed) async {
    if (widget.busy) return;
    widget.onBusy(true);
    try {
      final next = widget.embeds.where((e) => e.productId == product.productId && e.embedId != embed.embedId).toList(growable: false);
      await widget.api.productPut(widget.siteIid, product, embeds: next);
      widget.onEmbedsChanged();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      widget.onBusy(false);
    }
  }

  Widget _reservationUnitsSection(SiteProduct product) {
    if (!product.canReserve) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 12),
        const Text('Reservation units', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
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
                    child: Text(
                      o.name.isEmpty ? o.code : o.name,
                      style: const TextStyle(color: _text, fontSize: 13),
                    ),
                  ),
                  if (o.kind.isNotEmpty)
                    Text(
                      siteObjectKindLabel(o.kind),
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
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
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productId = '${product.productId}';
    final cells = siteProductCells(product);
    final rowKey = siteRowKey(widget.def, cells);
    final host = UiColCellHost(siteIid: widget.siteIid, products: widget.productsById);
    final embedDef = collectionDefEmbedFallback();
    final embedCols = embedDef?.columns.where((c) => !c.readonly && c.inlineEditable).toList() ?? const <ColDef>[];
    final mineEmbeds = widget.embeds.where((e) => e.productId == product.productId);

    return UiSiteEditorFormScroll(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name.isEmpty ? 'Product' : product.name,
                style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: widget.busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
              label: const Text('Delete', style: TextStyle(color: Color(0xFFF87171))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('ID $productId', style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 16),
        _PicRow(pic: product.pic, busy: widget.busy, onPick: () => _pickPic(product)),
        const SizedBox(height: 16),
        for (final col in widget.def.columns.where((c) => !c.readonly && c.inlineEditable && c.key != 'product_id' && c.key != 'pic'))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(col.label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                uiColCellBuild(
                  UiColCellScope(
                    context: context,
                    rowKey: rowKey,
                    row: cells,
                    col: col,
                    value: cells[col.key] ?? '',
                    editable: !widget.busy,
                    host: host,
                    onCommit: (v) => _commitProductField(product, col, v),
                  ),
                ),
              ],
            ),
          ),
        if (embedDef != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(embedDef.label, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600))),
              TextButton.icon(
                onPressed: widget.busy ? null : () => _addEmbed(product),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add label'),
              ),
            ],
          ),
          for (final e in mineEmbeds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final col in embedCols)
                    Expanded(
                      child: uiColCellBuild(
                        UiColCellScope(
                          context: context,
                          rowKey: '${e.embedId}',
                          row: siteProductEmbedCells(e),
                          col: col,
                          value: siteProductEmbedCells(e)[col.key] ?? '',
                          editable: !widget.busy,
                          onCommit: (v) => _commitEmbed(product, '${e.embedId}', col, v),
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: widget.busy ? null : () => _deleteEmbed(product, e),
                    icon: const Icon(Icons.delete_outline, size: 20, color: _muted),
                    tooltip: 'Delete label',
                  ),
                ],
              ),
            ),
        ],
        _reservationUnitsSection(product),
        if (widget.busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
      ],
    );
  }
}

class _PicRow extends StatelessWidget {
  const _PicRow({required this.pic, required this.busy, required this.onPick});

  final String pic;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: pic.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFF18181B),
                    child: const Icon(Icons.image_outlined, color: _muted),
                  )
                : UiImg(src: pic, width: 72, height: 72, fallback: const Icon(Icons.broken_image_outlined, color: _muted)),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onPick,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Upload image'),
            style: OutlinedButton.styleFrom(foregroundColor: _text, side: const BorderSide(color: _border)),
          ),
        ],
      );
}
