import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/ui_site_add_menu.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UiSitesPickerSiteAction = void Function(String siteIid);

Future<void> uiSitesPickerOpen({
  required BuildContext context,
  required ChatConn chatConn,
  UiSitesPickerSiteAction? onEdit,
  UiSitesPickerSiteAction? onPos,
}) =>
    uiDialogShow<void>(
      context: context,
      builder: (_) => UiSitesPickerDialog(chatConn: chatConn, onEdit: onEdit, onPos: onPos),
    );

class UiSitesPickerDialog extends StatefulWidget {
  const UiSitesPickerDialog({
    super.key,
    required this.chatConn,
    this.onEdit,
    this.onPos,
  });

  final ChatConn chatConn;
  final UiSitesPickerSiteAction? onEdit;
  final UiSitesPickerSiteAction? onPos;

  @override
  State<UiSitesPickerDialog> createState() => _UiSitesPickerDialogState();
}

class _UiSitesPickerDialogState extends State<UiSitesPickerDialog> {
  late final SiteStore _store = SiteStore(conn: widget.chatConn);
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

  Future<void> _pos(SiteRow row) async {
    final siteIid = row.siteIid.toString();
    try {
      final config = await _store.api.configGet(row.siteIid.toInt());
      final commerce = siteCapabilitiesParse(config.capabilitiesJson)['commerce'] ?? true;
      if (!commerce) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commerce is disabled for this site'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
    } catch (e) {
      lError('sites picker pos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    _popThen(() => widget.onPos?.call(siteIid));
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
        IoAskItemAction(label: 'Visit', onTap: () => unawaited(_visitSite(context, row, _store.api))),
        IoAskItemAction(label: 'Edit', onTap: () => _edit(id)),
        IoAskItemAction(label: 'POS', onTap: () => unawaited(_pos(row))),
      ],
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
