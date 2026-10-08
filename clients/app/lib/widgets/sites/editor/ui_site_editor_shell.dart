import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_chrome.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_design_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_effects_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_info_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_contacts_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_links_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_objects_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_products_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_queue_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_publish_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_settings_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_team_editor.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// CSA-style site editor: nav rail | section (master | detail).
class UiSiteEditorShell extends StatefulWidget {
  const UiSiteEditorShell({
    super.key,
    required this.row,
    required this.api,
    this.initialSection = siteEditorMenuDefaultId,
    this.onPublish,
    this.publishing = false,
    this.onCapabilitiesSaved,
  });

  final SiteRow row;
  final SiteApi api;
  final String initialSection;
  final VoidCallback? onPublish;
  final bool publishing;
  final Future<void> Function()? onCapabilitiesSaved;

  @override
  State<UiSiteEditorShell> createState() => _UiSiteEditorShellState();
}

class _UiSiteEditorShellState extends State<UiSiteEditorShell> {
  late String? _section = widget.initialSection;
  String? _catalogDetailId;
  SiteProductsPane _productsPane = SiteProductsPane.list;
  var _caps = const SiteEditorCaps();

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

  String get _handle => widget.row.alienId.isNotEmpty ? '@${widget.row.alienId}' : '';

  bool _catalogMasterDetail(BuildContext context, bool wide, String section) {
    if (!wide) return false;
    if (section == 'products' && _productsPane != SiteProductsPane.list) return false;
    if (section != 'products' && section != 'contacts' && section != 'objects') return false;
    return MediaQuery.sizeOf(context).width - siteEditorMenuRailW >= siteEditorMasterDetailBreakpoint;
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
      'publish' => UiSitePublishEditor(row: widget.row, onPublish: widget.onPublish, publishing: widget.publishing),
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

  Widget _buildWide(BuildContext context, String active) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: siteEditorMenuRailW,
            child: UiSiteEditorMenu(caps: _caps, variant: SiteEditorMenuVariant.rail, selectedId: active, onSelect: _openSection),
          ),
          Expanded(child: _sectionBody(context, active, wide: true)),
        ],
      );

  Widget _buildNarrow(BuildContext context) {
    final section = _section;
    if (section == null) {
      return UiSiteEditorMenu(caps: _caps, onSelect: _openSection);
    }
    final catalogDrill = (section == 'products' && (_productsPane != SiteProductsPane.list || _catalogDetailId != null)) ||
        ((section == 'contacts' || section == 'objects') && _catalogDetailId != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteEditorChrome(
          title: widget.row.name.isNotEmpty ? widget.row.name : 'Site',
          subtitle: catalogDrill && section == 'products' ? _productsSubtitle() : siteEditorMenuLabel(section, caps: _caps),
          onBack: catalogDrill ? _catalogDetailBack : () => setState(() => _section = null),
        ),
        Expanded(child: _sectionBody(context, section, wide: false)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= siteEditorWideBreakpoint;
    final active = _section ?? (wide ? widget.initialSection : '');
    final onMenu = !wide && (_section == null || _section!.isEmpty);

    if (!wide) {
      if (onMenu) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSiteEditorChrome(title: widget.row.name.isNotEmpty ? widget.row.name : 'Site', subtitle: _handle.isEmpty ? null : _handle),
            Expanded(child: UiSiteEditorMenu(caps: _caps, onSelect: _openSection)),
          ],
        );
      }
      return _buildNarrow(context);
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
        ),
        Expanded(child: _buildWide(context, section)),
      ],
    );
  }
}
