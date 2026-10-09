import 'dart:async';
import 'dart:typed_data';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/image_generate_prompt.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/media/ui_ask_image_generate.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/io/in_media_list.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/io/in_site_product_category.dart';
import 'package:alienai_c35/widgets/io/in_string_list.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_object_batch_dialog.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_objects_editor.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

const _reservationDurationUnits = ['second', 'minute', 'hour', 'day', 'week', 'month', 'year'];

String _reservationDurationLabel(String unit) =>
    unit.isEmpty ? unit : '${unit[0].toUpperCase()}${unit.substring(1)}';

IconData _reservationKindIcon(String kind) => switch (kind) {
      siteObjectKindTable => Icons.table_restaurant_outlined,
      siteObjectKindRoom => Icons.meeting_room_outlined,
      _ => Icons.category_outlined,
    };

class UiSiteProductDetail extends StatefulWidget {
  const UiSiteProductDetail({
    super.key,
    required this.api,
    required this.siteIid,
    required this.product,
    this.booking = true,
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
  final bool booking;
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
  var _textSaveActive = false;
  SiteProduct? _pendingTextDraft;
  late SiteProductExtras _extras = siteProductExtrasRead(widget.product);
  late final _nameCtrl = TextEditingController(text: widget.product.name);
  late final _durationCtrl = TextEditingController(text: '${_extras.durationValue}');
  late final _descCtrl = TextEditingController(text: widget.product.desc);
  late final _skuCtrl = TextEditingController(text: widget.product.sku);
  late final _unitCtrl = TextEditingController(text: widget.product.unit);
  late final _priceCtrl = TextEditingController(text: _priceDisplay(widget.product));
  Uint8List? _picPreviewBytes;
  var _picUploading = false;

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
      _picPreviewBytes = null;
      _picUploading = false;
      _syncCtrlsFromProduct();
      unawaited(_loadObjects());
    }
  }

  void _syncCtrlsFromProduct() {
    final p = widget.product;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.desc;
    _skuCtrl.text = p.sku;
    _unitCtrl.text = p.unit;
    _priceCtrl.text = _priceDisplay(p);
    _extras = siteProductExtrasRead(p);
    _durationCtrl.text = '${_extras.durationValue}';
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
    _priceCtrl.dispose();
    _durationCtrl.dispose();
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

  /// Autosave without [UiSiteProductDetail.busy]. Toggling `enabled` on a
  /// [TextField] unfocuses it, so typing must not disable the field.
  /// A newer draft typed during the request replaces the in-flight one.
  Future<void> _saveProduct(SiteProduct draft) async {
    _pendingTextDraft = draft;
    if (_textSaveActive) return;
    _textSaveActive = true;
    if (mounted) setState(() {});
    try {
      while (mounted && _pendingTextDraft != null) {
        final next = _withLiveText(_pendingTextDraft!);
        _pendingTextDraft = null;
        try {
          final updated = await widget.api.productPut(widget.siteIid, next);
          if (!mounted) return;
          if (_pendingTextDraft == null) widget.onProductUpdated(updated);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
          }
          break;
        }
      }
    } finally {
      _textSaveActive = false;
    }
    if (!mounted) return;
    final leftover = _pendingTextDraft;
    if (leftover != null) {
      unawaited(_saveProduct(leftover));
      return;
    }
    setState(() {});
  }

  SiteProduct _withLiveText(SiteProduct draft) {
    final price = moneyParseIdrInt(_priceCtrl.text) ?? 0;
    return draft.clone()
      ..name = _nameCtrl.text
      ..desc = _descCtrl.text
      ..sku = _skuCtrl.text
      ..unit = _unitCtrl.text
      ..price = Int64(price);
  }

  void _debouncedDraft(String key, SiteProduct draft) => _debouncedSave(key, () => _saveProduct(draft));

  /// Reads controllers when the timer fires so the payload matches what is on screen.
  void _scheduleTextSave() => _debouncedSave('text', () => _saveProduct(widget.product));

