import 'package:alienai_c35/c/pb/c35/report.pb.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _bg = Color(0xFF18181B);
const _panel = Color(0xFF111114);
const _accent = Color(0xFF34D399);

class UiReportWidgetView extends StatelessWidget {
  const UiReportWidgetView({super.key, required this.widgets});

  final List<UiWidget> widgets;

  @override
  Widget build(BuildContext context) {
    if (widgets.isEmpty) return const SizedBox.shrink();
    final cards = <UiWidget>[];
    final tables = <UiWidget>[];
    for (final w in widgets) {
      if (w.hasMetricsCard()) {
        cards.add(w);
      } else if (w.hasTable()) {
        tables.add(w);
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cards.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards.map((w) => _MetricsCardView(card: w.metricsCard)).toList(),
            ),
          for (final w in tables) ...[
            if (cards.isNotEmpty) const SizedBox(height: 8),
            _ReportTableView(table: w.table),
          ],
        ],
      ),
    );
  }
}

class _MetricsCardView extends StatelessWidget {
  const _MetricsCardView({required this.card});

  final UiMetricsCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(card.value, style: const TextStyle(color: _accent, fontSize: 22, fontWeight: FontWeight.w600)),
          if (card.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(card.subtitle, style: const TextStyle(color: _muted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _ReportTableView extends StatelessWidget {
  const _ReportTableView({required this.table});

  final UiReportTable table;

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          headingRowColor: WidgetStateProperty.all(_bg),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          columnSpacing: 24,
          horizontalMargin: 12,
          columns: [
            for (final h in table.headers)
              DataColumn(
                label: Text(h, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ],
          rows: [
            for (final row in table.rows)
              DataRow(
                cells: [
                  for (var i = 0; i < table.headers.length; i++)
                    DataCell(Text(
                      i < row.cells.length ? row.cells[i] : '',
                      style: const TextStyle(color: _text, fontSize: 12),
                    )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
