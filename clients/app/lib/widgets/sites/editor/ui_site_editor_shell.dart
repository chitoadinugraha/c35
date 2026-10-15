import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_adapter.dart';
import 'package:alienai_c35/c/site/site_editor_flush_coordinator.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_nav.dart';
import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_editor_preview_cache.dart';
import 'package:alienai_c35/c/site/site_editor_preview_patch.dart';
import 'package:alienai_c35/c/site/site_editor_save_bus.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_error_snackbar.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_loading_page.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_chrome.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
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
import 'package:alienai_c35/widgets/ui/ui_conn_wifi.dart';
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
  late SiteRow _row = widget.row.clone();
  final _saveBus = SiteEditorSaveBus();
  final _flush = SiteEditorFlushCoordinator();
  late final SiteEditorPreviewCache _previewCache = SiteEditorPreviewCache(api: widget.api, row: _row);
  late SiteEditorCatalogCache _catalogCache;
  late final SiteEditorNav _nav = SiteEditorNav();
  var _caps = const SiteEditorCaps();
  var _previewMode = SitePreviewMode.draft;
  var _publishing = false;
  var _publishPending = true;
  var _mobilePreviewOpen = false;
  var _wideDetailOpen = true;
  var _exitInFlight = false;
  SiteDraftAdapter? _draftAdapter;
  String? _draftLoadError;
  var _draftLoadAttempt = 0;

  int get _siteIid => _row.siteIid.toInt();

  bool get _platformSite => isPlatformSiteAlienId(_row.alienId);

  String _coerceSection(String section) {
    if (_platformSite && (section == 'design' || section == 'effects')) return 'info';
    return section;
  }

  void _coerceStoredSection() {
    final current = _nav.section;
    if (current == null || current.isEmpty) return;
    final next = _coerceSection(current);
    if (next != current) _nav.section = next;
  }

  String get _resolvedInitialSection => _coerceSection(widget.initialSection);

  @override
  void initState() {
    super.initState();
    _catalogCache = SiteEditorCatalogCache(api: widget.api, siteIid: _siteIid);
    final initial = _resolvedInitialSection;
    if (initial != siteEditorMenuDefaultId) _nav.section = initial;
    _catalogCache.addListener(_syncCatalogToPreview);
    _catalogCache.addListener(_onEditorGateProgress);
    _previewCache.addListener(_onEditorGateProgress);
    unawaited(_catalogCache.warm());
    unawaited(_catalogCache.prefetchProductsExtras(widget.api));
    unawaited(_loadDraftAdapter());
  }

  Future<void> _loadDraftAdapter() async {
    final attempt = ++_draftLoadAttempt;
    if (mounted) {
      setState(() {
        _draftLoadError = null;
        if (_draftAdapter != null) {
          _draftAdapter!.design.removeListener(_onAdapterDesignPreview);
          _draftAdapter!.dispose();
          _draftAdapter = null;
        }
      });
    }
    try {
      // Fast path: draft + config only; catalog warm continues in background.
      final draftConfig = await Future.wait([
        widget.api.draftGet(_siteIid),
        widget.api.configGet(_siteIid),
      ]);
      final draft = draftConfig[0] as SiteDraft;
      final config = draftConfig[1] as SiteConfig;
      final adapter = SiteDraftAdapter.fromDraft(
        api: widget.api,
        draft: draft,
        capabilitiesJson: config.capabilitiesJson,
        catalog: _catalogCache,
      );
      if (!mounted || attempt != _draftLoadAttempt) {
        adapter.dispose();
        return;
      }
      adapter.design.addListener(_onAdapterDesignPreview);
      _catalogCache.applyProductCatalogMeta(adapter.catalogMeta);
      setState(() {
        _draftAdapter = adapter;
        _draftLoadError = null;
        _caps = SiteEditorCaps.parse(siteCapabilitiesEncode(adapter.capabilities));
      });
      _onAdapterDesignPreview();
      unawaited(_previewCache.ensureLoaded());
      unawaited(_refreshPublishPending());
    } catch (e) {
      if (!mounted || attempt != _draftLoadAttempt) return;
      setState(() => _draftLoadError = uiFriendlyError(e));
    }
  }

  Widget _draftLoadingPage() {
    final handle = _row.alienId.trim().isEmpty ? null : '@${_row.alienId.trim()}';
    final pic = _row.pic.trim();
    final avatar = pic.isNotEmpty
        ? UiImg(src: pic, width: 76, height: 76, fit: BoxFit.cover, fallback: _siteAvatarFallback())
        : _siteAvatarFallback();
    return UiLoadingPage(
      onBack: widget.onBack ?? () => Navigator.maybePop(context),
      message: 'Loading site…',
      error: _draftLoadError,
      onRetry: _draftLoadError != null ? () => unawaited(_loadDraftAdapter()) : null,
      hero: UiLoadingPageSiteHero(
        name: _siteTitle,
        handle: handle,
        avatar: avatar,
        loading: true,
      ),
    );
  }

  Widget _siteAvatarFallback() {
    final letter = _siteTitle.isNotEmpty ? _siteTitle[0].toUpperCase() : 'S';
    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      color: const Color(0xFF27272A),
      child: Text(letter, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 28, fontWeight: FontWeight.w600)),
    );
  }

  void _onAdapterDesignPreview() {
    final adapter = _draftAdapter;
    if (adapter == null) return;
    _previewCache.patch((boot) => siteEditorPreviewPatchDesignStore(boot, adapter.design));
  }

  void _onEditorGateProgress() {
    if (mounted) setState(() {});
  }

  void _syncCatalogToPreview() {
    if (!_catalogCache.warmDone || _catalogCache.products.isEmpty) return;
    _previewCache.patch((boot) => siteEditorPreviewSyncCommerceCatalog(boot, _catalogCache.products));
    _previewCache.scheduleServerSync();
  }

  @override
  void didUpdateWidget(covariant UiSiteEditorShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.siteIid != widget.row.siteIid) {
      _row = widget.row.clone();
      final oldCatalog = _catalogCache;
      oldCatalog.removeListener(_syncCatalogToPreview);
      _catalogCache = SiteEditorCatalogCache(api: widget.api, siteIid: _siteIid);
      _catalogCache.addListener(_syncCatalogToPreview);
      _catalogCache.addListener(_onEditorGateProgress);
      _previewCache.addListener(_onEditorGateProgress);
      _previewCache.resetForSite(_row);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldCatalog.dispose();
      });
      unawaited(_refreshPublishPending());
      unawaited(_catalogCache.warm());
      unawaited(_catalogCache.prefetchProductsExtras(widget.api));
      unawaited(_previewCache.ensureLoaded());
      _draftAdapter?.design.removeListener(_onAdapterDesignPreview);
      unawaited(_draftAdapter?.flush());
      _draftAdapter?.dispose();
      _draftAdapter = null;
      unawaited(_loadDraftAdapter());
    } else if (oldWidget.row != widget.row) {
      _row = widget.row.clone();
      _previewCache.updateRow(_row);
    }
  }

  @override
  void dispose() {
    _catalogCache.removeListener(_syncCatalogToPreview);
    _catalogCache.removeListener(_onEditorGateProgress);
    _previewCache.removeListener(_onEditorGateProgress);
    _draftAdapter?.design.removeListener(_onAdapterDesignPreview);
    unawaited(_flush.flush());
    unawaited(_draftAdapter?.flush());
    _draftAdapter?.dispose();
    _previewCache.dispose();
    _catalogCache.dispose();
    _saveBus.dispose();
    super.dispose();
  }

  void _onRowChanged(SiteRow row) {
    final next = row.clone();
    setState(() => _row = next);
    _previewCache.updateRow(next);
  }

  void _onDraftSaved() {
    final adapter = _draftAdapter;
    if (adapter != null) {
      unawaited(widget.api.draftGet(_siteIid).then((draft) {
        if (mounted) adapter.replaceBaseline(draft);
      }));
    }
    _previewCache.scheduleServerSync();
    unawaited(_refreshPublishPending());
  }

  Future<void> _refreshPublishPending() async {
    try {
      final res = await widget.api.draftGetWithPublishStatus(_siteIid);
      if (!mounted) return;
      setState(() {
        _publishPending = res.publishPending;
        final vid = res.config.publishedVersionId;
        if (vid.isNotEmpty) {
          _row.publishedVersionId = vid;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _publishPending = true);
    }
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

  Future<void> _confirmPublish() async {
    if (_publishing || !_publishPending) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish site?'),
        content: const Text('Visitors will see your latest draft on the public URL.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      ),
    );
    if (ok == true && mounted) await _publish();
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      final res = await widget.api.publish(_siteIid);
      if (mounted) {
        if (res.hasPublish()) {
          final vid = res.publish.versionId;
          if (vid.isNotEmpty) {
            setState(() => _row.publishedVersionId = vid);
          }
        }
        setState(() => _publishPending = false);
        unawaited(_refreshPublishPending());
        unawaited(_previewCache.reloadFromServer(keepVisible: true));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site published'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        uiShowErrorSnackBar(context, e);
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

  List<SiteEditorBreadcrumbSegment> _breadcrumbSegments(bool wide) {
    final segs = _nav.pathSegments(caps: _caps, handleLabel: _handle, wide: wide);
    return segs.asMap().entries.map((e) {
      final seg = e.value;
      final isLast = e.key == segs.length - 1;
      return SiteEditorBreadcrumbSegment(
        label: seg.label,
        onTap: isLast ? null : () => unawaited(_onBreadcrumbTap(seg)),
      );
    }).toList();
  }

  Future<void> _onBreadcrumbTap(SiteEditorNavSegment seg) async {
    await _prepareNavigateBack();
    if (!mounted) return;
    setState(() {
      if (seg.kind == SiteEditorNavSegmentKind.handle) {
        _nav.openSection('info');
        return;
      }
      _nav.popToBreadcrumbDepth(seg.depth);
    });
  }

  ({String? statusLine, Color? statusColor, List<SiteEditorBreadcrumbSegment> breadcrumb}) _chromeHeaderState(bool wide) {
    if (_saveBus.error.isNotEmpty) {
      return (statusLine: 'Save failed', statusColor: Theme.of(context).colorScheme.error, breadcrumb: const []);
    }
    if (_saveBus.saving) {
      return (statusLine: 'Saving…', statusColor: _savingGreen, breadcrumb: const []);
    }
    return (statusLine: null, statusColor: null, breadcrumb: _breadcrumbSegments(wide));
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

  double _previewPaneW(bool wide) => wide && _wideDetailOpen ? siteEditorDetailPaneW : 0;

  bool _catalogMasterDetail(BuildContext context, bool wide, String section) =>
      _nav.catalogMasterDetail(context, wide: wide, section: section, previewPaneW: _previewPaneW(wide));

  void _openSection(String id) => setState(() => _nav.openSection(_coerceSection(id)));

  void _catalogDetailBack() => setState(_nav.pop);

  void _applyCatalogDetailId(String? id, {required String section}) {
    if (!mounted || _nav.catalogDetailId == id) return;
    setState(() => _nav.setDetailId(id, sectionId: section));
  }

  /// User taps apply immediately; [didUpdateWidget] may call during build — defer then.
  void _scheduleCatalogDetailId(String? id, {required String section}) {
    if (_nav.catalogDetailId == id) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks) {
      _applyCatalogDetailId(id, section: section);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyCatalogDetailId(id, section: section));
  }

  void _applyProductsPane(SiteProductsPane pane) {
    if (!mounted || _nav.productsPane == pane) return;
    setState(() => _nav.pushProductsPane(pane));
  }

  void _scheduleProductsPane(SiteProductsPane pane) {
    if (_nav.productsPane == pane) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks) {
      _applyProductsPane(pane);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyProductsPane(pane));
  }

  void _applyAiPane(SiteAiPane pane) {
    if (!mounted || _nav.aiPane == pane) return;
    setState(() => _nav.pushAiPane(pane));
  }

  void _scheduleAiPane(SiteAiPane pane) {
    if (_nav.aiPane == pane) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.transientCallbacks) {
      _applyAiPane(pane);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyAiPane(pane));
  }

  Future<void> _narrowSectionBack(String section) async {
    await _prepareNavigateBack();
    if (_nav.narrowCatalogDrill(section)) {
      _catalogDetailBack();
      return;
    }
    setState(_nav.openNarrowMenu);
  }

  bool _canPopEditorStack(String section, bool wide) => _nav.canPop(wide: wide);

  Future<void> _prepareNavigateBack() async {
    await _flush.flush();
    if (!mounted) return;
    final adapter = _draftAdapter;
    if (adapter != null && adapter.hasPendingFlush) {
      await siteEditorSaveRun(_saveBus, () => adapter.flush());
    }
    if (!mounted) return;
    await SiteEditorSaveScope.waitWhileSavingBus(_saveBus);
  }

  Future<void> _exitEditor() async {
    if (_exitInFlight) return;
    _exitInFlight = true;
    try {
      await _prepareNavigateBack();
      if (!mounted) return;
      widget.onBack?.call();
    } finally {
      _exitInFlight = false;
    }
  }

  Future<void> _handleChromeBack({required String section, required bool wide, required bool onMenu}) async {
    if (_canPopEditorStack(section, wide)) {
      await _prepareNavigateBack();
      if (!mounted) return;
      if (_nav.productsPane != SiteProductsPane.list || _nav.aiPane != SiteAiPane.list) {
        setState(_nav.pop);
        return;
      }
      if (_nav.narrowCatalogDrill(section)) {
        setState(_nav.pop);
        return;
      }
      if (!wide && !onMenu) {
        setState(_nav.openNarrowMenu);
        return;
      }
    }
    await _exitEditor();
  }

  bool get _showPublishedLabel => !_publishPending;

  List<Widget> _chromeActions({required bool showPreviewToggle}) => [
        UiConnWifi(conn: widget.api.conn),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (_publishing || !_publishPending) ? null : _confirmPublish,
          icon: _publishing
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_publishPending ? Icons.publish_outlined : Icons.check_circle_outline, size: 16),
          label: Text(_publishing ? 'Publishing…' : (_publishPending ? 'Publish' : 'Published')),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: _showPublishedLabel ? WidgetStatePropertyAll(_muted) : null,
          ),
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
        previewCache: _previewCache,
        onModeChanged: (m) {
          setState(() => _previewMode = m);
          _previewCache.setMode(m);
        },
      );

  Widget _sectionEditor(BuildContext context, String shown, {required bool masterDetail}) => switch (shown) {
      'info' => UiSiteInfoEditor(row: _row, api: widget.api, siteIid: _siteIid, onRowChanged: _onRowChanged, onDraftSaved: _onDraftSaved),
      'links' => UiSiteLinksEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onPublishStateMayHaveChanged: _refreshPublishPending,
        ),
      'posts' => UiSitePostsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'ai' => UiSiteAiEditor(
          api: widget.api,
          siteIid: _siteIid,
          siteName: _row.name,
          masterDetail: masterDetail,
          pane: _nav.aiPane,
          onPaneChanged: _scheduleAiPane,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onDraftSaved: _onDraftSaved,
        ),
      'design' => UiSiteDesignEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onDraftSaved: _onDraftSaved,
        ),
      'effects' => UiSiteEffectsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onDraftSaved: _onDraftSaved,
        ),
      'team' => UiSiteTeamEditor(
          row: _row,
          api: widget.api,
          siteIid: _siteIid,
          caps: _caps,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onCapabilitiesSaved: _onCapabilitiesSaved,
        ),
      'capabilities' => UiSiteSettingsEditor(
          row: _row,
          api: widget.api,
          siteIid: _siteIid,
          onCapabilitiesSaved: _onCapabilitiesSaved,
          onOpenPublish: () => _openSection('publish'),
        ),
      'publish' => UiSitePublishEditor(
          row: _row,
          api: widget.api,
          siteIid: _siteIid,
          onPublish: _confirmPublish,
          publishing: _publishing,
          publishPending: _publishPending,
        ),
      'products' => UiSiteProductsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          booking: _caps.booking,
          pane: _nav.productsPane,
          onPaneChanged: _scheduleProductsPane,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'contacts' => UiSiteContactsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'objects' => UiSiteObjectsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'queue' => UiSiteQueueEditor(
          api: widget.api,
          siteIid: _siteIid,
          queueEnabled: _caps.queue,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'attendance' => UiSiteAttendanceEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
        ),
      'accounts' => UiSiteAccountsEditor(
          api: widget.api,
          siteIid: _siteIid,
          masterDetail: masterDetail,
          detailId: _nav.catalogDetailId,
          onDetailIdChanged: (id) => _scheduleCatalogDetailId(id, section: shown),
          onDraftSaved: _onDraftSaved,
        ),
      'notifications' => UiSiteNotificationsEditor(api: widget.api, siteIid: _siteIid, onDraftSaved: _onDraftSaved),
      'plan' => const UiSitePlanEditor(),
      _ => Center(child: Text('Coming soon', style: const TextStyle(color: _muted, fontSize: 13))),
    };

  Widget _sectionBody(BuildContext context, String section, {required bool wide}) {
    final shown = _coerceSection(section);
    if (!wide) {
      final masterDetail = _catalogMasterDetail(context, wide, shown);
      return _sectionEditor(context, shown, masterDetail: masterDetail);
    }
    return LayoutBuilder(
      builder: (context, c) {
        final catalogMaster =
            SiteEditorNav.masterDetailSectionIds.contains(shown) && c.maxWidth >= siteEditorMasterDetailBreakpoint;
        return _sectionEditor(context, shown, masterDetail: catalogMaster);
      },
    );
  }

  Widget _buildWideMaster(BuildContext context, String active) {
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
      ],
    );
  }

  Widget _narrowBody(BuildContext context) {
    final section = _nav.section;
    if (section == null) {
      return UiSiteEditorMenu(caps: _caps, platformSite: _platformSite, onSelect: _openSection);
    }
    return _sectionBody(context, section, wide: false);
  }

  Widget _chrome({
    required String? statusLine,
    Color? statusColor,
    required List<SiteEditorBreadcrumbSegment> breadcrumb,
    VoidCallback? onBack,
    required List<Widget> actions,
    bool showDetailCollapse = false,
  }) =>
      ListenableBuilder(
        listenable: _saveBus,
        builder: (context, _) => UiSiteEditorChrome(
          title: _siteTitle,
          statusLine: statusLine,
          statusColor: statusColor,
          breadcrumb: breadcrumb,
          onBack: onBack,
          showDetailCollapse: showDetailCollapse,
          detailOpen: _wideDetailOpen,
          onDetailToggle: showDetailCollapse ? () => setState(() => _wideDetailOpen = !_wideDetailOpen) : null,
          actions: actions,
        ),
      );

  @override
  Widget build(BuildContext context) {
    _coerceStoredSection();
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= siteEditorWideBreakpoint;
    final active = _nav.section ?? (wide ? _resolvedInitialSection : '');
    final onMenu = !wide && (_nav.section == null || _nav.section!.isEmpty);

    if (_draftAdapter == null) {
      return _draftLoadingPage();
    }

    return SiteEditorSaveScope(
      bus: _saveBus,
      flush: _flush,
      preview: _previewCache,
      catalog: _catalogCache,
      draft: _draftAdapter,
      child: SiteEditorNavScope(
        nav: _nav,
        onNavChanged: () {
          if (mounted) setState(() {});
        },
        child: _siteEditorBody(context, wide: wide, active: active, onMenu: onMenu),
      ),
    );
  }

  Widget _siteEditorBody(BuildContext context, {required bool wide, required String active, required bool onMenu}) {
    return Builder(
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
                    statusLine: 'Preview',
                    statusColor: null,
                    breadcrumb: const [],
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
              final header = _chromeHeaderState(false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chrome(
                    statusLine: header.statusLine,
                    statusColor: header.statusColor,
                    breadcrumb: header.breadcrumb,
                    onBack: () => unawaited(_exitEditor()),
                    actions: chromeActions,
                  ),
                  _saveErrorStrip(),
                  Expanded(child: UiSiteEditorMenu(caps: _caps, platformSite: _platformSite, onSelect: _openSection)),
                ],
              );
            }
            final section = _nav.section!;
            final header = _chromeHeaderState(false);
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) unawaited(_narrowSectionBack(section));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _chrome(
                    statusLine: header.statusLine,
                    statusColor: header.statusColor,
                    breadcrumb: header.breadcrumb,
                    onBack: () => unawaited(_handleChromeBack(section: section, wide: false, onMenu: false)),
                    actions: chromeActions,
                  ),
                  _saveErrorStrip(),
                  Expanded(child: _narrowBody(context)),
                ],
              ),
            );
          }

          final section = active.isEmpty ? _resolvedInitialSection : active;
          final header = _chromeHeaderState(true);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _chrome(
                      statusLine: header.statusLine,
                      statusColor: header.statusColor,
                      breadcrumb: header.breadcrumb,
                      onBack: () => unawaited(_handleChromeBack(section: section, wide: true, onMenu: false)),
                      actions: chromeActions,
                      showDetailCollapse: true,
                    ),
                    _saveErrorStrip(),
                    Expanded(child: _buildWideMaster(context, section)),
                  ],
                ),
              ),
              if (_wideDetailOpen) ...[
                siteCatalogMasterDivider(context),
                SizedBox(width: siteEditorDetailPaneW, child: _previewPane()),
              ],
            ],
          );
      },
    );
  }
}
