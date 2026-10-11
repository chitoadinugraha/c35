import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminPlatformUserMetricsTable extends StatelessWidget {
  const UiAdminPlatformUserMetricsTable({
    super.key,
    required this.metrics,
    this.totalUsers,
  });

  final ResAdminPlatformUserMetrics metrics;
  final int? totalUsers;

  @override
  Widget build(BuildContext context) {
    final total = totalUsers ?? metrics.totalUsers.toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$total registered',
              style: const TextStyle(color: adminMuted, fontSize: 12),
            ),
          ),
        const _HeaderRow(),
        const Divider(height: 1, color: adminBorder),
        _MetricRow(label: 'Users', counts: _counts(metrics.users)),
        _MetricRow(label: 'Active users', counts: _counts(metrics.activeUsers)),
        _MetricRow(label: 'Paid users', counts: _counts(metrics.paidUsers)),
      ],
    );
  }

  static PlatformUserMetricsWindowCounts _counts(PlatformUserMetricsWindowCounts counts) => counts;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(child: SizedBox.shrink()),
          SizedBox(width: 52, child: Text('24h', textAlign: TextAlign.end, style: style)),
          SizedBox(width: 52, child: Text('7d', textAlign: TextAlign.end, style: style)),
          SizedBox(width: 52, child: Text('30d', textAlign: TextAlign.end, style: style)),
          SizedBox(width: 52, child: Text('1y', textAlign: TextAlign.end, style: style)),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.counts});

  final String label;
  final PlatformUserMetricsWindowCounts counts;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w500);
    const valueStyle = TextStyle(color: adminText, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          SizedBox(width: 52, child: Text('${counts.h24}', textAlign: TextAlign.end, style: valueStyle)),
          SizedBox(width: 52, child: Text('${counts.d7}', textAlign: TextAlign.end, style: valueStyle)),
          SizedBox(width: 52, child: Text('${counts.d30}', textAlign: TextAlign.end, style: valueStyle)),
          SizedBox(width: 52, child: Text('${counts.y1}', textAlign: TextAlign.end, style: valueStyle)),
        ],
      ),
    );
  }
}
