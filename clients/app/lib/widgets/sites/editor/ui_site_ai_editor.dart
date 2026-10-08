import 'dart:async';

import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiSiteAiEditor extends StatefulWidget {
  const UiSiteAiEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    this.detailId,
    this.onDetailIdChanged,
    this.onDraftSaved,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;
  final VoidCallback? onDraftSaved;

  @override
  State<UiSiteAiEditor> createState() => _UiSiteAiEditorState();
}

class _UiSiteAiEditorState extends State<UiSiteAiEditor> {
  late final _searchCtrl = TextEditingController();
  late final _titleCtrl = TextEditingController();
  late final _contentCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  String? _error;
  String? _selectedId;
  String? _editingId;
  var _suppress = false;
  Timer? _saveTimer;
  final _items = <SiteKnowledgeDraft>[];

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onField);
    _contentCtrl.addListener(_onField);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteAiEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (oldWidget.detailId != widget.detailId) _bindActive();
  }

  List<SiteKnowledgeDraft> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return List<SiteKnowledgeDraft>.from(_items);
    return _items.where((k) => k.title.toLowerCase().contains(q) || k.content.toLowerCase().contains(q)).toList(growable: false);
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      _items
        ..clear()
        ..addAll(siteDraftExtrasParse(draft.doc.metaJson).knowledge);
      _pickDefault();
      _bindActive();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickDefault() {
    if (_items.isEmpty) {
      _selectedId = null;
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || !_items.any((k) => k.id == _selectedId)) _selectedId = _items.first.id;
      return;
    }
    if (widget.detailId != null && !_items.any((k) => k.id == widget.detailId)) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
      _bindActive();
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  void _bindActive() {
    final id = _activeId;
    SiteKnowledgeDraft? item;
    for (final k in _items) {
      if (k.id == id) item = k;
    }
    _suppress = true;
    _editingId = item?.id;
    _titleCtrl.text = item?.title ?? '';
    _contentCtrl.text = item?.content ?? '';
    _suppress = false;
  }

  void _onField() {
    if (_loading || _suppress) return;
    final id = _editingId;
    if (id == null) return;
    final i = _items.indexWhere((k) => k.id == id);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(title: _titleCtrl.text, content: _contentCtrl.text);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_save()));
  }

  Future<void> _save() async {
    await SiteEditorSaveScope.run(context, () async {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      final doc = next.doc.clone();
      doc.metaJson = siteDraftExtrasMerge(doc.metaJson, knowledge: List<SiteKnowledgeDraft>.from(_items));
      next.doc = doc;
      await widget.api.draftPut(next);
      widget.onDraftSaved?.call();
    });
  }

  void _add() {
    final item = SiteKnowledgeDraft(id: siteDraftNewId('k'), title: 'New facts');
    _items.add(item);
    _searchCtrl.clear();
    setState(() => _search = '');
    _select(item.id);
    _scheduleSave();
  }

  Future<void> _delete(String id) async {
    _items.removeWhere((k) => k.id == id);
    _editingId = null;
    if (widget.masterDetail) {
      _pickDefault();
      _bindActive();
    } else {
      widget.onDetailIdChanged?.call(null);
    }
    setState(() {});
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)));
    }
    final detailId = _activeId;
    if (widget.masterDetail) {
      if (_items.isEmpty) return _listPane(selectedId: null);
      final selected = detailId ?? _items.first.id;
      if (_editingId != selected) _bindActive();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detail(selected)),
        ],
      );
    }
    if (detailId != null && _items.any((k) => k.id == detailId)) {
      if (_editingId != detailId) _bindActive();
      return _detail(detailId);
    }
    return _listPane(selectedId: null);
  }

  Widget _listPane({required String? selectedId}) {
    final items = _filtered;
    final searching = _search.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: _searchCtrl,
          hintText: 'Search knowledge',
          onSearchChanged: (v) => setState(() => _search = v),
          onAdd: _add,
          addTooltip: 'Add knowledge',
        ),
        Expanded(
          child: items.isEmpty
              ? UiEmptyState(
                  icon: Icons.lightbulb_outline,
                  title: searching ? 'No matching facts' : 'No knowledge yet',
                  subtitle: searching ? 'Try a different search.' : 'Add facts the site can keep on the draft.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final k = items[i];
                    final selected = k.id == selectedId;
                    final title = k.title.trim().isEmpty ? 'Untitled' : k.title.trim();
                    return Material(
                      color: selected ? const Color(0xFF34D399).withValues(alpha: 0.12) : const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: selected ? const Color(0xFF34D399).withValues(alpha: 0.35) : const Color(0xFF27272A)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _select(k.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
                              if (k.content.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    k.content.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: _muted, fontSize: 12),
                                  ),
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

  Widget _detail(String id) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          title: 'Knowledge',
          icon: Icons.lightbulb_outline,
          onDelete: () => _delete(id),
          deleteLabel: 'Delete',
          deleteConfirmTitle: 'Delete this fact?',
        ),
        const SizedBox(height: 16),
        UiSiteEditorLabeledField(
          label: 'Title',
          child: TextField(controller: _titleCtrl, style: const TextStyle(color: _text, fontSize: 14), decoration: siteEditorInputDecoration(hintText: 'Title')),
        ),
        UiSiteEditorLabeledField(
          label: 'Content',
          child: TextField(
            controller: _contentCtrl,
            minLines: 6,
            maxLines: 14,
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: siteEditorInputDecoration(hintText: 'Facts, hours, policies'),
          ),
        ),
      ],
    );
  }
}
