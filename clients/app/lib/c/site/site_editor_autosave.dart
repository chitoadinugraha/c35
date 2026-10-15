import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:flutter/material.dart';

const siteEditorAutosaveDebounce = Duration(seconds: 2);

void siteEditorScheduleSave(
  BuildContext context, {
  required String key,
  Duration debounce = siteEditorAutosaveDebounce,
  required Future<void> Function() save,
}) {
  final scope = SiteEditorSaveScope.maybeOf(context);
  if (scope == null) return;
  scope.flush.schedule(key, debounce, () async {
    if (!context.mounted) return;
    await save();
  });
}

void siteEditorCancelSave(BuildContext context, String key) {
  SiteEditorSaveScope.flushCoordinator(context).cancel(key);
}

void siteEditorPreviewPatch(BuildContext context, void Function(Map<String, dynamic> boot) patch) {
  SiteEditorSaveScope.maybeOf(context)?.preview.patch(patch);
}
