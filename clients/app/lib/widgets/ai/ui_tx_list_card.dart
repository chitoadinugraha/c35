import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/material.dart';

class UiTxListCard extends StatelessWidget {
  const UiTxListCard({super.key, required this.body, this.locale = 'en-US'});

  final Map<String, dynamic> body;
  final String locale;

  bool get _id => locale.toLowerCase().startsWith('id');

  @override
  Widget build(BuildContext context) {
    final title = body['title']?.toString() ?? (_id ? 'Transaksi' : 'Transactions');
    final rangeLabel = body['range_label']?.toString() ?? '';
    final rowCount = (body['row_count'] as num?)?.round() ?? 0;
    final glance = Map<String, dynamic>.from(body['glance'] as Map? ?? const {});
    final totalRevenue = (glance['total_revenue'] as num?) ?? body['total_revenue'] as num? ?? 0;
    final truncated = body['truncated'] == true;
    final showSite = body['show_site_column'] == true;
    final openOnly = body['open_only'] == true;
    final transactions = _transactions(body['transactions']);
    final scheme = Theme.of(context).colorScheme;

    final subtitle = _id
        ? '$rowCount transaksi · Omzet ${moneyFmtIdr(totalRevenue.toDouble())}'
        : '$rowCount transactions · Revenue ${moneyFmtIdr(totalRevenue.toDouble())}';

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
              if (rangeLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    rangeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              for (final tx in transactions) _TxRow(tx: tx, showSite: showSite, openOnly: openOnly, id: _id),
              if (truncated)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _id ? 'Menampilkan ${transactions.length} dari $rowCount.' : 'Showing ${transactions.length} of $rowCount.',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_TxRowData> _transactions(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _TxRowData(
        time: m['time']?.toString() ?? '',
        label: m['label']?.toString() ?? '',
        total: (m['total'] as num?)?.toInt() ?? 0,
        status: m['status']?.toString(),
        unpaid: (m['unpaid'] as num?)?.toInt(),
        siteName: m['site_name']?.toString(),
      );
    }).toList();
  }
}

class _TxRowData {
  const _TxRowData({
    required this.time,
    required this.label,
    required this.total,
    this.status,
    this.unpaid,
    this.siteName,
  });

  final String time;
  final String label;
  final int total;
  final String? status;
  final int? unpaid;
  final String? siteName;
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.showSite, required this.openOnly, required this.id});

  final _TxRowData tx;
  final bool showSite;
  final bool openOnly;
  final bool id;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = moneyFmtIdr(tx.total.toDouble());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(tx.time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label, style: const TextStyle(fontSize: 13)),
                if (showSite && (tx.siteName ?? '').isNotEmpty)
                  Text(tx.siteName!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                if (tx.status != null && tx.status!.isNotEmpty)
                  Text(tx.status!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                if (openOnly && tx.unpaid != null && tx.unpaid! > 0)
                  Text(
                    id ? 'Sisa ${moneyFmtIdr(tx.unpaid!.toDouble())}' : 'Due ${moneyFmtIdr(tx.unpaid!.toDouble())}',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
