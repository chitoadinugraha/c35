import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _panel = Color(0xFF111114);
const _head = Color(0xFF18181B);
const _accent = Color(0xFF34D399);
const _selected = Color(0xFF1F2937);

typedef UiTableCellCommit = Future<void> Function(String rowKey, ColDef col, String value);

class UiTable extends StatefulWidget {
  const UiTable({
    super.key,
    required this.def,
    required this.rows,
    this.loading = false,
    this.searchQuery = '',
    this.onCellCommit,
    this.onAddRow,
    this.expandedBuilder,
  });

  final TableDef def;
  final List<Map<String, String>> rows;
  final bool loading;
  final String searchQuery;
  final UiTableCellCommit? onCellCommit;
  final VoidCallback? onAddRow;
  final Widget Function(String rowKey)? expandedBuilder;

  @override
  State<UiTable> createState() => _UiTableState();
}

class _UiTableState extends State<UiTable> {
  String? _sortCol;
  var _sortAsc = true;
  final _expanded = <String>{};
  final _editing = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _editing.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, String>> get _visible {
    final filtered = uiTableFilterRows(widget.rows, widget.searchQuery, widget.def.columns);
    return uiTableSortRows(filtered, _sortCol, ascending: _sortAsc);
  }

  void _toggleSort(ColDef col) {
    setState(() {
      if (_sortCol == col.key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col.key;
        _sortAsc = true;
      }
    });
  }

  TextEditingController _ctrl(String rowKey, ColDef col, String value) {
    final id = '$rowKey:${col.key}';
    return _editing.putIfAbsent(id, () => TextEditingController(text: value));
  }

  Future<void> _commit(String rowKey, ColDef col) async {
    final id = '$rowKey:${col.key}';
    final ctrl = _editing[id];
    if (ctrl == null || widget.onCellCommit == null) return;
    await widget.onCellCommit!(rowKey, col, ctrl.text.trim());
  }

  bool _editable(ColDef col) => !col.readonly && col.inlineEditable;

  Widget _cell(String rowKey, ColDef col, String value) {
    if (!_editable(col)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(value, style: const TextStyle(color: _text, fontSize: 13)),
      );
    }
    if (col.type == ColType.COL_TYPE_BOOL) {
      final on = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
      return Center(
        child: Switch.adaptive(
          value: on,
          activeTrackColor: _accent,
          onChanged: widget.onCellCommit == null
              ? null
              : (v) => widget.onCellCommit!(rowKey, col, v ? 'yes' : 'no'),
        ),
      );
    }
    final ctrl = _ctrl(rowKey, col, value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: _text, fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accent)),
        ),
        onSubmitted: (_) => _commit(rowKey, col),
        onEditingComplete: () => _commit(rowKey, col),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final cols = widget.def.columns.where((c) => c.key.isNotEmpty).toList(growable: false);
    if (cols.isEmpty) return UiEmptyState.noMatches('columns');
    final rows = _visible;
    if (rows.isEmpty) {
      return Column(
        children: [
          if (widget.onAddRow != null) _toolbar(),
          Expanded(child: UiEmptyState.noMatches(widget.def.label.isNotEmpty ? widget.def.label : 'rows')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onAddRow != null) _toolbar(),
        Expanded(
          child: ColoredBox(
            color: _panel,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(cols),
                      for (final row in rows) ..._rowTiles(cols, row),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toolbar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onAddRow,
            icon: const Icon(Icons.add, size: 18, color: _accent),
            label: const Text('Add row', style: TextStyle(color: _accent)),
          ),
        ),
      );

  Widget _header(List<ColDef> cols) => Container(
        color: _head,
        child: Row(
          children: [
            if (widget.expandedBuilder != null) const SizedBox(width: 36),
            for (final col in cols)
              SizedBox(
                width: _colWidth(col),
                child: InkWell(
                  onTap: () => _toggleSort(col),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            col.label.isNotEmpty ? col.label : col.key,
                            style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_sortCol == col.key)
                          Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: _muted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  List<Widget> _rowTiles(List<ColDef> cols, Map<String, String> row) {
    final rowKey = siteRowKey(widget.def, row);
    final expanded = _expanded.contains(rowKey);
    return [
      Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6))),
          color: expanded ? _selected : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.expandedBuilder != null)
              SizedBox(
                width: 36,
                child: IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: _muted),
                  onPressed: () => setState(() {
                    if (expanded) {
                      _expanded.remove(rowKey);
                    } else {
                      _expanded.add(rowKey);
                    }
                  }),
                ),
              ),
            for (final col in cols)
              SizedBox(
                width: _colWidth(col),
                child: _cell(rowKey, col, row[col.key] ?? ''),
              ),
          ],
        ),
      ),
      if (expanded && widget.expandedBuilder != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: _head,
          child: widget.expandedBuilder!(rowKey),
        ),
    ];
  }

  double _colWidth(ColDef col) => switch (col.type) {
        ColType.COL_TYPE_BOOL => 88,
        ColType.COL_TYPE_INT => 96,
        ColType.COL_TYPE_MONEY => 120,
        ColType.COL_TYPE_TS => 140,
        ColType.COL_TYPE_JSON => 220,
        _ => 160,
      };
}
