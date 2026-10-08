import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _fieldBorder = Color(0xFF3F3F46);
const _accent = Color(0xFF34D399);

IconData _objectKindIcon(String kind) => switch (kind) {
      siteObjectKindTable => Icons.table_restaurant_outlined,
      siteObjectKindRoom => Icons.meeting_room_outlined,
      _ => Icons.category_outlined,
    };

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
      _byId
        ..clear()
        ..addEntries(items.map((o) => MapEntry('${o.id}', o)));
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
            o.kind.toLowerCase().contains(q))
        .toList(growable: false);
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
          onAdd: _add,
          addBusy: _busy,
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
                    final subtitle = [if (o.code.isNotEmpty) o.code, if (o.kind.isNotEmpty) siteObjectKindLabel(o.kind)].join(' · ');
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF27272A) : const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _fieldBorder.withValues(alpha: 0.7)),
                                ),
                                child: Icon(_objectKindIcon(o.kind), size: 18, color: active ? _accent : _muted),
                              ),
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
    return _UiSiteObjectDetailForm(objectId: id, object: object, onPatch: _patch);
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

class _UiSiteObjectDetailForm extends StatefulWidget {
  const _UiSiteObjectDetailForm({required this.objectId, required this.object, required this.onPatch});

  final String objectId;
  final SiteObject object;
  final void Function(String id, void Function(SiteObject o) fn) onPatch;

  @override
  State<_UiSiteObjectDetailForm> createState() => _UiSiteObjectDetailFormState();
}

class _UiSiteObjectDetailFormState extends State<_UiSiteObjectDetailForm> {
  late final _nameCtrl = TextEditingController(text: widget.object.name);
  late final _codeCtrl = TextEditingController(text: widget.object.code);
  late final _descCtrl = TextEditingController(text: widget.object.desc);
  late String _kind = widget.object.kind.isEmpty ? siteObjectKindTable : widget.object.kind;

  @override
  void didUpdateWidget(covariant _UiSiteObjectDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectId != widget.objectId) {
      _nameCtrl.text = widget.object.name;
      _codeCtrl.text = widget.object.code;
      _descCtrl.text = widget.object.desc;
      _kind = widget.object.kind.isEmpty ? siteObjectKindTable : widget.object.kind;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController ctrl, void Function(String v) onChanged, {int maxLines = 1}) => UiSiteEditorLabeledField(
        label: label,
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _text),
          decoration: siteEditorInputDecoration(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final id = widget.objectId;
    final o = widget.object;
    return UiSiteEditorFormScroll(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fieldBorder),
              ),
              child: Icon(_objectKindIcon(o.kind), color: _accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(o.name.isEmpty ? 'Object' : o.name, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w600)),
                  Text('ID $id', style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        UiSiteEditorFormSection(
          title: 'Identity',
          children: [
            _field('Name', _nameCtrl, (v) => widget.onPatch(id, (o) => o.name = v)),
            _field('Code', _codeCtrl, (v) => widget.onPatch(id, (o) => o.code = v)),
            UiSiteEditorLabeledField(
              label: 'Kind',
              child: DropdownButtonFormField<String>(
                initialValue: siteObjectKindValues.contains(_kind) ? _kind : siteObjectKindOther,
                decoration: siteEditorInputDecoration(),
                dropdownColor: const Color(0xFF18181B),
                style: const TextStyle(fontSize: 13, color: _text),
                items: siteObjectKindValues
                    .map((k) => DropdownMenuItem(value: k, child: Text(siteObjectKindLabel(k))))
                    .toList(growable: false),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _kind = v);
                  widget.onPatch(id, (o) => o.kind = v);
                },
              ),
            ),
            _field('Description', _descCtrl, (v) => widget.onPatch(id, (o) => o.desc = v), maxLines: 3),
          ],
        ),
        UiSiteEditorFormSection(
          title: 'Capabilities',
          children: [
            UiSiteEditorSwitchRow(label: 'Can order', value: o.canOrder, onChanged: (v) => widget.onPatch(id, (o) => o.canOrder = v)),
            UiSiteEditorSwitchRow(label: 'Can be reserved', value: o.canBeReserved, onChanged: (v) => widget.onPatch(id, (o) => o.canBeReserved = v)),
            UiSiteEditorSwitchRow(label: 'Active', value: o.isActive, onChanged: (v) => widget.onPatch(id, (o) => o.isActive = v)),
          ],
        ),
      ],
    );
  }
}
