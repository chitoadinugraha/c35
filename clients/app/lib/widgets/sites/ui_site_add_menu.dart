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
  Widget build(BuildContext context) => uiIconButton(
        tooltip: 'Create site',
        onPressed: () => _onCreate(context),
        icon: const Icon(Icons.add_rounded, size: 20, color: uiDialogMuted),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        visualDensity: VisualDensity.compact,
      );
}
