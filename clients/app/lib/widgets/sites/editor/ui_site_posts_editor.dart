import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_post_detail.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_posts_section.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSitePostsEditor extends StatefulWidget {
  const UiSitePostsEditor({
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
  State<UiSitePostsEditor> createState() => _UiSitePostsEditorState();
}

class _UiSitePostsEditorState extends State<UiSitePostsEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _selectedId;
  final _byId = <String, SitePost>{};

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
  void didUpdateWidget(covariant UiSitePostsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (_selectedId != null && _byId[_selectedId] == null) _pickDefault();
  }

  List<SitePost> get _ordered {
    final items = _byId.values.toList();
    items.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.postId.compareTo(b.postId);
    });
    return items;
  }

  String? get _firstId => _ordered.isEmpty ? null : '${_ordered.first.postId}';

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
      final items = await widget.api.sitePostList(widget.siteIid);
      _byId
        ..clear()
        ..addEntries(items.map((p) => MapEntry('${p.postId}', p)));
      _pickDefault();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _put(SitePost draft) async {
    setState(() => _busy = true);
    try {
      final saved = await widget.api.sitePostPut(widget.siteIid, draft);
      if (!mounted) return;
      _byId['${saved.postId}'] = saved;
      setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sort = _ordered.isEmpty ? 0 : _ordered.last.sortOrder + 1;
      final post = SitePost(siteIid: Int64(widget.siteIid), title: 'New post', sortOrder: sort);
      final saved = await widget.api.sitePostPut(widget.siteIid, post);
      _byId['${saved.postId}'] = saved;
      _searchCtrl.clear();
      setState(() => _search = '');
      _select('${saved.postId}');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onStorefrontChanged(String id, bool onStorefront) {
    final post = _byId[id];
    if (post == null) return;
    final next = post.clone()..onStorefront = onStorefront;
    _byId[id] = next;
    setState(() {});
    unawaited(_put(next));
  }

  Widget _listPane({required String? selectedId}) => UiSitePostsSection(
        searchController: _searchCtrl,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
        posts: _ordered,
        selectedId: selectedId,
        onSelect: _select,
        onAdd: () => unawaited(_add()),
        addBusy: _busy,
        onStorefrontChanged: _onStorefrontChanged,
      );

  Widget _detailPane(String id) {
    final post = _byId[id];
    if (post == null) {
      return const Center(child: Text('Post not found', style: TextStyle(color: _muted)));
    }
    return UiSitePostDetail(
      api: widget.api,
      siteIid: widget.siteIid,
      post: post,
      busy: _busy,
      onBusy: (v) => setState(() => _busy = v),
      onPostUpdated: (p) => setState(() => _byId['${p.postId}'] = p),
      onDeleted: () {
        _byId.remove(id);
        _pickDefault();
        if (widget.masterDetail) {
          setState(() {});
        } else {
          widget.onDetailIdChanged?.call(null);
        }
      },
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
