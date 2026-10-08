import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_shell.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _text = Color(0xFFF4F4F5);

class UiSiteDetail extends StatelessWidget {
  const UiSiteDetail({
    super.key,
    required this.row,
    required this.api,
    this.onBack,
    this.title,
    this.initialTabRoute,
    this.initialEditorSection = 'products',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onBack != null || title != null) _navBarWrap(context),
            Expanded(
              child: UiSiteEditorShell(
                row: row,
                api: api,
                initialSection: _editorInitialSection(),
              ),
            ),
          ],
        ),
      );

  Widget _navBarWrap(BuildContext context) => uiDesktopWindow ? _navBar() : uiMobileTopBar(context, _navBar());

  Widget _navBar() => Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: _text)),
            Expanded(
              child: Text(
                title ?? row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
