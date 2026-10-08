import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_save_bus.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_chrome.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:alienai_c35/widgets/sites/editor/design/ui_site_design_section.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_design_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_effects_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_info_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_accounts_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_ai_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_attendance_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_contacts_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_notifications_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_plan_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_links_editor.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_posts_editor.dart';
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
import 'package:flutter/scheduler.dart';

const _muted = Color(0xFF71717A);
const _savingGreen = Color(0xFF22C55E);

/// CSA-style site editor: nav rail | section | live preview (right on wide).
class UiSiteEditorShell extends StatefulWidget {
  const UiSiteEditorShell({
    super.key,
    required this.row,
    required this.api,
    this.initialSection = siteEditorMenuDefaultId,
    this.onCapabilitiesSaved,
    this.onBack,
    this.title,
  });

  final SiteRow row;
  final SiteApi api;
  final String initialSection;
  final Future<void> Function()? onCapabilitiesSaved;
  final VoidCallback? onBack;
  final String? title;

  @override
  State<UiSiteEditorShell> createState() => _UiSiteEditorShellState();
}

class _UiSiteEditorShellState extends State<UiSiteEditorShell> {
  late String? _section = widget.initialSection;
  late SiteRow _row = widget.row.clone();
  final _saveBus = SiteEditorSaveBus();
  String? _catalogDetailId;
  SiteProductsPane _productsPane = SiteProductsPane.list;
  var _caps = const SiteEditorCaps();
  var _previewMode = SitePreviewMode.draft;
  var _previewReloadNonce = 0;
  var _publishing = false;
  var _mobilePreviewOpen = false;

  int get _siteIid => _row.siteIid.toInt();

  bool get _platformSite => isPlatformSiteAlienId(_row.alienId);

  String _coerceSection(String section) {
    if (_platformSite && (section == 'design' || section == 'effects')) return 'info';
    return section;
  }

  void _coerceStoredSection() {
    final current = _section;
    if (current == null || current.isEmpty) return;
    final next = _coerceSection(current);
    if (next != current) _section = next;
  }

  @override
  void initState() {
    super.initState();
    final next = _coerceSection(widget.initialSection);
    if (next != widget.initialSection) _section = next;
    unawaited(_loadCaps());
  }

