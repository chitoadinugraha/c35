import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_chrome.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_design_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_effects_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_info_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_contacts_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_links_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_objects_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_preview_pane.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_products_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_queue_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_publish_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_settings_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_team_editor.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

/// CSA-style site editor: nav rail | section | live preview (right on wide).
class UiSiteEditorShell extends StatefulWidget {
  const UiSiteEditorShell({
    super.key,
    required this.row,
    required this.api,
    this.initialSection = siteEditorMenuDefaultId,
    this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final String initialSection;
  final Future<void> Function()? onCapabilitiesSaved;

  @override
  State<UiSiteEditorShell> createState() => _UiSiteEditorShellState();
}

class _UiSiteEditorShellState extends State<UiSiteEditorShell> {
  late String? _section = widget.initialSection;
  String? _catalogDetailId;
  SiteProductsPane _productsPane = SiteProductsPane.list;
  var _caps = const SiteEditorCaps();
  var _previewMode = SitePreviewMode.draft;
  var _previewReloadNonce = 0;
  var _publishing = false;
  var _mobilePreviewOpen = false;

  int get _siteIid => widget.row.siteIid.toInt();

  @override
  void initState() {
    super.initState();
    unawaited(_loadCaps());
  }

  Future<void> _loadCaps() async {
    try {
      final config = await widget.api.configGet(_siteIid);
      if (!mounted) return;
      setState(() => _caps = SiteEditorCaps.parse(config.capabilitiesJson));
    } catch (_) {
      if (mounted) setState(() => _caps = const SiteEditorCaps());
    }
  }

  Future<void> _onCapabilitiesSaved() async {
    await widget.onCapabilitiesSaved?.call();
    await _loadCaps();
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await widget.api.publish(_siteIid);
      if (mounted) {
        setState(() => _previewReloadNonce++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site published'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String get _handle => widget.row.alienId.isNotEmpty ? '@${widget.row.alienId}' : '';

  double _previewPaneW(double width) => siteEditorShowPreviewPane(width) ? siteEditorPreviewPaneW : 0;

  bool _catalogMasterDetail(BuildContext context, bool wide, String section) {
    if (!wide) return false;
    if (section == 'products' && _productsPane != SiteProductsPane.list) return false;
    if (section != 'products' && section != 'contacts' && section != 'objects') return false;
    final w = MediaQuery.sizeOf(context).width;
    return w - siteEditorMenuRailW - _previewPaneW(w) >= siteEditorMasterDetailBreakpoint;
  }

  void _openSection(String id) => setState(() {
        _section = id;
        _catalogDetailId = null;
        _productsPane = SiteProductsPane.list;
      });

  void _catalogDetailBack() => setState(() {
        if (_productsPane != SiteProductsPane.list) {
          _productsPane = SiteProductsPane.list;
          return;
        }
        _catalogDetailId = null;
      });

  String _productsSubtitle() => siteProductsPaneLabel(_productsPane);

  List<Widget> _chromeActions({required bool showPreviewToggle}) => [
        SegmentedButton<SitePreviewMode>(
          segments: const [
            ButtonSegment(value: SitePreviewMode.draft, label: Text('Draft'), icon: Icon(Icons.edit_note, size: 14)),
            ButtonSegment(value: SitePreviewMode.published, label: Text('Published'), icon: Icon(Icons.public, size: 14)),
          ],
          selected: {_previewMode},
          onSelectionChanged: (s) => setState(() => _previewMode = s.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _text : _muted),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _publishing ? null : _publish,
          icon: _publishing
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.publish_outlined, size: 16),
          label: Text(_publishing ? 'Publishing…' : 'Publish'),
          style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
        if (showPreviewToggle) ...[
          const SizedBox(width: 4),
          uiIconButton(
            tooltip: 'Preview',
            onPressed: () => setState(() => _mobilePreviewOpen = true),
            icon: const Icon(Icons.phone_iphone_outlined, size: 20),
          ),
        ],
      ];

  Widget _previewPane() => UiSitePreviewPane(
        row: widget.row,
        api: widget.api,
        mode: _previewMode,
        reloadNonce: _previewReloadNonce,
      );

  Widget _sectionBody(BuildContext context, String section, {required bool wide}) {
    final masterDetail = _catalogMasterDetail(context, wide, section);
    return switch (section) {
      'info' => UiSiteInfoEditor(row: widget.row, api: widget.api, siteIid: _siteIid),
      'links' => UiSiteLinksEditor(api: widget.api, siteIid: _siteIid),
      'design' => UiSiteDesignEditor(api: widget.api, siteIid: _siteIid),
      'effects' => const UiSiteEffectsEditor(),
      'team' => UiSiteTeamEditor(
          row: widget.row,
          api: widget.api,
          siteIid: _siteIid,
          onCapabilitiesSaved: _onCapabilitiesSaved,
        ),
      'capabilities' => UiSiteSettingsEditor(
          row: widget.row,
          api: widget.api,
          siteIid: _siteIid,
          onCapabilitiesSaved: _onCapabilitiesSaved,
        ),
      'publish' => UiSitePublishEditor(row: widget.row, onPublish: _publish, publishing: _publishing),
      'products' => UiSiteProductsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          pane: _productsPane,
          onPaneChanged: (p) => setState(() => _productsPane = p),
          detailId: _catalogDetailId,
          onDetailIdChanged: (id) => setState(() => _catalogDetailId = id),
        ),
      'contacts' => UiSiteContactsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: (id) => setState(() => _catalogDetailId = id),
        ),
      'objects' => UiSiteObjectsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: (id) => setState(() => _catalogDetailId = id),
        ),
      'queue' => UiSiteQueueEditor(api: widget.api, siteIid: _siteIid),
      _ => Center(child: Text('Coming soon', style: const TextStyle(color: _muted, fontSize: 13))),
    };
  }

  Widget _buildWide(BuildContext context, String active) {
    final width = MediaQuery.sizeOf(context).width;
    final showPreview = siteEditorShowPreviewPane(width);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: siteEditorMenuRailW,
          child: UiSiteEditorMenu(caps: _caps, variant: SiteEditorMenuVariant.rail, selectedId: active, onSelect: _openSection),
        ),
        Expanded(child: _sectionBody(context, active, wide: true)),
        if (showPreview) ...[
          siteCatalogMasterDivider(context),
          SizedBox(width: siteEditorPreviewPaneW, child: _previewPane()),
        ],
      ],
    );
  }

  Widget _narrowBody(BuildContext context) {
    final section = _section;
    if (section == null) return UiSiteEditorMenu(caps: _caps, onSelect: _openSection);
    return _sectionBody(context, section, wide: false);
  }

  bool _narrowCatalogDrill(String section) =>
      (section == 'products' && (_productsPane != SiteProductsPane.list || _catalogDetailId != null)) ||
      ((section == 'contacts' || section == 'objects') && _catalogDetailId != null);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= siteEditorWideBreakpoint;
    final active = _section ?? (wide ? widget.initialSection : '');
    final onMenu = !wide && (_section == null || _section!.isEmpty);

    if (!wide && _mobilePreviewOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSiteEditorChrome(
            title: 'Preview',
            subtitle: widget.row.name.isNotEmpty ? widget.row.name : null,
            onBack: () => setState(() => _mobilePreviewOpen = false),
            actions: _chromeActions(showPreviewToggle: false),
          ),
          Expanded(child: _previewPane()),
        ],
      );
    }

    final chromeActions = _chromeActions(showPreviewToggle: !wide);

    if (!wide) {
      if (onMenu) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSiteEditorChrome(
              title: widget.row.name.isNotEmpty ? widget.row.name : 'Site',
              subtitle: _handle.isEmpty ? null : _handle,
              actions: chromeActions,
            ),
            Expanded(child: UiSiteEditorMenu(caps: _caps, onSelect: _openSection)),
          ],
        );
      }
      final section = _section!;
      final catalogDrill = _narrowCatalogDrill(section);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSiteEditorChrome(
            title: widget.row.name.isNotEmpty ? widget.row.name : 'Site',
            subtitle: catalogDrill && section == 'products' ? _productsSubtitle() : siteEditorMenuLabel(section, caps: _caps),
            onBack: catalogDrill ? _catalogDetailBack : () => setState(() => _section = null),
            actions: chromeActions,
          ),
          Expanded(child: _narrowBody(context)),
        ],
      );
    }

    final section = active.isEmpty ? widget.initialSection : active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteEditorChrome(
          title: widget.row.name.isNotEmpty ? widget.row.name : 'Site',
          subtitle: section == 'products' && _productsPane != SiteProductsPane.list
              ? '${siteEditorMenuLabel(section, caps: _caps)} · ${_productsSubtitle()}'
              : siteEditorMenuLabel(section, caps: _caps),
          actions: chromeActions,
        ),
        Expanded(child: _buildWide(context, section)),
      ],
    );
  }
}
