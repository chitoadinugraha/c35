import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/material.dart';

class UiReportSummaryCard extends StatelessWidget {
  const UiReportSummaryCard({super.key, required this.body, this.locale = 'en-US'});

  final Map<String, dynamic> body;
  final String locale;

  bool get _id => locale.toLowerCase().startsWith('id');

  @override
  Widget build(BuildContext context) {
    final title = body['title']?.toString() ?? (_id ? 'Ringkasan' : 'Summary');
    final rangeLabel = body['range_label']?.toString() ?? '';
    final sites = _sites(body['sites']);
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
              if (rangeLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    rangeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 10),
              for (final site in sites) _SiteMetrics(site: site, id: _id),
            ],
          ),
        ),
      ),
    );
  }

  List<_SiteMetricsData> _sites(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final metricsRaw = m['metrics'];
      final metrics = <_Metric>[];
      if (metricsRaw is List) {
        for (final item in metricsRaw) {
          final row = Map<String, dynamic>.from(item as Map);
          metrics.add(_Metric(
            label: row['label']?.toString() ?? '',
            value: (row['value'] as num?)?.toInt() ?? 0,
            key: row['key']?.toString() ?? '',
          ));
        }
      }
      return _SiteMetricsData(
        siteName: m['site_name']?.toString() ?? '',
        metrics: metrics,
      );
    }).toList();
  }
}

class _SiteMetrics extends StatelessWidget {
  const _SiteMetrics({required this.site, required this.id});

  final _SiteMetricsData site;
  final bool id;

  @override
  Widget build(BuildContext context) {
    if (site.siteName.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(site.siteName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final m in site.metrics) _MetricRow(metric: m, id: id),
          const SizedBox(height: 8),
        ],
      );
    }
    return Column(
      children: [for (final m in site.metrics) _MetricRow(metric: m, id: id)],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric, required this.id});

  final _Metric metric;
  final bool id;

  @override
  Widget build(BuildContext context) {
    final isMoney = metric.key == 'revenue' || metric.key == 'profit';
    final valueText = isMoney ? moneyFmtIdr(metric.value.toDouble()) : '${metric.value}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric.label),
          Text(valueText, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SiteMetricsData {
  _SiteMetricsData({required this.siteName, required this.metrics});

  final String siteName;
  final List<_Metric> metrics;
}

class _Metric {
  _Metric({required this.label, required this.value, required this.key});

  final String label;
  final int value;
  final String key;
}
