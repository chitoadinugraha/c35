import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/object_table.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/object.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_search_toggle.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class PageRootObjects extends StatefulWidget {
  const PageRootObjects({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootObjects> createState() => _PageRootObjectsState();
}

class _PageRootObjectsState extends State<PageRootObjects> {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  final _docs = <String, ObjectAliasDoc>{};
  var _loading = false;
  var _search = '';
  var _showAll = false;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isRoot) unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final q = _search.trim();
      final items = await _api.objectAliasList(
        verified: _showAll ? null : false,
        q: q.isEmpty ? null : q,
      );
      _docs
        ..clear()
        ..addEntries(items.map((d) => MapEntry('${d.id}', d)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, String>> get _rows => _docs.values.map(objectAliasCells).toList(growable: false);

  Future<void> _onCellCommit(String rowKey, ColDef col, String value) async {
    final base = _docs[rowKey];
    final cells = Map<String, String>.from(objectAliasCells(base ?? ObjectAliasDoc()));
    cells[col.key] = value;
    final saved = await _api.objectAliasPut(objectAliasFromCells(cells, base: base));
    _docs['${saved.id}'] = saved;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'Objects',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: _muted))),
      );
    }
    return UiPage(
      title: 'Objects',
      onBack: () => Navigator.pop(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            label: const Text('Unverified', style: TextStyle(fontSize: 12)),
            selected: !_showAll,
            selectedColor: _accent.withValues(alpha: 0.25),
            checkmarkColor: _accent,
            labelStyle: TextStyle(color: !_showAll ? _text : _muted, fontSize: 12),
            side: BorderSide(color: !_showAll ? _accent : const Color(0xFF27272A)),
            onSelected: (_) {
              setState(() => _showAll = false);
              unawaited(_reload());
            },
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('All', style: TextStyle(fontSize: 12)),
            selected: _showAll,
            selectedColor: _accent.withValues(alpha: 0.25),
            checkmarkColor: _accent,
            labelStyle: TextStyle(color: _showAll ? _text : _muted, fontSize: 12),
            side: BorderSide(color: _showAll ? _accent : const Color(0xFF27272A)),
            onSelected: (_) {
              setState(() => _showAll = true);
              unawaited(_reload());
            },
          ),
          UiSearchToggle(onSearch: (q) {
            setState(() => _search = q);
            unawaited(_reload());
          }),
        ],
      ),
      body: UiTable(
        def: objectAliasTableDef(),
        rows: _rows,
        loading: _loading,
        onCellCommit: _onCellCommit,
        expandedBuilder: (rowKey) => _ObjectAliasExpanded(doc: _docs[rowKey]),
      ),
    );
  }
}

class _ObjectAliasExpanded extends StatelessWidget {
  const _ObjectAliasExpanded({required this.doc});

  final ObjectAliasDoc? doc;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Name', style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          SelectableText(doc?.name ?? '', style: const TextStyle(color: _text, fontSize: 12)),
          const SizedBox(height: 10),
          const Text('Object path', style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          SelectableText(doc?.objPath ?? '', style: const TextStyle(color: _text, fontSize: 12)),
        ],
      );
}
