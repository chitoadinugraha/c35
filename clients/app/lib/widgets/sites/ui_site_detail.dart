import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_menu.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_shell.dart';
import 'package:flutter/material.dart';

class UiSiteDetail extends StatelessWidget {
  const UiSiteDetail({
    super.key,
    required this.row,
    required this.api,
    this.onBack,
    this.title,
    this.initialTabRoute,
    this.initialEditorSection = siteEditorMenuDefaultId,
  });

  final SiteRow row;
  final SiteApi api;
  final VoidCallback? onBack;
  final String? title;
  final String? initialTabRoute;
  final String initialEditorSection;

  String _editorInitialSection() => switch (initialTabRoute) {
        'site.product' => 'products',
        'site.contact' => 'contacts',
        'site.object' => 'objects',
        'site.settings' => 'capabilities',
        _ => initialEditorSection,
      };

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF08080A),
        child: UiSiteEditorShell(
          row: row,
          api: api,
          initialSection: _editorInitialSection(),
          onBack: onBack,
          title: title,
        ),
      );
}
