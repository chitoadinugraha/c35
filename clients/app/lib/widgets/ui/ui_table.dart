import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:alienai_c35/widgets/ui/ui_col_cell.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _panel = Color(0xFF111114);
const _head = Color(0xFF18181B);
const _accent = Color(0xFF34D399);
const _selected = Color(0xFF1F2937);

typedef UiTableCellCommit = Future<void> Function(String rowKey, ColDef col, String value);

/// Per-cell override. Return null to use the built-in renderer for [scope.col.type].
typedef UiTableCellBuilder = Widget? Function(UiTableCellScope scope);

/// Full row override. Return null to use the built-in row + optional [expandedBuilder].
typedef UiTableRowBuilder = List<Widget>? Function(UiTableRowScope scope);

class UiTableCellScope {
  const UiTableCellScope({
    required this.rowKey,
    required this.row,
    required this.col,
    required this.value,
    this.onCommit,
  });

  final String rowKey;
  final Map<String, String> row;
  final ColDef col;
  final String value;
  final Future<void> Function(String value)? onCommit;
}

class UiTableRowScope {
  const UiTableRowScope({
    required this.rowKey,
    required this.row,
    required this.cols,
    required this.expanded,
    required this.tableWidth,
    required this.defaultTiles,
    this.onExpandToggle,
    this.onRowTap,
  });

  final String rowKey;
  final Map<String, String> row;
  final List<ColDef> cols;
  final bool expanded;
  final double tableWidth;
  final List<Widget> defaultTiles;
  final VoidCallback? onExpandToggle;
  final VoidCallback? onRowTap;
}

class UiTable extends StatefulWidget {
  const UiTable({
    super.key,
    required this.def,
    required this.rows,
    this.loading = false,
    this.searchQuery = '',
    this.onCellCommit,
    this.onAddRow,
    this.onRowTap,
    this.cellBuilder,
    this.rowBuilder,
    this.expandedBuilder,
    this.colCellHost,
  });

  final TableDef def;
  final List<Map<String, String>> rows;
  final bool loading;
  final String searchQuery;
  final UiTableCellCommit? onCellCommit;
  final VoidCallback? onAddRow;
  final void Function(String rowKey)? onRowTap;
  final UiTableCellBuilder? cellBuilder;
  final UiTableRowBuilder? rowBuilder;
  final Widget Function(String rowKey)? expandedBuilder;
  final UiColCellHost? colCellHost;

  @override
  State<UiTable> createState() => _UiTableState();
}

class _UiTableState extends State<UiTable> {
  String? _sortCol;
  var _sortAsc = true;
  final _expanded = <String>{};

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

  bool _editable(ColDef col) => !col.readonly && col.inlineEditable && widget.onCellCommit != null;

  Future<void> Function(String value)? _cellCommit(String rowKey, ColDef col) =>
      widget.onCellCommit == null ? null : (value) => widget.onCellCommit!(rowKey, col, value);

  Widget _cell(String rowKey, ColDef col, String value, Map<String, String> row) {
    final custom = widget.cellBuilder?.call(UiTableCellScope(
      rowKey: rowKey,
      row: row,
      col: col,
      value: value,
      onCommit: _cellCommit(rowKey, col),
    ));
    if (custom != null) return custom;
    return uiColCellBuild(UiColCellScope(
      context: context,
      rowKey: rowKey,
      row: row,
      col: col,
      value: value,
      editable: _editable(col),
      onCommit: _cellCommit(rowKey, col),
      host: widget.colCellHost,
    ));
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

  void _toggleExpanded(String rowKey) => setState(() {
        if (_expanded.contains(rowKey)) {
          _expanded.remove(rowKey);
        } else {
          _expanded.add(rowKey);
        }
      });

  List<Widget> _defaultRowTiles(List<ColDef> cols, Map<String, String> row) {
    final rowKey = siteRowKey(widget.def, row);
    final expanded = _expanded.contains(rowKey);
    return [
      Material(
        color: expanded ? _selected : Colors.transparent,
        child: InkWell(
          onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(rowKey),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _border.withValues(alpha: 0.6))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.expandedBuilder != null)
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: _muted),
                      onPressed: () => _toggleExpanded(rowKey),
                    ),
                  ),
                for (final col in cols)
                  SizedBox(
                    width: _colWidth(col),
                    child: _cell(rowKey, col, row[col.key] ?? '', row),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (expanded && widget.expandedBuilder != null)
        SizedBox(
          width: _tableWidth(cols),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: _head,
            child: widget.expandedBuilder!(rowKey),
          ),
        ),
    ];
  }

  List<Widget> _rowTiles(List<ColDef> cols, Map<String, String> row) {
    final rowKey = siteRowKey(widget.def, row);
    final expanded = _expanded.contains(rowKey);
    final defaultTiles = _defaultRowTiles(cols, row);
    final custom = widget.rowBuilder?.call(UiTableRowScope(
      rowKey: rowKey,
      row: row,
      cols: cols,
      expanded: expanded,
      tableWidth: _tableWidth(cols),
      defaultTiles: defaultTiles,
      onExpandToggle: widget.expandedBuilder == null ? null : () => _toggleExpanded(rowKey),
      onRowTap: widget.onRowTap == null ? null : () => widget.onRowTap!(rowKey),
    ));
    return custom ?? defaultTiles;
  }

  double _tableWidth(List<ColDef> cols) {
    var w = widget.expandedBuilder != null ? 36.0 : 0.0;
    for (final col in cols) {
      w += _colWidth(col);
    }
    return w;
  }

  double _colWidth(ColDef col) => switch (col.type) {
        ColType.COL_TYPE_BOOL => 64,
        ColType.COL_TYPE_INT => 96,
        ColType.COL_TYPE_MONEY => 120,
        ColType.COL_TYPE_TS => 140,
        ColType.COL_TYPE_JSON => 220,
        _ => 160,
      };
}
