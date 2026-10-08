import 'package:alienai_c35/c/site/site_editor_save_bus.dart';
import 'package:flutter/material.dart';

class SiteEditorSaveScope extends InheritedNotifier<SiteEditorSaveBus> {
  const SiteEditorSaveScope({super.key, required SiteEditorSaveBus bus, required super.child}) : super(notifier: bus);

  static SiteEditorSaveBus of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SiteEditorSaveScope>();
    assert(scope != null, 'SiteEditorSaveScope not found');
    return scope!.notifier!;
  }

  static Future<T> run<T>(BuildContext context, Future<T> Function() fn) =>
      siteEditorSaveRun(of(context), fn);
}
