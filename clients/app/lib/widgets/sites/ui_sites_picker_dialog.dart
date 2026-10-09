import 'dart:async';
import 'dart:io' show Platform;

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/platform_site.dart';
import 'package:alienai_c35/c/site/pos_shortcut_install.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_menu.dart';
import 'package:alienai_c35/widgets/sites/io_site_delete_dialog.dart';
import 'package:alienai_c35/widgets/sites/ui_site_add_menu.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:alienai_c35/widgets/ui/ui_alert.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UiSitesPickerSiteAction = void Function(String siteIid);

Future<void> uiSitesPickerOpen({
  required BuildContext context,
  required ChatConn chatConn,
  ChatStore? shellStore,
  UiSitesPickerSiteAction? onEdit,
  UiSitesPickerSiteAction? onPos,
}) =>
    uiDialogShow<void>(
      context: context,
      builder: (_) => UiSitesPickerDialog(chatConn: chatConn, shellStore: shellStore, onEdit: onEdit, onPos: onPos),
    );

class UiSitesPickerDialog extends StatefulWidget {
  const UiSitesPickerDialog({
    super.key,
    required this.chatConn,
    this.shellStore,
    this.onEdit,
    this.onPos,
  });

  final ChatConn chatConn;
  final ChatStore? shellStore;
  final UiSitesPickerSiteAction? onEdit;
  final UiSitesPickerSiteAction? onPos;

  @override
  State<UiSitesPickerDialog> createState() => _UiSitesPickerDialogState();
}

