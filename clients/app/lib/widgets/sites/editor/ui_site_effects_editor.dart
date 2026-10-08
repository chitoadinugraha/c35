import 'dart:async';

import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_normalize.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_preset.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/overlay_effect/ui_overlay_effect_config.dart';
import 'package:alienai_c35/widgets/overlay_effect/ui_overlay_effect_icon.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Overlay effects master/detail. Preset ids come from `assets/effects/presets.json`.
class UiSiteEffectsEditor extends StatefulWidget {
  const UiSiteEffectsEditor({
    super.key,
    required this.api,
    required this.siteIid,
    this.masterDetail = false,
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
  State<UiSiteEffectsEditor> createState() => _UiSiteEffectsEditorState();
}

class _UiSiteEffectsEditorState extends State<UiSiteEffectsEditor> {
  final _store = SiteDesignStore();
  var _loading = true;
  var _ready = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _store.removeListener(_scheduleSave);
    _store.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      _store.loadTheme(draft.doc.themeJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _ready = true;
        });
        _store.addListener(_scheduleSave);
      }
    }
  }

  void _scheduleSave() {
    if (!_ready) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => unawaited(_save()));
  }

  Future<void> _save() async {
    if (!mounted) return;
    try {
      await SiteEditorSaveScope.run(context, () async {
        final draft = await widget.api.draftGet(widget.siteIid);
        final next = draft.clone();
        next.doc = siteDocWithThemeJson(next.doc, _store.toThemeJson());
        await widget.api.draftPut(next);
      });
      widget.onDraftSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    return _UiSiteEffectsSection(
      draft: _store,
      masterDetail: widget.masterDetail,
      detailId: widget.detailId,
      onDetailIdChanged: widget.onDetailIdChanged,
    );
  }
}

class _UiSiteEffectsSection extends StatefulWidget {
  const _UiSiteEffectsSection({
    required this.draft,
    this.masterDetail = false,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteDesignStore draft;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<_UiSiteEffectsSection> createState() => _UiSiteEffectsSectionState();
}

class _UiSiteEffectsSectionState extends State<_UiSiteEffectsSection> {
  String? _selectedId;
  late final _searchCtrl = TextEditingController();
  var _search = '';
  OverlayEffectPresetCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    unawaited(_catalogLoad());
    _pickDefault();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _catalogLoad() async {
    final catalog = await OverlayEffectPresetCatalog.load();
    if (!mounted) return;
    setState(() => _catalog = catalog);
  }

  @override
  void didUpdateWidget(covariant _UiSiteEffectsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.masterDetail != oldWidget.masterDetail) _pickDefault();
    if (_selectedId != null && widget.draft.overlayEffectGet(_selectedId!) == null) _pickDefault();
  }

  void _pickDefault() {
    final effects = widget.draft.overlayEffects;
    if (effects.isEmpty) {
      if (!widget.masterDetail) widget.onDetailIdChanged?.call(null);
      _selectedId = null;
      return;
    }
    if (widget.masterDetail) {
      if (_selectedId == null || widget.draft.overlayEffectGet(_selectedId!) == null) {
        _selectedId = effects.first.id;
      }
      return;
    }
    if (widget.detailId != null && widget.draft.overlayEffectGet(widget.detailId!) == null) {
      widget.onDetailIdChanged?.call(null);
    }
  }

  String? get _activeId => widget.masterDetail ? _selectedId : widget.detailId;

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
  }

  void _afterDelete() {
    if (widget.masterDetail) {
      setState(_pickDefault);
    } else {
      widget.onDetailIdChanged?.call(null);
    }
  }

  List<SiteOverlayEffectDraft> get _filtered {
    final catalog = _catalog;
    final q = _search.trim().toLowerCase();
    final effects = widget.draft.overlayEffects;
    if (q.isEmpty || catalog == null) return effects;
    return effects.where((e) {
      final preset = catalog.presetById(e.presetId) ?? catalog.presetById(overlayEffectPresetCanonical(e.presetId));
      final name = preset?.name ?? e.presetId;
      return name.toLowerCase().contains(q) || e.presetId.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _effectAdd(BuildContext context) async {
    final catalog = _catalog;
    if (catalog == null) return;
    final preset = await _presetPickerShow(context, catalog);
    if (preset == null || !mounted) return;
    final created = overlayEffectCreate(preset.id, preset);
    final id = widget.draft.overlayEffectAdd(presetId: created.presetId, params: created.params);
    _searchCtrl.clear();
    setState(() => _search = '');
    _select(id);
  }

  Widget _listPane({required String? selectedId}) => _EffectList(
        draft: widget.draft,
        catalog: _catalog,
        effects: _filtered,
        search: _search,
        searchController: _searchCtrl,
        selectedId: selectedId,
        showActive: !widget.masterDetail,
        onSearchChanged: (v) => setState(() => _search = v),
        onSelect: _select,
        onAdd: () => _effectAdd(context),
      );

  @override
  Widget build(BuildContext context) {
    if (_catalog == null) return const UILoading();
    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) {
        if (widget.masterDetail) {
          final effects = widget.draft.overlayEffects;
          if (effects.isEmpty) return _listPane(selectedId: null);
          final selected = _activeId ?? effects.first.id;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
              siteCatalogMasterDivider(context),
              Expanded(child: _EffectDetail(draft: widget.draft, catalog: _catalog!, effectId: selected, onDeleted: _afterDelete)),
            ],
          );
        }
        final detailId = _activeId;
        if (detailId != null) {
          return _EffectDetail(draft: widget.draft, catalog: _catalog!, effectId: detailId, onDeleted: _afterDelete);
        }
        return _listPane(selectedId: null);
      },
    );
  }
}

