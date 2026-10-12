import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/site/site_ai_assistant.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ai/alien_icon_svg.dart';
import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/c/site/site_editor_preview_patch.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_ai_channels.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

enum SiteAiPane { list, chat, call }

String siteAiPaneLabel(SiteAiPane pane) => switch (pane) {
      SiteAiPane.list => 'AI',
      SiteAiPane.chat => 'AI Chat',
      SiteAiPane.call => 'AI Call',
    };

class UiSiteAiEditor extends StatefulWidget {
  const UiSiteAiEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.siteName,
    required this.masterDetail,
    this.pane = SiteAiPane.list,
    this.onPaneChanged,
    this.detailId,
    this.onDetailIdChanged,
    this.onDraftSaved,
  });

  final SiteApi api;
  final int siteIid;
  final String siteName;
  final bool masterDetail;
  final SiteAiPane pane;
  final ValueChanged<SiteAiPane>? onPaneChanged;
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
  late final _chatIntroCtrl = TextEditingController();
  late final _chatPlaceholderCtrl = TextEditingController();
  late final _callIntroCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  String? _error;
  String? _selectedId;
  String? _editingId;
  var _suppress = false;
  var _suppressAi = false;
  final _items = <SiteKnowledgeDraft>[];
  var _aiAssistant = SiteAiAssistantDraft.legacyDefaults;
  var _connectChannelNonce = 0;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onField);
    _contentCtrl.addListener(_onField);
    _chatIntroCtrl.addListener(_onAiField);
    _chatPlaceholderCtrl.addListener(_onAiField);
    _callIntroCtrl.addListener(_onAiField);
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _chatIntroCtrl.dispose();
    _chatPlaceholderCtrl.dispose();
    _callIntroCtrl.dispose();
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
      final extras = siteDraftExtrasParse(draft.doc.metaJson);
      _items
        ..clear()
        ..addAll(extras.knowledge);
      _aiAssistant = extras.aiAssistant;
      _bindAiFields();
      _pickDefault();
      _bindActive();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bindAiFields() {
    _suppressAi = true;
    _chatIntroCtrl.text = _aiAssistant.chatIntro;
    _chatPlaceholderCtrl.text = _aiAssistant.chatPlaceholder;
    _callIntroCtrl.text = _aiAssistant.callIntro;
    _suppressAi = false;
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

  void _onAiField() {
    if (_loading || _suppressAi) return;
    _aiAssistant = _aiAssistant.copyWith(
      configured: true,
      chatIntro: _chatIntroCtrl.text,
      chatPlaceholder: _chatPlaceholderCtrl.text.trim().isEmpty ? 'Ask Alien AI...' : _chatPlaceholderCtrl.text,
      callIntro: _callIntroCtrl.text,
    );
    _scheduleSave();
  }

  void _setPane(SiteAiPane pane) => widget.onPaneChanged?.call(pane);

  void _patchAi(SiteAiAssistantDraft next) {
    setState(() => _aiAssistant = next.copyWith(configured: true));
    _scheduleSave();
  }

  void _previewDraftMeta() {
    siteEditorPreviewPatch(context, (boot) {
      final base = boot['meta'] is Map
          ? Map<String, dynamic>.from(boot['meta'] as Map)
          : <String, dynamic>{};
      final merged = siteDraftExtrasMerge(
        base.isEmpty ? '{}' : jsonEncode(base),
        knowledge: List<SiteKnowledgeDraft>.from(_items),
        aiAssistant: _aiAssistant,
      );
      siteEditorPreviewMergeMetaJson(boot, merged);
    });
  }

  void _scheduleSave() {
    _previewDraftMeta();
    siteEditorScheduleSave(context, key: 'ai', save: _save);
  }

  Future<void> _save() async {
    await SiteEditorSaveScope.run(context, () async {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      final doc = next.doc.clone();
      doc.metaJson = siteDraftExtrasMerge(
        doc.metaJson,
        knowledge: List<SiteKnowledgeDraft>.from(_items),
        aiAssistant: _aiAssistant,
      );
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

  Widget _aiFeatureFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        children: [
          _AiFeatureRow(
            icon: Icons.chat_bubble_outline,
            alienIcon: true,
            title: 'AI Chat',
            subtitle: _aiAssistant.featureChatEnabled ? 'On for guests' : 'Off',
            enabled: _aiAssistant.featureChatEnabled,
            onEnabledChanged: (v) => _patchAi(_aiAssistant.copyWith(chatEnabled: v)),
            onOpenSettings: () => _setPane(SiteAiPane.chat),
          ),
          const SizedBox(height: 8),
          _AiFeatureRow(
            icon: Icons.phone_in_talk_outlined,
            title: 'AI Call',
            subtitle: _aiAssistant.featureCallEnabled ? 'On for guests' : 'Off',
            enabled: _aiAssistant.featureCallEnabled,
            onEnabledChanged: (v) => _patchAi(_aiAssistant.copyWith(callEnabled: v)),
            onOpenSettings: () => _setPane(SiteAiPane.call),
          ),
        ],
      ),
    );
  }

  Widget _listSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: Text(title, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      );

  void _requestConnectChannel() => setState(() => _connectChannelNonce++);

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
          extraActions: [
            PopupMenuButton<String>(
              tooltip: 'Add',
              icon: const Icon(Icons.add, size: 20, color: _muted),
              onSelected: (v) {
                if (v == 'knowledge') _add();
                if (v == 'channel') _requestConnectChannel();
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'knowledge', child: Text('Add knowledge')),
                PopupMenuItem(value: 'channel', child: Text('Connect channel')),
              ],
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _listSectionHeader('Knowledge'),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: UiEmptyState(
                    icon: Icons.lightbulb_outline,
                    title: searching ? 'No matching facts' : 'No knowledge yet',
                    subtitle: searching ? 'Try a different search.' : 'Add facts the site can keep on the draft.',
                  ),
                )
              else
                ...[
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _knowledgeRow(items[i], selectedId),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              _listSectionHeader('Channels'),
              UiSiteAiChannelsSection(
                api: widget.api,
                siteIid: widget.siteIid,
                siteName: widget.siteName,
                connectRequestNonce: _connectChannelNonce,
              ),
            ],
          ),
        ),
        _aiFeatureFooter(),
      ],
    );
  }

  Widget _knowledgeRow(SiteKnowledgeDraft k, String? selectedId) {
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
  }

  Widget _chatSettingsPane() => UiSiteEditorFormScroll(
        children: [
          const UiSiteEditorPaneHeader(
            title: 'AI Chat',
            subtitle: 'Floating chat on the published guest site. Knowledge facts are included in replies.',
          ),
          UiSiteEditorSwitchRow(
            label: 'Show chat bubble on guest site',
            value: _aiAssistant.featureChatEnabled,
            onChanged: (v) => _patchAi(_aiAssistant.copyWith(chatEnabled: v)),
          ),
          const SizedBox(height: 8),
          UiSiteEditorLabeledField(
            label: 'Welcome message',
            child: TextField(
              controller: _chatIntroCtrl,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: siteEditorInputDecoration(hintText: 'Ask anything about this business.'),
            ),
          ),
          UiSiteEditorLabeledField(
            label: 'Input placeholder',
            child: TextField(
              controller: _chatPlaceholderCtrl,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: siteEditorInputDecoration(hintText: 'Ask Alien AI...'),
            ),
          ),
        ],
      );

  Widget _callSettingsPane() => UiSiteEditorFormScroll(
        children: [
          const UiSiteEditorPaneHeader(
            title: 'AI Call',
            subtitle: 'Voice call entry on the guest site. Uses the same knowledge as chat.',
          ),
          UiSiteEditorSwitchRow(
            label: 'Show call button on guest site',
            value: _aiAssistant.featureCallEnabled,
            onChanged: (v) => _patchAi(_aiAssistant.copyWith(callEnabled: v)),
          ),
          const SizedBox(height: 8),
          UiSiteEditorLabeledField(
            label: 'Welcome message',
            child: TextField(
              controller: _callIntroCtrl,
              minLines: 2,
              maxLines: 5,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: siteEditorInputDecoration(hintText: 'Tap to talk with Alien AI about this site.'),
            ),
          ),
        ],
      );

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

  Widget _paneBody({String? selectedId}) {
    return switch (widget.pane) {
      SiteAiPane.chat => _chatSettingsPane(),
      SiteAiPane.call => _callSettingsPane(),
      SiteAiPane.list => widget.masterDetail
          ? _listPane(selectedId: selectedId)
          : (selectedId != null ? _detail(selectedId) : _listPane(selectedId: null)),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_error != null && _items.isEmpty && widget.pane == SiteAiPane.list) {
      return Center(child: Text(_error!, style: const TextStyle(color: _muted, fontSize: 13)));
    }
    final detailId = _activeId;
    if (widget.masterDetail && widget.pane == SiteAiPane.list) {
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
    if (!widget.masterDetail && widget.pane == SiteAiPane.list && detailId != null && _items.any((k) => k.id == detailId)) {
      if (_editingId != detailId) _bindActive();
      return _detail(detailId);
    }
    return _paneBody(selectedId: detailId);
  }
}

class _AiFeatureRow extends StatelessWidget {
  const _AiFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabledChanged,
    required this.onOpenSettings,
    this.alienIcon = false,
  });

  final IconData icon;
  final bool alienIcon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: siteEditorCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: siteEditorFieldBorder.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpenSettings,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: alienIcon ? Colors.black : siteEditorFieldFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: siteEditorFieldBorder),
                        ),
                        child: alienIcon
                            ? Padding(
                                padding: const EdgeInsets.all(5),
                                child: SvgPicture.string(alienIconSvg, fit: BoxFit.contain),
                              )
                            : Icon(icon, size: 16, color: _accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
            UiSiteCatalogActiveSwitch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
      ),
    );
  }
}
