import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_editor_preview_patch.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:flutter/foundation.dart';

/// Client-held site boot for editor preview (CSA-style instant updates).
class SiteEditorPreviewCache extends ChangeNotifier {
  SiteEditorPreviewCache({
    required this.api,
    required this.row,
    this.mode = SitePreviewMode.draft,
  });

  final SiteApi api;
  SiteRow row;
  SitePreviewMode mode;

  Map<String, dynamic>? _boot;
  var _loading = false;
  String? _error;
  Timer? _serverSyncTimer;
  Future<void>? _loadFuture;
  var _disposed = false;

  Map<String, dynamic>? get boot => _boot;
  bool get loading => _loading && _boot == null;
  String? get error => _error;

  void updateRow(SiteRow next) {
    if (_disposed) return;
    row = next.clone();
    if (_boot != null) {
      siteEditorPreviewPatchSiteRow(_boot!, row);
      notifyListeners();
    }
  }

  /// New `site_iid` — drop cached boot from the previous site.
  void resetForSite(SiteRow next) {
    if (_disposed) return;
    row = next.clone();
    _boot = null;
    _error = null;
    _loading = false;
    _serverSyncTimer?.cancel();
    notifyListeners();
    unawaited(reloadFromServer(keepVisible: false));
  }

  void patch(void Function(Map<String, dynamic> boot) fn) {
    final b = _boot;
    if (b == null) return;
    fn(b);
    notifyListeners();
  }

  void scheduleServerSync({Duration delay = const Duration(milliseconds: 1200)}) {
    _serverSyncTimer?.cancel();
    _serverSyncTimer = Timer(delay, () => unawaited(reloadFromServer(keepVisible: true)));
  }

  Future<void> ensureLoaded() async {
    if (_boot != null) return;
    _loadFuture ??= reloadFromServer(keepVisible: false);
    await _loadFuture;
  }

  Future<void> _hydrateEmptyHomeBlocks() async {
    final boot = _boot;
    if (boot == null || !siteEditorPreviewHomeBlocksEmpty(boot)) return;
    try {
      final draft = await api.draftGet(row.siteIid.toInt());
      if (_disposed || !identical(_boot, boot)) return;
      siteEditorPreviewApplyDocToBoot(boot, row, draft.doc);
    } catch (_) {
      if (_disposed || !identical(_boot, boot)) return;
      siteEditorPreviewApplyDocToBoot(boot, row, SiteDoc());
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> reloadFromServer({required bool keepVisible}) async {
    if (_disposed) return;
    if (!keepVisible) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final bootMode = mode == SitePreviewMode.draft
          ? SiteBootMode.SITE_BOOT_MODE_DRAFT
          : SiteBootMode.SITE_BOOT_MODE_PUBLISHED;
      final res = await api.bootGet(row.siteIid.toInt(), mode: bootMode);
      final raw = res.bootJson;
      if (raw.isEmpty) throw 'Site boot payload missing';
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw 'Invalid site boot payload';
      _boot = decoded;
      _error = null;
    } catch (e) {
      _error = '$e';
    } finally {
      if (!_disposed) {
        _loading = false;
        _loadFuture = null;
        notifyListeners();
      }
    }
    if (!_disposed && _boot != null) {
      unawaited(_hydrateEmptyHomeBlocks());
    }
  }

  void setMode(SitePreviewMode next) {
    if (_disposed || mode == next) return;
    mode = next;
    unawaited(reloadFromServer(keepVisible: _boot != null));
  }

  @override
  void dispose() {
    _disposed = true;
    _serverSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
