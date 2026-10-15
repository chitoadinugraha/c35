import 'dart:async';

import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/design/ui_site_design_section.dart';
import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/c/site/site_editor_draft_flush.dart';
import 'package:alienai_c35/c/site/site_editor_preview_patch.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// CSA site designer: appearance (theme, cards, background, backdrop) and block styles.
class UiSiteDesignEditor extends StatefulWidget {
  const UiSiteDesignEditor({
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
  State<UiSiteDesignEditor> createState() => _UiSiteDesignEditorState();
}

class _UiSiteDesignEditorState extends State<UiSiteDesignEditor> {
  SiteDesignStore? _ownedStore;
  SiteDesignStore? _boundStore;
  var _sharedDesign = false;
  var _loading = true;
  var _ready = false;
  var _loadScheduled = false;

  SiteDesignStore get _store =>
      SiteEditorSaveScope.draftAdapter(context)?.design ?? _ownedStore!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadScheduled) return;
    _loadScheduled = true;
    unawaited(_load());
  }

  @override
  void dispose() {
    _boundStore?.removeListener(_scheduleSave);
    if (!_sharedDesign) {
      _ownedStore?.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final adapter = SiteEditorSaveScope.maybeOf(context)?.draft;
      if (adapter != null) {
        _sharedDesign = true;
      } else {
        _ownedStore = SiteDesignStore();
        final draft = await widget.api.draftGet(widget.siteIid);
        final meta = siteDraftMetaParse(draft.doc.metaJson);
        _ownedStore!.loadTheme(draft.doc.themeJson, productFallback: meta.productDesign);
      }
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
        final store = SiteEditorSaveScope.draftAdapter(context)?.design ?? _ownedStore!;
        _boundStore = store;
        store.addListener(_scheduleSave);
      }
    }
  }

  void _scheduleSave() {
    if (!_ready) return;
    siteEditorPreviewPatch(context, (boot) => siteEditorPreviewPatchDesignStore(boot, _store));
    siteEditorScheduleSave(
      context,
      key: 'design',
      save: _save,
    );
  }

  Future<void> _save() async {
    if (!mounted) return;
    try {
      if (SiteEditorSaveScope.draftAdapter(context) != null) {
        await siteEditorFlushDraft(context);
      } else {
        await SiteEditorSaveScope.run(context, () async {
          final draft = await widget.api.draftGet(widget.siteIid);
          final next = draft.clone();
          next.doc = siteDocWithThemeJson(next.doc, _store.toThemeJson());
          next.doc = siteDocWithMetaJson(
            next.doc,
            siteDraftMetaMerge(next.doc.metaJson, productDesign: _store.productDesign),
          );
          await widget.api.draftPut(next);
        });
      }
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
    return UiSiteDesignSection(
      draft: _store,
      masterDetail: widget.masterDetail,
      detailId: widget.detailId,
      onDetailIdChanged: widget.onDetailIdChanged,
    );
  }
}