Future<OverlayEffectPreset?> _presetPickerShow(BuildContext context, OverlayEffectPresetCatalog catalog) =>
    showModalBottomSheet<OverlayEffectPreset>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final presets = catalog.filter(query).where((p) => overlayEffectPresetRunnable(p.id)).toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (_, scroll) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Search effects', isDense: true),
                      onChanged: (v) => setLocal(() => query = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: presets.length,
                      itemBuilder: (context, i) {
                        final preset = presets[i];
                        return ListTile(
                          leading: UiOverlayEffectIcon(icon: preset.icon, size: 22),
                          title: Text(preset.name),
                          subtitle: Text(preset.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.pop(ctx, preset),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

class _EffectList extends StatelessWidget {
  const _EffectList({
    required this.draft,
    required this.catalog,
    required this.effects,
    required this.search,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onAdd,
    this.selectedId,
    this.showActive = true,
  });

  final SiteDesignStore draft;
  final OverlayEffectPresetCatalog? catalog;
  final List<SiteOverlayEffectDraft> effects;
  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final String? selectedId;
  final bool showActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: searchController,
          hintText: 'Search effects',
          onSearchChanged: onSearchChanged,
          addTooltip: 'Add effect',
          onAdd: onAdd,
          menuItems: const [
            SiteCatalogMenuItem(value: 'add', label: 'Add effect', leading: Icon(Icons.add, size: 18)),
          ],
          onMenuAction: (action) {
            if (action == 'add') onAdd();
          },
        ),
        Expanded(
          child: effects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 36, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          search.trim().isEmpty ? 'No effects yet' : 'No matches',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          search.trim().isEmpty ? 'Add rain, snow, petals, and other overlays.' : 'Try another search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                        if (search.trim().isEmpty) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add effect')),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: effects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final e = effects[i];
                    final preset = catalog?.presetById(e.presetId) ?? catalog?.presetById(overlayEffectPresetCanonical(e.presetId));
                    final title = preset?.name ?? e.presetId;
                    final selected = e.id == selectedId;
                    return Material(
                      color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: selected ? cs.primary.withValues(alpha: 0.25) : cs.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(e.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Opacity(
                                  opacity: e.active ? 1 : 0.5,
                                  child: Row(
                                    children: [
                                      UiOverlayEffectIcon(icon: preset?.icon ?? '', size: 18, color: cs.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? cs.onSurface : null)),
                                            if (preset != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  preset.description,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (showActive) ...[
                                const SizedBox(width: 4),
                                UiSiteCatalogActiveSwitch(
                                  value: e.active,
                                  onChanged: (v) => draft.overlayEffectUpdate(e.id, active: v),
                                ),
                              ],
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
}

class _EffectDetail extends StatelessWidget {
  const _EffectDetail({required this.draft, required this.catalog, required this.effectId, required this.onDeleted});

  final SiteDesignStore draft;
  final OverlayEffectPresetCatalog catalog;
  final String effectId;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: draft,
        builder: (context, _) {
          final effect = draft.overlayEffectGet(effectId);
          final preset = effect == null
              ? null
              : catalog.presetById(effect.presetId) ?? catalog.presetById(overlayEffectPresetCanonical(effect.presetId));
          if (effect == null || preset == null) return const SizedBox.shrink();
          return UiOverlayEffectConfig(
            effect: effect,
            preset: preset,
            onChanged: (next) => draft.overlayEffectUpdate(
                  effectId,
                  presetId: next.presetId,
                  params: next.params,
                  active: next.active,
                ),
            onDelete: () {
              draft.overlayEffectRemove(effectId);
              onDeleted();
            },
            deleteConfirmTitle: 'Remove effect?',
            deleteConfirmBody: 'This overlay will be removed from the page.',
          );
        },
      );
}
