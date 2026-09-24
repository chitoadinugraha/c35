import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/inst_fields.dart';
import 'package:alienai_c35/c/admin/inst_table.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/inst.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_field_filter.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:alienai_c35/widgets/ui/ui_search_toggle.dart';
import 'package:alienai_c35/widgets/ui/ui_table.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _border = Color(0xFF27272A);

class PageRootInst extends StatefulWidget {
  const PageRootInst({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootInst> createState() => _PageRootInstState();
}

class _PageRootInstState extends State<PageRootInst> {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  final _docs = <String, InstDoc>{};
  var _loading = false;
  var _search = '';
  final _filterValues = <String, String>{};

  @override
  void initState() {
    super.initState();
    if (Session.instance.isRoot) unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final items = await _api.instList();
      _docs
        ..clear()
        ..addEntries(items.map((d) => MapEntry(d.id, d)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, String>> get _rows => instApplyFilters(_docs.values.map(instCells).toList(growable: false), _filterValues);

  Future<void> _onCellCommit(String rowKey, ColDef col, String value) async {
    final base = _docs[rowKey];
    final cells = Map<String, String>.from(instCells(base ?? InstDoc(id: rowKey)));
    cells[col.key] = value;
    final saved = await _api.instPut(instFromCells(cells, base: base));
    _docs[saved.id] = saved;
    setState(() {});
  }

  Future<void> _onAddRow() async {
    final id = 'inst.new.${DateTime.now().millisecondsSinceEpoch}';
    final scope = _filterValues['scope']?.trim();
    final doc = InstDoc(id: id, scope: scope?.isNotEmpty == true ? scope! : 'global', kind: 'task', inst: '', enabled: true, priority: 50);
    final saved = await _api.instPut(doc);
    _docs[saved.id] = saved;
    setState(() {});
  }

  Future<void> _onDelete(String id) async {
    await _api.instDelete(id);
    _docs.remove(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'Inst',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: _muted))),
      );
    }
    return UiPage(
      title: 'Inst',
      onBack: () => Navigator.pop(context),
      trailing: UiSearchToggle(onSearch: (q) => setState(() => _search = q)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: UiFieldFilter(
              fields: instFilterFields(),
              values: _filterValues,
              onChanged: (v) => setState(() {
                _filterValues
                  ..clear()
                  ..addAll(v);
              }),
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: UiTable(
              def: instTableDef(),
              rows: _rows,
              loading: _loading,
              searchQuery: _search,
              onCellCommit: _onCellCommit,
              onAddRow: _onAddRow,
              expandedBuilder: (rowKey) => _InstExpanded(
                doc: _docs[rowKey],
                onSave: (doc) async {
                  final saved = await _api.instPut(doc);
                  _docs[saved.id] = saved;
                  setState(() {});
                },
                onDelete: () => unawaited(_onDelete(rowKey)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstExpanded extends StatefulWidget {
  const _InstExpanded({required this.doc, required this.onSave, required this.onDelete});

  final InstDoc? doc;
  final ValueChanged<InstDoc> onSave;
  final VoidCallback onDelete;

  @override
  State<_InstExpanded> createState() => _InstExpandedState();
}

class _InstExpandedState extends State<_InstExpanded> {
  late final _instCtrl = TextEditingController(text: widget.doc?.inst ?? '');
  late final _triggersCtrl = TextEditingController(text: widget.doc?.triggers.join(', ') ?? '');

  @override
  void dispose() {
    _instCtrl.dispose();
    _triggersCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final doc = (widget.doc ?? InstDoc()).clone();
    doc.inst = _instCtrl.text;
    doc.triggers.clear();
    doc.triggers.addAll(_triggersCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    widget.onSave(doc);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Instruction', style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _instCtrl,
            maxLines: 6,
            style: const TextStyle(color: _text, fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: _border))),
          ),
          const SizedBox(height: 10),
          const Text('Triggers (comma-separated)', style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: _triggersCtrl,
            style: const TextStyle(color: _text, fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: _border))),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFF87171)), label: const Text('Delete', style: TextStyle(color: Color(0xFFF87171)))),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      );
}