  Future<void> _putProduct(SiteProduct draft) async {
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

  Future<void> _setTrackStock(SiteProduct product, bool value) async {
    final draft = product.clone()
      ..trackStock = value
      ..canReserve = value ? false : product.canReserve;
    await _putProduct(draft);
  }

  void _persistExtras(SiteProductExtras extras) {
    setState(() => _extras = extras);
    _debouncedSave('extras', () => _saveProduct(siteProductApplyExtras(widget.product, _extras)));
  }

  void _onDurationEdited(String raw) {
    final n = int.tryParse(raw.trim());
    if (n == null || n < 1) return;
    if (n == _extras.durationValue) return;
    _persistExtras(_extras.copyWith(durationValue: n));
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
      var addUnits = false;
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
        addUnits = add == true;
      }
      final draft = product.clone()
        ..canReserve = enabling
        ..trackStock = enabling ? false : product.trackStock;
      await _putProduct(draft);
      if (addUnits && mounted) await _openBatchDialog(draft, ignoreBusy: true);
      return;
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

  Future<void> _openBatchDialog(SiteProduct product, {bool ignoreBusy = false}) async {
    if (widget.busy && !ignoreBusy) return;
    final n = await showSiteObjectBatchDialog(context, api: widget.api, siteIid: widget.siteIid, product: product);
    if (n != null && n > 0) await _loadObjects();
  }

  Future<void> _pickExtraPics(SiteProduct product) async {
    if (widget.busy) return;
    final staged = await askMedia(
      context: context,
      types: const [MediaType.image],
      allowMultiple: true,
      maxCount: 8,
      allowGenerate: true,
      conn: widget.api.conn,
      generateSlot: ImageGenerateSlot.productExtra,
      generateName: _nameCtrl.text,
      generateDesc: _descCtrl.text,
    );
    if (staged == null || staged.isEmpty) return;
    widget.onBusy(true);
    try {
      final paths = [...siteProductPicsRead(product)];
      for (final file in staged) {
        final generated = file.hash;
        if (generated != null && generated.isNotEmpty) {
          paths.add(fileStoragePath(generated));
          continue;
        }
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

  Future<void> _generatePic(SiteProduct product) async {
    if (widget.busy) return;
    final image = await askImageGenerate(
      context,
      conn: widget.api.conn,
      slot: ImageGenerateSlot.product,
      name: _nameCtrl.text,
      desc: _descCtrl.text,
    );
    if (image == null || image.hash.isEmpty || !mounted) return;
    setState(() => _picUploading = true);
    widget.onBusy(true);
    try {
      final pic = fileStoragePath(image.hash);
      final updated = await widget.api.productPut(widget.siteIid, product.clone()..pic = pic);
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _picUploading = false);
      widget.onBusy(false);
    }
  }

  Future<void> _pickPic(SiteProduct product) async {
    if (widget.busy || _picUploading) return;
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
    if (staged == null || staged.isEmpty) return;
    final file = staged.first;
    if (file.bytes.isEmpty) return;
    setState(() {
      _picPreviewBytes = Uint8List.fromList(file.bytes);
      _picUploading = true;
    });
    widget.onBusy(true);
    try {
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) throw 'upload failed';
      final pic = fileStoragePath(up.hash);
      final updated = await widget.api.productPut(widget.siteIid, product.clone()..pic = pic);
      widget.onProductUpdated(updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _picUploading = false);
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

  Future<void> _editLinkedObject(SiteObject object) async {
    final reservable = widget.productsById.values.where((p) => p.canReserve).toList(growable: false);
    await showSiteObjectEditDialog(
      context,
      api: widget.api,
      siteIid: widget.siteIid,
      object: object,
      reservableProducts: reservable,
    );
    if (mounted) await _loadObjects();
  }

  Widget _reservationUnitsSection(SiteProduct product) {
    final groups = siteObjectsGroupByKindPrefix(_linkedObjects);
    return Column(
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
          for (final group in groups)
            for (final bucket in group.prefixes)
              ExpansionTile(
                key: ValueKey('res-units-${group.kind}-${bucket.prefix}'),
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                iconColor: _muted,
                collapsedIconColor: _muted,
                textColor: _text,
                collapsedTextColor: _text,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                title: Text(bucket.prefix, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(siteObjectKindLabel(group.kind), style: const TextStyle(color: _muted, fontSize: 11)),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in bucket.objs) _reservationUnitTile(product, o),
                      ],
                    ),
                  ),
                ],
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

  Widget _reservationUnitTile(SiteProduct product, SiteObject object) {
    final pic = object.pic.isNotEmpty ? object.pic : product.pic;
    final name = object.name.isEmpty ? object.code : object.name;
    return SizedBox(
      width: 80,
      child: InkWell(
        onTap: widget.busy ? null : () => unawaited(_editLinkedObject(object)),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: pic.isEmpty
                    ? ColoredBox(
                        color: siteEditorFieldFill,
                        child: Icon(_reservationKindIcon(object.kind), color: _muted, size: 28),
                      )
                    : UiImg(
                        src: pic,
                        fit: BoxFit.cover,
                        fallback: Icon(_reservationKindIcon(object.kind), color: _muted, size: 28),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _text, fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationSection(SiteProduct product) {
    final unit = _reservationDurationUnits.contains(_extras.durationUnit) ? _extras.durationUnit : 'day';
    return UiSiteEditorFormSection(
      title: 'Reservation',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: UiSiteEditorLabeledField(
                label: 'Duration',
                child: TextField(
                  key: ValueKey('site-product-duration-${product.productId}'),
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: siteEditorInputDecoration(hintText: '1'),
                  onChanged: _onDurationEdited,
                  onEditingComplete: () {
                    final n = int.tryParse(_durationCtrl.text.trim());
                    if (n == null || n < 1) {
                      _durationCtrl.text = '1';
                      _onDurationEdited('1');
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UiSiteEditorLabeledField(
                label: 'Unit',
                child: DropdownButtonFormField<String>(
                  key: ValueKey('site-product-duration-unit-${product.productId}-$unit'),
                  initialValue: unit,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF18181B),
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: siteEditorInputDecoration(),
                  items: [
                    for (final u in _reservationDurationUnits)
                      DropdownMenuItem(value: u, child: Text(_reservationDurationLabel(u))),
                  ],
                  onChanged: widget.busy
                      ? null
                      : (v) {
                          if (v == null || v == _extras.durationUnit) return;
                          final n = int.tryParse(_durationCtrl.text.trim());
                          final duration = n == null || n < 1 ? 1 : n;
                          _persistExtras(_extras.copyWith(durationUnit: v, durationValue: duration));
                        },
                ),
              ),
            ),
          ],
        ),
        UiSiteEditorSwitchRow(
          label: 'Guest picks a unit',
          value: _extras.reservationGuestPicks,
          onChanged: widget.busy
              ? null
              : (v) {
                  if (v == _extras.reservationGuestPicks) return;
                  _persistExtras(_extras.copyWith(reservationGuestPicks: v));
                },
        ),
        _reservationUnitsSection(product),
      ],
    );
  }

  Widget _heroRow(SiteProduct product) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductPicTile(
            pic: product.pic,
            previewBytes: _picPreviewBytes,
            uploading: _picUploading,
            icon: product.icon,
            busy: widget.busy,
            onTap: () => _pickPic(product),
            onGenerate: () => unawaited(_generatePic(product)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('site-product-name'),
                  controller: _nameCtrl,
                  style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: siteEditorInputDecoration(hintText: 'Product name'),
                  onChanged: (_) => _scheduleTextSave(),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('site-product-desc'),
                  controller: _descCtrl,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(color: _text, fontSize: 13, height: 1.35),
                  decoration: siteEditorInputDecoration(hintText: 'Description'),
                  onChanged: (_) => _scheduleTextSave(),
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
                      key: const ValueKey('site-product-price'),
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: moneyIdrInputFormatters,
                      style: const TextStyle(color: _text, fontSize: 13),
                      decoration: siteEditorInputDecoration(hintText: '0').copyWith(
                        suffixText: 'IDR',
                        suffixStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 12),
                      ),
                      onChanged: (_) => _scheduleTextSave(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: UiSiteEditorLabeledField(
                    label: 'Unit',
                    child: TextField(
                      key: const ValueKey('site-product-unit'),
                      controller: _unitCtrl,
                      style: const TextStyle(color: _text, fontSize: 13),
                      decoration: siteEditorInputDecoration(hintText: 'pcs, plate…'),
                      onChanged: (_) => _scheduleTextSave(),
                    ),
                  ),
                ),
              ],
            ),
            UiSiteEditorLabeledField(
              label: 'Category',
              child: InSiteProductCategory(
                value: product.category,
                categories: siteProductCategoryLabels(widget.productsById.values.map((p) => p.category)),
                enabled: !widget.busy,
                onCommit: (v) => _saveProduct(product.clone()..category = v),
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
                key: const ValueKey('site-product-sku'),
                controller: _skuCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: siteEditorInputDecoration(hintText: 'Internal code'),
                onChanged: (_) => _scheduleTextSave(),
              ),
            ),
            UiSiteEditorLabeledField(
              label: 'Barcodes',
              child: InStringList(
                key: ValueKey('site-product-barcodes-$productId'),
                values: siteProductBarcodesRead(product),
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
              key: ValueKey('site-product-alt-$productId'),
              values: _altNames(),
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
              onChanged: widget.busy ? null : (v) => unawaited(_setTrackStock(product, v)),
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
                if (col.key != 'track_stock' && (col.key != 'can_reserve' || widget.booking))
                  UiSiteEditorSwitchRow(
                    label: col.key == 'can_reserve' ? 'Can reserve' : col.label,
                    value: _parseBool(cells[col.key] ?? ''),
                    onChanged: widget.busy ? null : (v) => _commitProductField(product, col, v ? 'yes' : 'no'),
                  ),
            ],
          ),
        if (widget.booking && product.canReserve) _reservationSection(product),
        if (widget.busy || _textSaveActive)
          const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
      ],
    );
  }
}

class _ProductPicTile extends StatelessWidget {
  const _ProductPicTile({
    required this.pic,
    required this.previewBytes,
    required this.uploading,
    required this.icon,
    required this.busy,
    required this.onTap,
    required this.onGenerate,
  });

  static const _side = 88.0;

  final String pic;
  final Uint8List? previewBytes;
  final bool uploading;
  final String icon;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onGenerate;

  bool get _locked => busy || uploading;

  Widget _imageContent() {
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return Image.memory(previewBytes!, width: _side, height: _side, fit: BoxFit.cover);
    }
    if (pic.isEmpty) {
      return Center(
        child: UiIcon(
          'iconify://${icon.trim().isEmpty ? 'mdi:shopping' : icon.trim()}',
          size: 36,
          color: _muted,
        ),
      );
    }
    return UiImg(
      src: pic,
      width: _side,
      height: _side,
      fit: BoxFit.cover,
      fallback: const Icon(Icons.broken_image_outlined, color: _muted),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ring = 3.0;
    return SizedBox(
      width: _side + ring * 2,
      height: _side + ring * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (uploading)
            SizedBox(
              width: _side + ring * 2,
              height: _side + ring * 2,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent),
            ),
          Material(
            color: siteEditorFieldFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.9)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _locked ? null : onTap,
              child: SizedBox(
                width: _side,
                height: _side,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _imageContent(),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: InkWell(
                        onTap: _locked ? null : onGenerate,
                        borderRadius: BorderRadius.circular(6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(6)),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: UiAlienIcon(size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