class _UiSitesPickerDialogState extends State<UiSitesPickerDialog> {
  late final SiteStore _store = SiteStore(conn: widget.chatConn, shellStore: widget.shellStore);
  late final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_store.refresh());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _popThen(VoidCallback? fn) {
    Navigator.pop(context);
    fn?.call();
  }

  void _edit(String siteIid) => _popThen(() => widget.onEdit?.call(siteIid));

  bool _canDeleteSite(SiteRow row) => !isPlatformSiteAlienId(row.alienId);

  Future<void> _archiveSite(SiteRow row) async {
    final id = row.siteIid.toString();
    final name = row.name.isNotEmpty ? row.name : row.alienId;
    try {
      await _store.archivePut(id, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" archived'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) await uiAlertError(context, e);
    }
  }

  Future<void> _deleteSite(SiteRow row) async {
    final ok = await siteDeleteConfirmShow(context, store: _store, row: row);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Site deleted'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _siteCommerceOk(SiteRow row) async {
    try {
      final config = await _store.api.configGet(row.siteIid.toInt());
      final commerce = siteCapabilitiesParse(config.capabilitiesJson)['commerce'] ?? true;
      if (!commerce) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commerce is disabled for this site'), behavior: SnackBarBehavior.floating),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      lError('sites picker commerce: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
      return false;
    }
  }

  Future<void> _addPosShortcut(SiteRow row) async {
    if (!await _siteCommerceOk(row)) return;
    final name = row.name.isNotEmpty ? row.name : row.alienId;
    final siteIid = row.siteIid.toString();
    final res = await posShortcutInstall(siteIid: siteIid, siteName: name);
    if (!mounted) return;
    final msg = switch (res) {
      PosShortcutInstallResult.ok => 'Shortcut added: "$name - POS"',
      PosShortcutInstallResult.unsupported => 'POS shortcuts are not supported on this device',
      PosShortcutInstallResult.failed => 'Could not add POS shortcut',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _siteRowMenu(BuildContext context, SiteRow row, Offset global) async {
    final canDelete = _canDeleteSite(row);
    final showShortcut = !kIsWeb && (Platform.isWindows || Platform.isAndroid);
    final action = await uiBotMenuShowAt<String>(
      context: context,
      global: global,
      items: [
        if (showShortcut)
          uiBotMenuItem(value: 'pos_shortcut', icon: Icons.add_to_home_screen_outlined, label: 'Add POS Shortcut'),
        uiBotMenuItem(value: 'archive', icon: Icons.archive_outlined, label: 'Archive'),
        if (canDelete) ...[
          uiBotMenuDivider,
          uiBotMenuItem(value: 'delete', icon: Icons.delete_outline, label: 'Delete', destructive: true),
        ],
      ],
    );
    if (action == null || !mounted) return;
    if (action == 'pos_shortcut') await _addPosShortcut(row);
    if (action == 'archive') await _archiveSite(row);
    if (action == 'delete') await _deleteSite(row);
  }

  Widget _siteRowMenuButton(SiteRow row) => Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Site options',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.more_vert, size: 20, color: uiDialogMuted),
          onPressed: () {
            final box = ctx.findRenderObject() as RenderBox?;
            if (box == null) return;
            final pos = box.localToGlobal(Offset(box.size.width, box.size.height / 2));
            unawaited(_siteRowMenu(context, row, pos));
          },
        ),
      );

  Future<void> _pos(SiteRow row) async {
    if (!await _siteCommerceOk(row)) return;
    _popThen(() => widget.onPos?.call(row.siteIid.toString()));
  }

  List<IoAskItem> _items() => _store.filtered.map(_rowToItem).toList();

  IoAskItem _rowToItem(SiteRow row) {
    final id = row.siteIid.toString();
    final slug = row.alienId.isNotEmpty ? row.alienId : id;
    final title = row.name.isNotEmpty ? row.name : slug;
    return IoAskItem(
      id: id,
      title: title,
      subtitle: '$siteUrlPrefix$slug',
      imageUrl: row.pic,
      icon: Icons.language_outlined,
      actions: [
        IoAskItemAction(label: 'Visit', icon: Icons.open_in_new_rounded, onTap: () => unawaited(_visitSite(context, row, _store.api))),
        IoAskItemAction(label: 'Edit', icon: Icons.edit_outlined, onTap: () => _edit(id)),
        IoAskItemAction(label: 'POS', icon: Icons.point_of_sale_outlined, onTap: () => unawaited(_pos(row))),
      ],
      trailing: _siteRowMenuButton(row),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => IoAskItemsDialog(
          semanticsLabel: 'Sites',
          searchHint: 'Search sites…',
          searchController: _searchCtrl,
          onSearchChanged: _store.searchPut,
          clientSearch: false,
          popOnSelect: false,
          sourceItemCount: _store.rows.length,
          items: _items(),
          loading: _store.loading && _store.rows.isEmpty,
          emptyText: 'No sites yet',
          dividerBelowHeader: true,
          bodyGap: 0,
          searchSuffix: IconButton(
            tooltip: _store.refreshing ? 'Stop' : 'Refresh',
            onPressed: _store.refreshing ? _store.refreshStop : () => unawaited(_store.refresh()),
            icon: _store.refreshing
                ? const Icon(Icons.stop_rounded, size: 18, color: Color(0xFFEF4444))
                : const Icon(Icons.refresh_rounded, size: 18, color: uiDialogMuted),
          ),
          beforeClose: [
            UiSiteAddMenu(
              store: _store,
              onCreated: (id) => _popThen(() => widget.onEdit?.call(id)),
            ),
          ],
        ),
      );
}

Future<void> _visitSite(BuildContext context, SiteRow row, SiteApi api) async {
  try {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    final slug = row.alienId.isNotEmpty ? row.alienId : row.siteIid.toString();
    late final String url;
    if (row.publishedVersionId.isNotEmpty) {
      url = '$origin/$slug';
    } else {
      final res = await api.sitePreviewToken(row.siteIid.toInt());
      final token = res.token;
      if (token.isEmpty) throw 'Preview token missing';
      url = '$origin/$slug?draft=1&ptoken=${Uri.encodeComponent(token)}';
    }
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL'), behavior: SnackBarBehavior.floating));
    }
  } catch (e) {
    lError('sites picker visit: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
