import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/sites/in_site_create.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiSiteAddMenu extends StatelessWidget {
  const UiSiteAddMenu({super.key, required this.store});

  final SiteStore store;

  Future<void> _onCreate(BuildContext context) async {
    final created = await inSiteCreateShow(context, store: store);
    if (created == null || !context.mounted) return;
    store.select(created.siteIid.toString());
  }

  @override
  Widget build(BuildContext context) => uiPopupMenuTooltipWrap(
        tooltip: 'Add site',
        menu: PopupMenuButton<String>(
          tooltip: uiPopupMenuTooltipText('Add site'),
          padding: EdgeInsets.zero,
          icon: uiPopupMenuIcon(Icons.add),
          iconSize: 18,
          color: const Color(0xFF18181B),
          onSelected: (v) => switch (v) {
            'create' => _onCreate(context),
            _ => null,
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'create',
              child: ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text('Create site'),
                subtitle: Text('Name, URL, and features'),
              ),
            ),
          ],
        ),
      );
}
