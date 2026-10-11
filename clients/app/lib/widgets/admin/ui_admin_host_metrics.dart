import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/admin/admin_stats_stream.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_network_row.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

class UiAdminNodeMetrics extends StatelessWidget {
  const UiAdminNodeMetrics({super.key, required this.stats, required this.node});

  final AdminStatsStream stats;
  final NodeStat node;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          UiAdminStatBar(
            label: 'CPU',
            detail: '${node.cpuCores} cores',
            pct: node.cpuPct.clamp(0, 100),
            dense: true,
          ),
          UiAdminStatBar(
            label: 'RAM',
            detail: adminFmtBytesPair(node.memUsedBytes, node.memTotalBytes),
            pct: adminPct(node.memUsedBytes, node.memTotalBytes),
            dense: true,
          ),
          if (node.swapTotalBytes > 0)
            UiAdminStatBar(
              label: 'Swap',
              detail: adminFmtBytesPair(node.swapUsedBytes, node.swapTotalBytes),
              pct: adminPct(node.swapUsedBytes, node.swapTotalBytes),
              dense: true,
            ),
          UiAdminNetworkRow(
            interfaceLabel: adminNodeNetLabel(node),
            inBps: node.netInBps,
            outBps: node.netOutBps,
            maxBps: stats.networkMaxBps(node.nodeName),
          ),
        ],
      );
}

class UiAdminPodMetrics extends StatelessWidget {
  const UiAdminPodMetrics({super.key, required this.stats, required this.pod});

  final AdminStatsStream stats;
  final PodStat pod;

  @override
  Widget build(BuildContext context) {
    final cpuMarker = adminPodRequestMarkerFrac(pod.cpuRequestCores, pod.cpuLimitCores);
    final memMarker = adminPodRequestMarkerFrac(
      pod.memRequestBytes.toInt().toDouble(),
      pod.memLimitBytes.toInt().toDouble(),
    );
    final cpuUnbounded = adminPodCpuUnbounded(pod.cpuLimitCores);
    final memUnbounded = adminPodMemUnbounded(pod.memLimitBytes);
    return Column(
      children: [
        UiAdminStatBar(
          label: 'CPU',
          detail: adminFmtCpuTriple(pod.cpuUsedCores, pod.cpuRequestCores, pod.cpuLimitCores),
          pct: cpuUnbounded ? 100 : pod.cpuPct.clamp(0, 100),
          dense: true,
          detailWidth: kAdminStatPodDetailWidth,
          requestMarkerFrac: cpuUnbounded ? null : cpuMarker,
          fillColor: cpuUnbounded ? adminBarIn : null,
          pctLabel: cpuUnbounded ? '\u2014' : null,
        ),
        UiAdminStatBar(
          label: 'RAM',
          detail: adminFmtBytesTriple(pod.memUsedBytes, pod.memRequestBytes, pod.memLimitBytes),
          pct: memUnbounded ? 100 : pod.memPct.clamp(0, 100),
          dense: true,
          detailWidth: kAdminStatPodDetailWidth,
          requestMarkerFrac: memUnbounded ? null : memMarker,
          fillColor: memUnbounded ? adminBarIn : null,
          pctLabel: memUnbounded ? '\u2014' : null,
        ),
        UiAdminNetworkRow(
          interfaceLabel: stats.nodeNetIface(pod.nodeName) ?? 'Network',
          inBps: pod.netInBps,
          outBps: pod.netOutBps,
          maxBps: stats.networkMaxBpsForPod(pod),
        ),
      ],
    );
  }
}
