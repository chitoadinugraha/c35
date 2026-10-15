import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';

typedef UiStaffSitePickerAction = void Function(String siteIid);

Future<void> uiStaffSitePickerOpen({
  required BuildContext context,
  required ChatConn chatConn,
  required UiStaffSitePickerAction onEdit,
}) async {
  final picked = await uiDialogShow<IoAskItem>(
    context: context,
    builder: (_) => UiStaffSitePickerDialog(chatConn: chatConn),
  );
  if (picked != null) onEdit(picked.id);
}

class UiStaffSitePickerDialog extends StatefulWidget {
  const UiStaffSitePickerDialog({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<UiStaffSitePickerDialog> createState() => _UiStaffSitePickerDialogState();
}

class _UiStaffSitePickerDialogState extends State<UiStaffSitePickerDialog> {
  late final TextEditingController _searchCtrl = TextEditingController();
  final _items = <IoAskItem>[];
  var _loading = false;
  Timer? _debounce;
  var _searchGen = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _items.clear();
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () => unawaited(_runSearch(q)));
  }

  Future<void> _runSearch(String q) async {
    final gen = ++_searchGen;
    setState(() => _loading = true);
    try {
      final rows = await siteListFetch(widget.chatConn, query: q, limit: 40);
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows.map(_rowToItem));
      });
    } finally {
      if (mounted && gen == _searchGen) setState(() => _loading = false);
    }
  }

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
    );
  }

  @override
  Widget build(BuildContext context) => IoAskItemsDialog(
        semanticsLabel: 'Edit site',
        searchHint: 'Search all sites…',
        searchController: _searchCtrl,
        onSearchChanged: _onSearchChanged,
        clientSearch: false,
        popOnSelect: true,
        items: _items,
        loading: _loading,
        emptyText: 'Type a site name, slug, or id',
        noMatchText: 'No sites match',
        dividerBelowHeader: true,
        bodyGap: 0,
      );
}
