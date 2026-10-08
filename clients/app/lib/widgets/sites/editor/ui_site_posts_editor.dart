import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _postTitleMax = 200;

class UiSitePostsEditor extends StatefulWidget {
  const UiSitePostsEditor({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSitePostsEditor> createState() => _UiSitePostsEditorState();
}

class _UiSitePostsEditorState extends State<UiSitePostsEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  var _busy = false;
  String? _error;
  final _posts = <SitePost>[];
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
  void didUpdateWidget(covariant UiSitePostsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
  }

  List<SitePost> get _ordered {
    final items = [..._posts];
    items.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.postId.compareTo(b.postId);
    });
    return items;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _posts
        ..clear()
        ..addAll(await widget.api.sitePostList(widget.siteIid));
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
      final post = SitePost(siteIid: Int64(widget.siteIid), title: 'New post', sortOrder: sort);
      final saved = await widget.api.sitePostPut(widget.siteIid, post);
      _posts.add(saved);
      _searchCtrl.clear();
      setState(() => _search = '');
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _debouncedPut(String id, SitePost draft) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(const Duration(milliseconds: 450), () => unawaited(_put(id, draft)));
  }

  Future<void> _put(String id, SitePost draft) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.sitePostPut(widget.siteIid, draft);
      if (!mounted) return;
      final idx = _posts.indexWhere((p) => '${p.postId}' == id);
      if (idx >= 0) _posts[idx] = saved;
      setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _patch(String id, void Function(SitePost p) fn) {
    final idx = _posts.indexWhere((p) => '${p.postId}' == id);
    if (idx < 0) return;
    final next = _posts[idx].clone();
    fn(next);
    if (next.title.length > _postTitleMax) {
      next.title = next.title.substring(0, _postTitleMax);
    }
    setState(() => _posts[idx] = next);
    _debouncedPut(id, next);
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final postId = int.tryParse(id);
    if (postId == null || postId <= 0) return;
    setState(() => _busy = true);
    try {
      await widget.api.sitePostDelete(widget.siteIid, postId);
      _posts.removeWhere((p) => '${p.postId}' == id);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<SitePost> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _ordered;
    return _ordered
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.caption.toLowerCase().contains(q) ||
            p.body.toLowerCase().contains(q))
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
          hintText: 'Search news',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _add,
          addBusy: _busy,
        ),
        Expanded(
          child: filtered.isEmpty
              ? const UiEmptyState(icon: Icons.newspaper_outlined, title: 'No news', subtitle: 'Add a post to show on the home')
              : UiSiteEditorFormScroll(
                  children: [
                    for (final post in filtered)
                      _UiSitePostCard(
                        key: ValueKey('${post.postId}'),
                        post: post,
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

class _UiSitePostCard extends StatefulWidget {
  const _UiSitePostCard({super.key, required this.post, required this.busy, required this.onPatch, required this.onDelete});

  final SitePost post;
  final bool busy;
  final void Function(String id, void Function(SitePost p) fn) onPatch;
  final Future<void> Function(String id) onDelete;

  @override
  State<_UiSitePostCard> createState() => _UiSitePostCardState();
}

class _UiSitePostCardState extends State<_UiSitePostCard> {
  late final _titleCtrl = TextEditingController();
  late final _captionCtrl = TextEditingController();
  late final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    _titleCtrl.text = widget.post.title;
    _captionCtrl.text = widget.post.caption;
    _bodyCtrl.text = widget.post.body;
  }

  @override
  void didUpdateWidget(covariant _UiSitePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.post.postId}' != '${widget.post.postId}') _sync();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = '${widget.post.postId}';
    final post = widget.post;
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
              Expanded(
                child: Text(
                  post.title.isEmpty ? 'News' : post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.busy ? null : () => unawaited(widget.onDelete(id)),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
              ),
            ],
          ),
          UiSiteEditorLabeledField(
            label: 'Title',
            child: TextField(
              controller: _titleCtrl,
              maxLength: _postTitleMax,
              onChanged: widget.busy ? null : (v) => widget.onPatch(id, (p) => p.title = v),
              style: const TextStyle(fontSize: 13, color: siteEditorFormText),
              decoration: siteEditorInputDecoration(hintText: 'Headline'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('200 characters max', style: TextStyle(color: _muted, fontSize: 11)),
          ),
          UiSiteEditorLabeledField(
            label: 'Caption',
            child: TextField(
              controller: _captionCtrl,
              maxLines: 2,
              onChanged: widget.busy ? null : (v) => widget.onPatch(id, (p) => p.caption = v),
              style: const TextStyle(fontSize: 13, color: siteEditorFormText),
              decoration: siteEditorInputDecoration(hintText: 'Short summary'),
            ),
          ),
          UiSiteEditorLabeledField(
            label: 'Body',
            child: TextField(
              controller: _bodyCtrl,
              maxLines: 6,
              onChanged: widget.busy ? null : (v) => widget.onPatch(id, (p) => p.body = v),
              style: const TextStyle(fontSize: 13, color: siteEditorFormText),
              decoration: siteEditorInputDecoration(hintText: 'Full story'),
            ),
          ),
          UiSiteEditorSwitchRow(
            label: 'Show on home',
            value: post.onStorefront,
            onChanged: widget.busy ? null : (v) => widget.onPatch(id, (p) => p.onStorefront = v),
          ),
        ],
      ),
    );
  }
}
