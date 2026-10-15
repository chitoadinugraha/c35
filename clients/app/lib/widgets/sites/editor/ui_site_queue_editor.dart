import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_listener.dart';
import 'package:alienai_c35/c/site/site_queue_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_queue_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _border = Color(0xFF3F3F46);

class UiSiteQueueEditor extends StatefulWidget {
  const UiSiteQueueEditor({
    super.key,
    required this.api,
    required this.siteIid,
    this.queueEnabled = true,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteApi api;
  final int siteIid;
  final bool queueEnabled;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteQueueEditor> createState() => _UiSiteQueueEditorState();
}

class _UiSiteQueueEditorState extends State<UiSiteQueueEditor> with SiteEditorCatalogListener {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  final _byId = <String, SiteQueue>{};
  var _loadScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteQueueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _byId[_selectedId] == null) _pickDefault();
  }

  List<SiteQueue> get _ordered => siteQueuesSorted(_byId.values.toList());

  List<SiteQueue> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ordered;
    return _ordered
        .where((item) {
          final meta = siteQueueMetaOf(item);
          return item.name.toLowerCase().contains(q) ||
              item.prefix.toLowerCase().contains(q) ||
              meta.description.toLowerCase().contains(q);
        })
        .toList();
  }

  String? get _firstId => _ordered.isEmpty ? null : '${_ordered.first.queueId}';

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
      ..addEntries(catalog.queues.map((q) => MapEntry('${q.queueId}', q)));
    _pickDefault();
    if (mounted) {
      setState(() {
        _loading = false;
        if (catalog.warmError != null && _byId.isEmpty) {
          _error = uiFriendlyError(catalog.warmError!);
        }
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
      final items = await widget.api.queueList(widget.siteIid);
      editorCatalog?.setQueues(items);
      _byId
        ..clear()
        ..addEntries(items.map((q) => MapEntry('${q.queueId}', q)));
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
      final draft = widget.api.queueNew(widget.siteIid, existing: _ordered);
      final saved = await widget.api.queuePut(widget.siteIid, draft);
      final id = '${saved.queueId}';
      _byId[id] = saved;
      editorCatalog?.upsertQueue(saved);
      _searchCtrl.clear();
      setState(() => _search = '');
      _select(id);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _put(String id, SiteQueue draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.queuePut(widget.siteIid, draft);
      if (!mounted) return;
      final savedId = '${saved.queueId}';
      setState(() {
        _byId.remove(id);
        _byId[savedId] = saved;
        if (_selectedId == id) _selectedId = savedId;
        _error = null;
      });
      editorCatalog?.upsertQueue(saved);
      if (!widget.masterDetail && widget.detailId == id && widget.detailId != savedId) {
        widget.onDetailIdChanged?.call(savedId);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SiteQueue q) fn) {
    final base = _byId[id];
    if (base == null) return;
    final next = base.clone();
    fn(next);
    setState(() => _byId[id] = next);
    unawaited(_put(id, next));
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final queueId = int.tryParse(id);
    if (queueId == null || queueId <= 0) return;
    setState(() => _busy = true);
    try {
      final row = _byId[id]?.clone();
      if (row != null) {
        row.isActive = false;
        await widget.api.queuePut(widget.siteIid, row);
      }
      _byId.remove(id);
      editorCatalog?.removeQueue(queueId);
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
    final items = [..._filtered];
    if (oldIndex < 0 || oldIndex >= items.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0 || target >= items.length) return;
    final moved = items.removeAt(oldIndex);
    items.insert(target, moved);
    setState(() => _busy = true);
    try {
      for (var i = 0; i < items.length; i++) {
        final meta = siteQueueMetaOf(items[i]);
        if (meta.sortOrder == i) continue;
        final next = items[i].clone();
        siteQueueApplyMeta(next, meta.copyWith(sortOrder: i));
        _byId['${next.queueId}'] = next;
        await widget.api.queuePut(widget.siteIid, next);
      }
      if (mounted) {
        editorCatalog?.setQueues(_ordered);
        setState(() => _error = null);
      }
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _listPane({required String? selectedId}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Manage guest take-a-number counters. Drag to reorder.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
            ),
          ),
          UiSiteCatalogToolbar(
            searchController: _searchCtrl,
            hintText: 'Search counters',
            onSearchChanged: (v) => setState(() => _search = v),
            onAdd: () => unawaited(_add()),
            addBusy: _busy,
            addTooltip: 'Add counter',
          ),
          Expanded(child: _queueList(selectedId: selectedId)),
        ],
      );

  Widget _queueList({required String? selectedId}) {
    final items = _filtered;
    if (items.isEmpty) {
      final empty = _search.trim().isEmpty
          ? const UiEmptyState(
              icon: Icons.queue_outlined,
              title: 'No counters yet',
              subtitle: 'Add a counter so guests can take a ticket on your site.',
              actionHint: 'Tap + to add',
            )
          : UiEmptyState.noMatches('counters');
      return Center(child: empty);
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) => _reorder(oldIndex, newIndex),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = '${item.queueId}';
        final ticket = siteQueueTicketPreview(item, ticketNo: item.servingTicketNo > 0 ? item.servingTicketNo : 1);
        final selected = id == selectedId;
        return Padding(
          key: ValueKey(id),
          padding: const EdgeInsets.only(bottom: 8),
          child: ReorderableDragStartListener(
            index: index,
            child: Material(
              color: selected ? _accent.withValues(alpha: 0.12) : const Color(0xFF18181B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: selected ? _accent : _border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _select(id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.drag_handle, size: 18, color: _muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.isNotEmpty ? item.name : 'Counter ${item.queueId}',
                              style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(color: _muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ticket,
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!widget.masterDetail)
                        Switch(
                          value: item.isActive,
                          onChanged: _busy ? null : (v) => _patch(id, (q) => q.isActive = v),
                          activeThumbColor: _accent,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailPane(String id) {
    final queue = _byId[id];
    if (queue == null) {
      return const Center(child: Text('Counter not found', style: TextStyle(color: _muted)));
    }
    return UiSiteQueueDetail(
      api: widget.api,
      siteIid: widget.siteIid,
      queueId: id,
      queue: queue,
      busy: _busy,
      onPatch: (fn) => _patch(id, fn),
      onDelete: () => _delete(id),
      onSaved: (saved) {
        final savedId = '${saved.queueId}';
        setState(() => _byId[savedId] = saved);
        editorCatalog?.upsertQueue(saved);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.queueEnabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Queue is off for this site. Turn it on under Settings → Capabilities to use take-a-number on the storefront.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }
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
