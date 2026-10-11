import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Subscribes to [SiteEditorCatalogCache] and offers [ensureEditorCatalog] for section loads.
mixin SiteEditorCatalogListener<T extends StatefulWidget> on State<T> {
  SiteEditorCatalogCache? _catalogAttached;

  @protected
  SiteEditorCatalogCache? get editorCatalog => _catalogAttached;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = SiteEditorSaveScope.maybeOf(context)?.catalog;
    if (identical(next, _catalogAttached)) return;
    _catalogAttached?.removeListener(_catalogNotify);
    _catalogAttached = next;
    _catalogAttached?.addListener(_catalogNotify);
    if (_catalogAttached != null && _catalogAttached!.warmDone) {
      onEditorCatalogUpdated(_catalogAttached!);
    }
  }

  @override
  void dispose() {
    _catalogAttached?.removeListener(_catalogNotify);
    super.dispose();
  }

  void _catalogNotify() {
    if (!mounted || _catalogAttached == null) return;
    if (!_catalogAttached!.warmDone) return;
    onEditorCatalogUpdated(_catalogAttached!);
  }

  /// Returns true when warm catalog data was applied (no network list needed).
  Future<bool> ensureEditorCatalog() async {
    final cat = SiteEditorSaveScope.maybeOf(context)?.catalog;
    if (cat == null) return false;
    if (!cat.warmDone) await cat.ensureWarm();
    if (cat.warmDone && cat.warmError == null) {
      onEditorCatalogUpdated(cat);
      return true;
    }
    return false;
  }

  void onEditorCatalogUpdated(SiteEditorCatalogCache catalog);
}
