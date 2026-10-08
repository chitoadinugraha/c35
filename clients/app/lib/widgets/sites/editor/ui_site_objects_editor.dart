import 'dart:async';
import 'dart:math' as math;

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/files/file_path.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/io/in_site_product.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_object_batch_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _fieldBorder = Color(0xFF3F3F46);
const _accent = Color(0xFF34D399);

Future<void> showSiteObjectEditDialog(
  BuildContext context, {
  required SiteApi api,
  required int siteIid,
  required SiteObject object,
  required List<SiteProduct> reservableProducts,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => _SiteObjectEditDialog(
        api: api,
        siteIid: siteIid,
        object: object,
        reservableProducts: reservableProducts,
      ),
    );

class UiSiteObjectsEditor extends StatefulWidget {
  const UiSiteObjectsEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteObjectsEditor> createState() => _UiSiteObjectsEditorState();
}

class _UiSiteObjectsEditorState extends State<UiSiteObjectsEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  final _byId = <String, SiteObject>{};
  final _debounceTimers = <String, Timer>{};
  List<SiteProduct> _products = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteObjectsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _byId[_selectedId] == null) _pickDefault();
  }

  List<SiteProduct> get _reservable => _products.where((p) => p.canReserve).toList(growable: false);

  SiteProduct? _productFor(SiteObject o) {
    final id = o.productId.toInt();
    if (id == 0) return null;
    for (final p in _products) {
      if (p.productId.toInt() == id) return p;
    }
    return null;
  }

  String _rowPic(SiteObject o) {
    if (o.pic.isNotEmpty) return o.pic;
    return _productFor(o)?.pic ?? '';
  }

  String _productSubtitle(SiteObject o) {
    final p = _productFor(o);
    if (p == null) return '';
    return p.name.isNotEmpty ? p.name : 'Product ${p.productId}';
  }

  List<SiteObject> get _ordered {
    final items = _byId.values.toList();
    items.sort((a, b) {
      final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return c != 0 ? c : a.code.toLowerCase().compareTo(b.code.toLowerCase());
    });
    return items;
  }

  String? get _firstId => _ordered.isEmpty ? null : '${_ordered.first.id}';

  String? get _activeId => widget.masterDetail ? (_selectedId ?? _firstId) : widget.detailId;

  void _pickDefault() {
    if (_byId.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || _byId[_selectedId] == null) _selectedId = _firstId;
      return;
    }
    if (widget.detailId != null && _byId[widget.detailId] == null) {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.objectList(widget.siteIid);
      List<SiteProduct> products = _products;
      try {
        products = await widget.api.productList(widget.siteIid);
      } catch (e) {
        _error = uiFriendlyError(e);
      }
      _byId
        ..clear()
        ..addEntries(items.map((o) => MapEntry('${o.id}', o)));
      _products = products;
      _pickDefault();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final o = await widget.api.objectPut(widget.siteIid, widget.api.objectNew(widget.siteIid));
      _byId['${o.id}'] = o;
      _searchCtrl.clear();
      setState(() => _search = '');
      _select('${o.id}');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMany() async {
    if (_busy || !mounted) return;
    var products = _products;
    if (products.isEmpty) {
      try {
        products = await widget.api.productList(widget.siteIid);
        if (mounted) setState(() => _products = products);
      } catch (e) {
        if (mounted) setState(() => _error = uiFriendlyError(e));
        return;
      }
    }
    if (!mounted) return;
    final picked = await inSiteProductPick(
      context,
      products: {for (final p in products) '${p.productId}': p},
      reservableOnly: true,
    );
    if (picked == null || !mounted) return;
    final count = await showSiteObjectBatchDialog(
      context,
      api: widget.api,
      siteIid: widget.siteIid,
      product: picked,
    );
    if (count != null && count > 0 && mounted) await _load();
  }

  void _debouncedPut(String id, SiteObject draft) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 450), () => unawaited(_put(id, draft)));
  }

  Future<void> _put(String id, SiteObject draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.objectPut(widget.siteIid, draft);
      if (!mounted) return;
      setState(() {
        _byId.remove(id);
        _byId['${saved.id}'] = saved;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SiteObject o) fn) {
    final base = _byId[id];
    if (base == null) return;
    final next = base.clone();
    fn(next);
    setState(() => _byId[id] = next);
    _debouncedPut(id, next);
  }

  List<SiteObject> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ordered;
    return _ordered
        .where((o) =>
            o.name.toLowerCase().contains(q) ||
            o.code.toLowerCase().contains(q) ||
            o.kind.toLowerCase().contains(q) ||
            _productSubtitle(o).toLowerCase().contains(q))
        .toList(growable: false);
  }

  Widget _thumb(SiteObject o, {required bool active}) {
    final pic = _rowPic(o);
    final icon = Icon(siteObjectKindIcon(o.kind), size: 18, color: active ? _accent : _muted);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF27272A) : const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _fieldBorder.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: pic.isEmpty ? icon : UiImg(src: pic, width: 36, height: 36, fit: BoxFit.cover, fallback: icon),
    );
  }

  Widget _listPane({required String? selectedId}) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search objects',
          onSearchChanged: (v) => setState(() => _search = v),
          addTooltip: 'Add',
          addBusy: _busy,
          menuItems: [
            SiteCatalogMenuItem(value: 'add', label: 'Add', leading: const Icon(Icons.add, size: 18), enabled: !_busy),
            SiteCatalogMenuItem(
              value: 'add-many',
              label: 'Add many',
              leading: const Icon(Icons.library_add_outlined, size: 18),
              enabled: !_busy,
            ),
          ],
          onMenuAction: (action) {
            if (action == 'add') unawaited(_add());
            if (action == 'add-many') unawaited(_addMany());
          },
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.table_restaurant_outlined, title: 'No objects', subtitle: 'Add a table, room, or unit')
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final o = filtered[i];
                    final id = '${o.id}';
                    final active = selectedId == id;
                    final subtitle = _productSubtitle(o);
                    return Material(
                      color: active ? const Color(0xFF1F2937) : Colors.transparent,
                      child: InkWell(
                        onTap: () => _select(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: active ? _accent : Colors.transparent, width: 3),
                              bottom: BorderSide(color: _border.withValues(alpha: 0.6)),
                            ),
                          ),
                          child: Row(
                            children: [
                              _thumb(o, active: active),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.name.isEmpty ? 'Object' : o.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 13,
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty)
                                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (o.canBeReserved)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.event_available_outlined, size: 16, color: _accent),
                                ),
                              if (!o.isActive)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Text('Inactive', style: TextStyle(color: _muted, fontSize: 10)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _detailPane(String id) {
    final object = _byId[id];
    if (object == null) {
      return const Center(child: Text('Object not found', style: TextStyle(color: _muted)));
    }
    return _SiteObjectDetailForm(
      key: ValueKey(id),
      objectId: id,
      object: object,
      reservableProducts: _reservable,
      onPatch: (fn) => _patch(id, fn),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    if (_error != null && _byId.isEmpty) {
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

    final detailId = _activeId;
    final Widget body;
    if (widget.masterDetail && _byId.isNotEmpty) {
      final selected = detailId ?? _firstId!;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detailPane(selected)),
        ],
      );
    } else {
      body = widget.masterDetail || detailId == null ? _listPane(selectedId: detailId) : _detailPane(detailId);
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

class _SiteObjectEditDialog extends StatefulWidget {
  const _SiteObjectEditDialog({
    required this.api,
    required this.siteIid,
    required this.object,
    required this.reservableProducts,
  });

  final SiteApi api;
  final int siteIid;
  final SiteObject object;
  final List<SiteProduct> reservableProducts;

  @override
  State<_SiteObjectEditDialog> createState() => _SiteObjectEditDialogState();
}

class _SiteObjectEditDialogState extends State<_SiteObjectEditDialog> {
  late SiteObject _draft = widget.object.clone();
  var _saving = false;
  var _error = '';

  void _patch(void Function(SiteObject o) fn) {
    final next = _draft.clone();
    fn(next);
    setState(() => _draft = next);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await widget.api.objectPut(widget.siteIid, _draft);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = math.min(560.0, MediaQuery.sizeOf(context).height * 0.7);
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text(_draft.name.isEmpty ? 'Edit object' : _draft.name, style: const TextStyle(color: _text, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      content: SizedBox(
        width: 480,
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SiteObjectDetailForm(
                objectId: '${_draft.id}',
                object: _draft,
                reservableProducts: widget.reservableProducts,
                busy: _saving,
                onPatch: _patch,
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(_error, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _SiteObjectDetailForm extends StatefulWidget {
  const _SiteObjectDetailForm({
    super.key,
    required this.objectId,
    required this.object,
    required this.reservableProducts,
    required this.onPatch,
    this.busy = false,
  });

  final String objectId;
  final SiteObject object;
  final List<SiteProduct> reservableProducts;
  final void Function(void Function(SiteObject o) fn) onPatch;
  final bool busy;

  @override
  State<_SiteObjectDetailForm> createState() => _SiteObjectDetailFormState();
}

class _SiteObjectDetailFormState extends State<_SiteObjectDetailForm> {
  late final _nameCtrl = TextEditingController(text: widget.object.name);
  late final _descCtrl = TextEditingController(text: widget.object.desc);
  late String _kind = widget.object.kind.isEmpty ? siteObjectKindTable : widget.object.kind;
  var _uploading = false;

  @override
  void didUpdateWidget(covariant _SiteObjectDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectId != widget.objectId) {
      _nameCtrl.text = widget.object.name;
      _descCtrl.text = widget.object.desc;
      _kind = widget.object.kind.isEmpty ? siteObjectKindTable : widget.object.kind;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.object.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  Future<void> _pickPic() async {
    if (_uploading || widget.busy) return;
    final staged = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false, maxCount: 1);
    if (staged == null || staged.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    try {
      final file = staged.first;
      final up = await casUpload(bytes: file.bytes, mime: file.mime, name: file.name);
      if (up == null || up.hash.isEmpty) throw 'upload failed';
      final pic = fileStoragePath(up.hash);
      widget.onPatch((o) => o.pic = pic);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  List<DropdownMenuItem<int>> _productItems() {
    final selected = widget.object.productId.toInt();
    final items = <DropdownMenuItem<int>>[const DropdownMenuItem(value: 0, child: Text('None'))];
    final seen = <int>{0};
    if (selected > 0 && !widget.reservableProducts.any((p) => p.productId.toInt() == selected)) {
      items.add(DropdownMenuItem(value: selected, child: Text('Product $selected')));
      seen.add(selected);
    }
    for (final p in widget.reservableProducts) {
      final id = p.productId.toInt();
      if (id <= 0 || !seen.add(id)) continue;
      items.add(DropdownMenuItem(
        value: id,
        child: Text(p.name.isNotEmpty ? p.name : 'Product $id', overflow: TextOverflow.ellipsis),
      ));
    }
    return items;
  }

  Widget _field(String label, TextEditingController ctrl, void Function(String v) onChanged, {int maxLines = 1}) => UiSiteEditorLabeledField(
        label: label,
        child: TextField(
          controller: ctrl,
          onChanged: widget.busy ? null : onChanged,
          readOnly: widget.busy,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _text),
          decoration: siteEditorInputDecoration(),
        ),
      );

  Widget _picTile() {
    final pic = widget.object.pic;
    final locked = widget.busy || _uploading;
    return Material(
      color: siteEditorFieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : _pickPic,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_uploading)
                const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)))
              else if (pic.isEmpty)
                Center(child: Icon(siteObjectKindIcon(widget.object.kind), color: _muted, size: 28))
              else
                UiImg(src: pic, fit: BoxFit.cover, fallback: Icon(siteObjectKindIcon(widget.object.kind), color: _muted)),
              const Positioned(
                right: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x8C000000), borderRadius: BorderRadius.all(Radius.circular(6))),
                  child: Padding(
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

  @override
  Widget build(BuildContext context) {
    final o = widget.object;
    final kind = siteObjectKindValues.contains(_kind) ? _kind : siteObjectKindOther;
    final productId = o.productId.toInt() < 0 ? 0 : o.productId.toInt();
    return UiSiteEditorFormScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _picTile(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(o.name.isEmpty ? 'Object' : o.name, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600)),
                  Text('ID ${widget.objectId}', style: const TextStyle(color: _muted, fontSize: 11)),
                  if (o.pic.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: widget.busy ? null : () => widget.onPatch((obj) => obj.pic = ''),
                        child: const Text('Clear'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        UiSiteEditorFormSection(
          title: 'Identity',
          children: [
            _field('Name', _nameCtrl, (v) => widget.onPatch((obj) => obj.name = v)),
            UiSiteEditorLabeledField(
              label: 'Code',
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: _text,
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: _fieldBorder),
                    ),
                  ),
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy_outlined, size: 16, color: _muted),
                  label: Text(o.code.isEmpty ? 'Copy code' : o.code, style: const TextStyle(fontSize: 13, color: _text)),
                ),
              ),
            ),
            UiSiteEditorLabeledField(
              label: 'Kind',
              child: DropdownButtonFormField<String>(
                key: ValueKey('kind-${widget.objectId}'),
                initialValue: kind,
                decoration: siteEditorInputDecoration(),
                dropdownColor: const Color(0xFF18181B),
                style: const TextStyle(fontSize: 13, color: _text),
                items: [
                  for (final k in siteObjectKindValues)
                    DropdownMenuItem(
                      value: k,
                      child: Row(
                        children: [
                          Icon(siteObjectKindIcon(k), size: 18, color: _muted),
                          const SizedBox(width: 8),
                          Text(siteObjectKindLabel(k)),
                        ],
                      ),
                    ),
                ],
                onChanged: widget.busy
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _kind = v);
                        widget.onPatch((obj) => obj.kind = v);
                      },
              ),
            ),
            UiSiteEditorLabeledField(
              label: 'Product',
              child: DropdownButtonFormField<int>(
                key: ValueKey('product-${widget.objectId}-$productId'),
                initialValue: productId,
                isExpanded: true,
                decoration: siteEditorInputDecoration(),
                dropdownColor: const Color(0xFF18181B),
                style: const TextStyle(fontSize: 13, color: _text),
                items: _productItems(),
                onChanged: widget.busy
                    ? null
                    : (v) {
                        if (v == null) return;
                        widget.onPatch((obj) => obj.productId = Int64(v));
                      },
              ),
            ),
            _field('Description', _descCtrl, (v) => widget.onPatch((obj) => obj.desc = v), maxLines: 3),
          ],
        ),
        UiSiteEditorFormSection(
          title: 'Capabilities',
          children: [
            UiSiteEditorSwitchRow(
              label: 'Can order',
              value: o.canOrder,
              onChanged: widget.busy ? null : (v) => widget.onPatch((obj) => obj.canOrder = v),
            ),
            UiSiteEditorSwitchRow(
              label: 'Can be reserved',
              value: o.canBeReserved,
              onChanged: widget.busy ? null : (v) => widget.onPatch((obj) => obj.canBeReserved = v),
            ),
            UiSiteEditorSwitchRow(
              label: 'Active',
              value: o.isActive,
              onChanged: widget.busy ? null : (v) => widget.onPatch((obj) => obj.isActive = v),
            ),
          ],
        ),
      ],
    );
  }
}
