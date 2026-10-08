import 'package:flutter/material.dart';

class UiStockReportCard extends StatelessWidget {
  const UiStockReportCard({super.key, required this.body});

  final Map<String, dynamic> body;

  @override
  Widget build(BuildContext context) {
    final title = body['title']?.toString() ?? 'Stock report';
    final rowCount = body['row_count']?.toString() ?? '0';
    final qtyIn = body['qty_in']?.toString() ?? '0';
    final qtyOut = body['qty_out']?.toString() ?? '0';
    final truncated = body['truncated'] == true;
    final headers = _strings(body['headers']);
    final rows = _rows(body['rows']);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$rowCount rows. In $qtyIn, out $qtyOut.'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    for (final h in headers) DataColumn(label: Text(h)),
                  ],
                  rows: [
                    for (final row in rows)
                      DataRow(
                        cells: [
                          for (var i = 0; i < headers.length; i++)
                            DataCell(Text(i < row.length ? row[i] : '')),
                        ],
                      ),
                  ],
                ),
              ),
              if (truncated)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Showing ${rows.length} of $rowCount. Full rows are in the file.'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  List<List<String>> _rows(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((row) {
      if (row is! List) return <String>[];
      return row.map((c) => c.toString()).toList();
    }).toList();
  }
}