  @override
  void didUpdateWidget(covariant UiSiteEditorShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.siteIid != widget.row.siteIid) _row = widget.row.clone();
  }

  @override
  void dispose() {
    _saveBus.dispose();
    super.dispose();
  }

  void _onRowChanged(SiteRow row) => setState(() => _row = row.clone());

  void _onDraftSaved() => setState(() => _previewReloadNonce++);

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

  String get _handle => _row.alienId.isNotEmpty ? '@${_row.alienId}' : '';

  String get _siteTitle {
    if (widget.title != null && widget.title!.trim().isNotEmpty) return widget.title!.trim();
    if (_row.name.isNotEmpty) return _row.name;
    return 'Site';
  }

  String _chromeSubtitle(String section) {
    final parts = <String>[];
    if (section == 'products' && _productsPane != SiteProductsPane.list) {
      parts.add(_productsSubtitle());
    } else if (section == 'design' && _catalogDetailId != null) {
      parts.add(siteDesignNavLabelTr(_catalogDetailId!));
    } else {
      parts.add(siteEditorMenuLabel(section, caps: _caps) ?? section);
    }
    if (_handle.isNotEmpty) parts.add(_handle);
    return parts.join(' · ');
  }

  ({String? subtitle, Color? subtitleColor}) _chromeSubtitleState(String section) {
    if (_saveBus.error.isNotEmpty) return (subtitle: 'Save failed', subtitleColor: Theme.of(context).colorScheme.error);
    if (_saveBus.saving) return (subtitle: 'Saving…', subtitleColor: _savingGreen);
    final sub = _chromeSubtitle(section);
    return (subtitle: sub.isEmpty ? null : sub, subtitleColor: null);
  }

  Widget _saveErrorStrip() {
    if (_saveBus.error.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(_saveBus.error, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12)),
      ),
    );
  }

  double _previewPaneW(double width) => siteEditorShowPreviewPane(width) ? siteEditorPreviewPaneW : 0;

  bool _catalogMasterDetail(BuildContext context, bool wide, String section) {
    if (!wide) return false;
    if (section == 'products' && _productsPane != SiteProductsPane.list) return false;
    if (section != 'products' &&
        section != 'contacts' &&
        section != 'objects' &&
        section != 'team' &&
        section != 'design' &&
        section != 'effects' &&
        section != 'ai' &&
        section != 'accounts') {
      return false;
    }
    final w = MediaQuery.sizeOf(context).width;
    return w - siteEditorMenuRailW - _previewPaneW(w) >= siteEditorMasterDetailBreakpoint;
  }

  void _openSection(String id) => setState(() {
        _section = _coerceSection(id);
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

  void _applyCatalogDetailId(String? id) {
    if (!mounted || _catalogDetailId == id) return;
    setState(() => _catalogDetailId = id);
  }

  /// User taps apply immediately; [didUpdateWidget] may call during build — defer then.
  void _scheduleCatalogDetailId(String? id) {
    if (_catalogDetailId == id) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks) {
      _applyCatalogDetailId(id);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyCatalogDetailId(id));
  }

  void _applyProductsPane(SiteProductsPane pane) {
    if (!mounted || _productsPane == pane) return;
    setState(() => _productsPane = pane);
  }

  void _scheduleProductsPane(SiteProductsPane pane) {
    if (_productsPane == pane) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks) {
      _applyProductsPane(pane);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyProductsPane(pane));
  }

  void _narrowSectionBack(String section) {
    if (_narrowCatalogDrill(section)) {
      _catalogDetailBack();
      return;
    }
    setState(() => _section = null);
  }

  String _productsSubtitle() => siteProductsPaneLabel(_productsPane);

  List<Widget> _chromeActions({required bool showPreviewToggle}) => [
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
        row: _row,
        api: widget.api,
        mode: _previewMode,
        reloadNonce: _previewReloadNonce,
        onModeChanged: (m) => setState(() => _previewMode = m),
      );

  Widget _sectionBody(BuildContext context, String section, {required bool wide}) {
    final shown = _coerceSection(section);
    final masterDetail = _catalogMasterDetail(context, wide, shown);
    return switch (shown) {
      'info' => UiSiteInfoEditor(row: _row, api: widget.api, siteIid: _siteIid, onRowChanged: _onRowChanged, onDraftSaved: _onDraftSaved),
      'links' => UiSiteLinksEditor(api: widget.api, siteIid: _siteIid),
      'posts' => UiSitePostsEditor(api: widget.api, siteIid: _siteIid),
      'ai' => UiSiteAiEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
          onDraftSaved: _onDraftSaved,
        ),
      'design' => UiSiteDesignEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
          onDraftSaved: _onDraftSaved,
        ),
      'effects' => UiSiteEffectsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
          onDraftSaved: _onDraftSaved,
        ),
      'team' => UiSiteTeamEditor(
          row: _row,
          api: widget.api,
          siteIid: _siteIid,
          caps: _caps,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
          onCapabilitiesSaved: _onCapabilitiesSaved,
        ),
      'capabilities' => UiSiteSettingsEditor(
          row: _row,
          api: widget.api,
          siteIid: _siteIid,
          onCapabilitiesSaved: _onCapabilitiesSaved,
        ),
      'publish' => UiSitePublishEditor(row: _row, onPublish: _publish, publishing: _publishing),
      'products' => UiSiteProductsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          booking: _caps.booking,
          pane: _productsPane,
          onPaneChanged: _scheduleProductsPane,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
        ),
      'contacts' => UiSiteContactsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
        ),
      'objects' => UiSiteObjectsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
        ),
      'queue' => UiSiteQueueEditor(api: widget.api, siteIid: _siteIid),
      'attendance' => UiSiteAttendanceEditor(api: widget.api, siteIid: _siteIid),
      'accounts' => UiSiteAccountsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _catalogDetailId,
          onDetailIdChanged: _scheduleCatalogDetailId,
          onDraftSaved: _onDraftSaved,
        ),
      'notifications' => UiSiteNotificationsEditor(api: widget.api, siteIid: _siteIid, onDraftSaved: _onDraftSaved),
      'plan' => const UiSitePlanEditor(),
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
          child: UiSiteEditorMenu(
            caps: _caps,
            platformSite: _platformSite,
            variant: SiteEditorMenuVariant.rail,
            selectedId: active,
            onSelect: _openSection,
          ),
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
    if (section == null) {
      return UiSiteEditorMenu(caps: _caps, platformSite: _platformSite, onSelect: _openSection);
    }
    return _sectionBody(context, section, wide: false);
  }

  bool _narrowCatalogDrill(String section) =>
      (section == 'products' && (_productsPane != SiteProductsPane.list || _catalogDetailId != null)) ||
      ((section == 'contacts' || section == 'objects' || section == 'team' || section == 'design' || section == 'effects' || section == 'ai' || section == 'accounts') &&
          _catalogDetailId != null);

  Widget _chrome({required String? subtitle, Color? subtitleColor, VoidCallback? onBack, required List<Widget> actions}) =>
      ListenableBuilder(
        listenable: _saveBus,
        builder: (context, _) => UiSiteEditorChrome(
          title: _siteTitle,
          subtitle: subtitle,
          subtitleColor: subtitleColor,
          onBack: onBack,
          actions: actions,
        ),
      );

  @override
  Widget build(BuildContext context) {
    _coerceStoredSection();
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= siteEditorWideBreakpoint;
    final active = _section ?? (wide ? widget.initialSection : '');
    final onMenu = !wide && (_section == null || _section!.isEmpty);

    return SiteEditorSaveScope(
      bus: _saveBus,
      child: Builder(
        builder: (context) {
          if (!wide && _mobilePreviewOpen) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) setState(() => _mobilePreviewOpen = false);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chrome(
                    subtitle: _row.name.isNotEmpty ? _row.name : null,
                    subtitleColor: null,
                    onBack: () => setState(() => _mobilePreviewOpen = false),
                    actions: _chromeActions(showPreviewToggle: false),
                  ),
                  _saveErrorStrip(),
                  Expanded(child: _previewPane()),
                ],
              ),
            );
          }

          final chromeActions = _chromeActions(showPreviewToggle: !wide);

          if (!wide) {
            if (onMenu) {
              final sub = _chromeSubtitleState('');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chrome(
                    subtitle: sub.subtitle ?? (_handle.isEmpty ? null : _handle),
                    subtitleColor: sub.subtitleColor,
                    onBack: widget.onBack,
                    actions: chromeActions,
                  ),
                  _saveErrorStrip(),
                  Expanded(child: UiSiteEditorMenu(caps: _caps, platformSite: _platformSite, onSelect: _openSection)),
                ],
              );
            }
            final section = _section!;
            final catalogDrill = _narrowCatalogDrill(section);
            final sub = _chromeSubtitleState(section);
            final fallback = catalogDrill && section == 'products' ? _productsSubtitle() : siteEditorMenuLabel(section, caps: _caps);
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _narrowSectionBack(section);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chrome(
                    subtitle: sub.subtitle ?? fallback,
                    subtitleColor: sub.subtitleColor,
                    onBack: () => _narrowSectionBack(section),
                    actions: chromeActions,
                  ),
                  _saveErrorStrip(),
                  Expanded(child: _narrowBody(context)),
                ],
              ),
            );
          }

          final section = active.isEmpty ? widget.initialSection : active;
          final sub = _chromeSubtitleState(section);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _chrome(subtitle: sub.subtitle ?? _chromeSubtitle(section), subtitleColor: sub.subtitleColor, onBack: widget.onBack, actions: chromeActions),
              _saveErrorStrip(),
              Expanded(child: _buildWide(context, section)),
            ],
          );
        },
      ),
    );
  }
}
