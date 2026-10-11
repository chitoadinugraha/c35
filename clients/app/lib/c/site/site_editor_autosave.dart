import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:flutter/material.dart';

const siteEditorAutosaveDebounce = Duration(milliseconds: 500);

void siteEditorScheduleSave(
  BuildContext context, {
  required String key,
  Duration debounce = siteEditorAutosaveDebounce,
  required Future<void> Function() save,
}) {
  SiteEditorSaveScope.flushCoordinator(context).schedule(key, debounce, save);
}

void siteEditorCancelSave(BuildContext context, String key) {
  SiteEditorSaveScope.flushCoordinator(context).cancel(key);
}

void siteEditorPreviewPatch(BuildContext context, void Function(Map<String, dynamic> boot) patch) {
  SiteEditorSaveScope.maybeOf(context)?.preview.patch(patch);
}
