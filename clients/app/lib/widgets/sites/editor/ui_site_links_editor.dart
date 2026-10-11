import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_listener.dart';
import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/c/site/site_editor_preview_patch.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_link_detail.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_links_section.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSiteLinksEditor extends StatefulWidget {
  const UiSiteLinksEditor({
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
  State<UiSiteLinksEditor> createState() => _UiSiteLinksEditorState();
}

class _UiSiteLinksEditorState extends State<UiSiteLinksEditor> with SiteEditorCatalogListener {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  final _byId = <String, SiteLink>{};
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _byId[_selectedId] == null) _pickDefault();
  }

  List<SiteLink> get _ordered {
    final items = _byId.values.toList();
    items.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.linkId.compareTo(b.linkId);
    });
    return items;
  }

  String? get _firstId => _ordered.isEmpty ? null : '${_ordered.first.linkId}';

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

  @override
  void onEditorCatalogUpdated(SiteEditorCatalogCache catalog) {
    _byId
      ..clear()
      ..addEntries(catalog.links.map((l) => MapEntry('${l.linkId}', l)));
    _pickDefault();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = catalog.warmError != null ? uiFriendlyError(catalog.warmError!) : null;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (await ensureEditorCatalog()) return;
      final items = await widget.api.linkList(widget.siteIid);
      editorCatalog?.setLinks(items);
      _byId
        ..clear()
        ..addEntries(items.map((l) => MapEntry('${l.linkId}', l)));
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
      final sort = _ordered.isEmpty ? 0 : _ordered.last.sortOrder + 1;
      final link = widget.api.linkNew(widget.siteIid)..sortOrder = sort;
      final saved = await widget.api.linkPut(widget.siteIid, link);
      final id = '${saved.linkId}';
      _byId[id] = saved;
      editorCatalog?.upsertLink(saved);
      _searchCtrl.clear();
      setState(() => _search = '');
      _select(id);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _debouncedPut(String id, SiteLink draft) {
    siteEditorScheduleSave(
      context,
      key: 'link:$id',
      debounce: const Duration(milliseconds: 450),
      save: () => _put(id, draft),
    );
  }

  Future<void> _put(String id, SiteLink draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.linkPut(widget.siteIid, draft);
      if (!mounted) return;
      final savedId = '${saved.linkId}';
      setState(() {
        _byId.remove(id);
        _byId[savedId] = saved;
        if (_selectedId == id) _selectedId = savedId;
        _error = null;
      });
      editorCatalog?.upsertLink(saved);
      if (!widget.masterDetail && widget.detailId == id && widget.detailId != savedId) {
        widget.onDetailIdChanged?.call(savedId);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SiteLink l) fn) {
    final base = _byId[id];
    if (base == null) return;
    final next = base.clone();
    fn(next);
    setState(() => _byId[id] = next);
    siteEditorPreviewPatch(context, (boot) => siteEditorPreviewUpsertLink(boot, next));
    _debouncedPut(id, next);
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final linkId = int.tryParse(id);
    if (linkId == null || linkId <= 0) return;
    setState(() => _busy = true);
    try {
      await widget.api.linkDelete(widget.siteIid, linkId);
      _byId.remove(id);
      editorCatalog?.removeLink(linkId);
      siteEditorPreviewPatch(context, (boot) => siteEditorPreviewRemoveLink(boot, linkId));
      _pickDefault();
      if (widget.masterDetail) {
        if (mounted) setState(() => _error = null);
      } else {
        widget.onDetailIdChanged?.call(null);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_busy || _search.trim().isNotEmpty) return;
    final items = [..._ordered];
    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex > items.length) return;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _busy = true);
    try {
      final saves = <Future<SiteLink>>[];
      for (var i = 0; i < items.length; i++) {
        if (items[i].sortOrder == i) continue;
        final next = items[i].clone()..sortOrder = i;
        _byId['${next.linkId}'] = next;
        saves.add(widget.api.linkPut(widget.siteIid, next));
      }
      if (saves.isNotEmpty) await Future.wait(saves);
      if (mounted) {
        editorCatalog?.setLinks(_ordered);
        siteEditorPreviewPatch(context, (boot) => siteEditorPreviewSetLinks(boot, _ordered));
        setState(() => _error = null);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onListActiveChanged(String id, bool active) => _patch(id, (l) => l.active = active);

  Widget _listPane({required String? selectedId}) => UiSiteLinksSection(
        searchController: _searchCtrl,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
        links: _ordered,
        selectedId: selectedId,
        onSelect: _select,
        onAdd: () => unawaited(_add()),
        addBusy: _busy,
        onReorder: _reorder,
        onActiveChanged: _onListActiveChanged,
        showListActive: !widget.masterDetail,
      );

  Widget _detailPane(String id) {
    final link = _byId[id];
    if (link == null) {
      return const Center(child: Text('Link not found', style: TextStyle(color: _muted)));
    }
    return UiSiteLinkDetail(
      link: link,
      busy: _busy,
      onPatch: _patch,
      onDelete: () => unawaited(_delete(id)),
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
