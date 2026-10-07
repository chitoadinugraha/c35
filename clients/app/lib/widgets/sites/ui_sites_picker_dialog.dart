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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => UiDialog(
          maxWidth: 360,
          padding: EdgeInsets.zero,
          inset: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: uiDialogInsetCompact,
                child: UiDialogSearchHeader(
                  controller: _searchCtrl,
                  hintText: 'Search sites…',
                  onChanged: _store.searchPut,
                  searchSuffix: IconButton(
                    tooltip: 'Refresh',
                    onPressed: _store.loading ? null : () => unawaited(_store.refresh()),
                    icon: _store.loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: uiDialogMuted),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18, color: uiDialogMuted),
                  ),
                  beforeClose: [
                    UiSiteAddMenu(
                      store: _store,
                      onCreated: (id) => _popThen(() => widget.onEdit?.call(id)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: uiDialogBorder),
              if (_store.loading && _store.rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: uiDialogMuted))),
                )
              else if (_store.rows.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No sites yet', textAlign: TextAlign.center, style: TextStyle(color: uiDialogMuted, fontSize: 13)))
              else if (_store.filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('No matches', textAlign: TextAlign.center, style: TextStyle(color: uiDialogMuted, fontSize: 13)))
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: UiSitesPickerRows(
                    rows: _store.filtered,
                    api: _store.api,
                    onVisit: (row) => unawaited(_visitSite(context, row, _store.api)),
                    onEdit: _edit,
                    onPos: (row) => unawaited(_pos(row)),
                  ),
                ),
            ],
          ),
        ),
      );
}

class UiSitesPickerRows extends StatelessWidget {
  const UiSitesPickerRows({
    super.key,
    required this.rows,
    required this.api,
    required this.onVisit,
    required this.onEdit,
    required this.onPos,
  });

  final List<SiteRow> rows;
  final SiteApi api;
  final void Function(SiteRow row) onVisit;
  final void Function(String siteIid) onEdit;
  final void Function(SiteRow row) onPos;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 52, color: uiDialogBorder),
        itemBuilder: (context, i) => _UiSitesPickerRow(
          row: rows[i],
          onVisit: () => onVisit(rows[i]),
          onEdit: () => onEdit(rows[i].siteIid.toString()),
          onPos: () => onPos(rows[i]),
        ),
      );
}

class _UiSitesPickerRow extends StatelessWidget {
  const _UiSitesPickerRow({
    required this.row,
    required this.onVisit,
    required this.onEdit,
    required this.onPos,
  });

  final SiteRow row;
  final VoidCallback onVisit;
  final VoidCallback onEdit;
  final VoidCallback onPos;

  String get _slug => row.alienId.isNotEmpty ? row.alienId : row.siteIid.toString();

  String get _title => row.name.isNotEmpty ? row.name : _slug;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: uiDialogBorder,
              child: row.pic.isNotEmpty
                  ? ClipOval(child: Image.network(row.pic, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _globe()))
                  : _globe(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: uiDialogTitleColor, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('$siteUrlPrefix$_slug', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: uiDialogMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: [
                      _UiSitesPickerAction(label: 'Visit', onTap: onVisit),
                      _UiSitesPickerAction(label: 'Edit', onTap: onEdit),
                      _UiSitesPickerAction(label: 'POS', onTap: onPos),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _globe() => const Icon(Icons.language_outlined, size: 15, color: uiDialogMuted);
}

class _UiSitesPickerAction extends StatelessWidget {
  const _UiSitesPickerAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const _labelColor = Color(0xFFE4E4E7);
  static const _borderColor = Color(0xFF52525B);
  static const _fillColor = Color(0xFF3F3F46);

  @override
  Widget build(BuildContext context) => Material(
        color: _fillColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(label, style: const TextStyle(color: _labelColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
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
