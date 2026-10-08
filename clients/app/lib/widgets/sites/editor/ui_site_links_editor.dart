import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _fieldBorder = Color(0xFF3F3F46);
const _fieldFill = Color(0xFF18181B);

class UiSiteLinksEditor extends StatefulWidget {
  const UiSiteLinksEditor({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteLinksEditor> createState() => _UiSiteLinksEditorState();
}

class _UiSiteLinksEditorState extends State<UiSiteLinksEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  final _links = <SiteLink>[];
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
  void didUpdateWidget(covariant UiSiteLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
  }

  List<SiteLink> get _ordered {
    final items = [..._links];
    items.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.linkId.compareTo(b.linkId);
    });
    return items;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _links
        ..clear()
        ..addAll(await widget.api.linkList(widget.siteIid));
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
      _links.add(saved);
      _searchCtrl.clear();
      setState(() => _search = '');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _debouncedPut(String id, SiteLink draft) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 450), () => unawaited(_put(id, draft)));
  }

  Future<void> _put(String id, SiteLink draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.linkPut(widget.siteIid, draft);
      if (!mounted) return;
      final idx = _links.indexWhere((l) => '${l.linkId}' == id);
      if (idx >= 0) _links[idx] = saved;
      setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SiteLink l) fn) {
    final idx = _links.indexWhere((l) => '${l.linkId}' == id);
    if (idx < 0) return;
    final next = _links[idx].clone();
    fn(next);
    setState(() => _links[idx] = next);
    _debouncedPut(id, next);
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final linkId = int.tryParse(id);
    if (linkId == null || linkId <= 0) return;
    setState(() => _busy = true);
    try {
      await widget.api.linkDelete(widget.siteIid, linkId);
      _links.removeWhere((l) => '${l.linkId}' == id);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<SiteLink> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ordered;
    return _ordered
        .where((l) => l.label.toLowerCase().contains(q) || l.url.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }

    final filtered = _filtered;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search links',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _add,
          addBusy: _busy,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.link, title: 'No links', subtitle: 'Add a hub link for your storefront')
              : UiSiteEditorFormScroll(
                  children: [
                    for (final link in filtered)
                      _UiSiteLinkCard(
                        key: ValueKey('${link.linkId}'),
                        link: link,
                        busy: _busy,
                        onPatch: _patch,
                        onDelete: _delete,
                      ),
                  ],
                ),
        ),
      ],
    );

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

class _UiSiteLinkCard extends StatefulWidget {
  const _UiSiteLinkCard({super.key, required this.link, required this.busy, required this.onPatch, required this.onDelete});

  final SiteLink link;
  final bool busy;
  final void Function(String id, void Function(SiteLink l) fn) onPatch;
  final Future<void> Function(String id) onDelete;

  @override
  State<_UiSiteLinkCard> createState() => _UiSiteLinkCardState();
}

class _UiSiteLinkCardState extends State<_UiSiteLinkCard> {
  late final _labelCtrl = TextEditingController(text: widget.link.label);
  late final _urlCtrl = TextEditingController(text: widget.link.url);
  late final _iconCtrl = TextEditingController(text: widget.link.icon);

  @override
  void didUpdateWidget(covariant _UiSiteLinkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.link.linkId}' != '${widget.link.linkId}') {
      _labelCtrl.text = widget.link.label;
      _urlCtrl.text = widget.link.url;
      _iconCtrl.text = widget.link.icon;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF34D399))),
      );

  Widget _field(String label, TextEditingController ctrl, void Function(String v) onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: _text),
              decoration: _decoration(),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final id = '${widget.link.linkId}';
    final link = widget.link;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF121216),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(link.label.isEmpty ? 'Link' : link.label, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600))),
              IconButton(
                onPressed: widget.busy ? null : () => unawaited(widget.onDelete(id)),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
              ),
            ],
          ),
          _field('Label', _labelCtrl, (v) => widget.onPatch(id, (l) => l.label = v)),
          _field('URL', _urlCtrl, (v) => widget.onPatch(id, (l) => l.url = v)),
          _field('Icon', _iconCtrl, (v) => widget.onPatch(id, (l) => l.icon = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pinned', style: TextStyle(color: _text, fontSize: 13)),
            value: link.isPinned,
            activeThumbColor: const Color(0xFF34D399),
            onChanged: widget.busy ? null : (v) => widget.onPatch(id, (l) => l.isPinned = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active', style: TextStyle(color: _text, fontSize: 13)),
            value: link.active,
            activeThumbColor: const Color(0xFF34D399),
            onChanged: widget.busy ? null : (v) => widget.onPatch(id, (l) => l.active = v),
          ),
        ],
      ),
    );
  }
}
