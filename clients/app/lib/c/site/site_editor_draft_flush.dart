import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:flutter/material.dart';

/// Debounced persist of the shared [SiteDraftAdapter] (draft, config, dirty products).
void siteEditorScheduleDraftFlush(
  BuildContext context, {
  required String key,
  Duration debounce = siteEditorAutosaveDebounce,
}) {
  siteEditorScheduleSave(
    context,
    key: key,
    debounce: debounce,
    save: () => siteEditorFlushDraft(context),
  );
}

Future<void> siteEditorFlushDraft(BuildContext context) async {
  final adapter = SiteEditorSaveScope.maybeOf(context)?.draft;
  if (adapter == null) return;
  await SiteEditorSaveScope.run(context, () => adapter.flush());
}
