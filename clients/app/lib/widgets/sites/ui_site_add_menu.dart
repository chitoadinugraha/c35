import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/sites/in_site_create.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiSiteAddMenu extends StatelessWidget {
  const UiSiteAddMenu({super.key, required this.store, this.onCreated});

  final SiteStore store;
  final void Function(String siteIid)? onCreated;

  Future<void> _onCreate(BuildContext context) async {
    final created = await inSiteCreateShow(context, store: store);
    if (created == null || !context.mounted) return;
    final id = created.siteIid.toString();
    if (onCreated != null) {
      onCreated!(id);
    } else {
      store.select(id);
    }
  }

  @override
  Widget build(BuildContext context) => uiPopupMenuTooltipWrap(
        tooltip: 'Add site',
        menu: PopupMenuButton<String>(
          tooltip: uiPopupMenuTooltipText('Add site'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: uiPopupMenuIcon(Icons.add, size: 20, color: uiDialogMuted),
          iconSize: 20,
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
                subtitle: Text(
                  'Create website for personal or business (can use pos / queue / reservation, crm)',
                ),
              ),
            ),
          ],
        ),
      );
}
