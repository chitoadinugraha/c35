import 'package:alienai_c35/c/site/site_editor_catalog_cache.dart';
import 'package:alienai_c35/c/site/site_editor_flush_coordinator.dart';
import 'package:alienai_c35/c/site/site_editor_preview_cache.dart';
import 'package:alienai_c35/c/site/site_editor_save_bus.dart';
import 'package:flutter/material.dart';

class SiteEditorSaveScope extends InheritedWidget {
  const SiteEditorSaveScope({
    super.key,
    required this.bus,
    required this.flush,
    required this.preview,
    required this.catalog,
    required super.child,
  });

  final SiteEditorSaveBus bus;
  final SiteEditorFlushCoordinator flush;
  final SiteEditorPreviewCache preview;
  final SiteEditorCatalogCache catalog;

  static SiteEditorSaveScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteEditorSaveScope>();

  static SiteEditorSaveScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SiteEditorSaveScope not found');
    return scope!;
  }

  static SiteEditorSaveBus saveBus(BuildContext context) => of(context).bus;

  static SiteEditorFlushCoordinator flushCoordinator(BuildContext context) => of(context).flush;

  static SiteEditorPreviewCache previewCache(BuildContext context) => of(context).preview;

  static SiteEditorCatalogCache catalogCache(BuildContext context) => of(context).catalog;

  static Future<T> run<T>(BuildContext context, Future<T> Function() fn) =>
      siteEditorSaveRun(saveBus(context), fn);

  static Future<void> flushPending(BuildContext context) => flushCoordinator(context).flush();

  static Future<void> waitWhileSaving(BuildContext context) async {
    final scope = maybeOf(context);
    if (scope == null) return;
    await waitWhileSavingBus(scope.bus);
  }

  /// Shell and other ancestors of [SiteEditorSaveScope] should use this directly.
  static Future<void> waitWhileSavingBus(SiteEditorSaveBus bus) async {
    if (!bus.saving) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var spins = 0;
    while (bus.saving && spins < 400) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      spins++;
    }
  }

  @override
  bool updateShouldNotify(SiteEditorSaveScope oldWidget) =>
      oldWidget.bus != bus ||
      oldWidget.flush != flush ||
      oldWidget.preview != preview ||
      oldWidget.catalog != catalog;
}
