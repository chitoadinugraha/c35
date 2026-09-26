import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/admin/admin_stats_stream.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/pages/page_root_inst.dart';
import 'package:alienai_c35/pages/page_root_logs.dart';
import 'package:alienai_c35/pages/page_root_objects.dart';
import 'package:alienai_c35/pages/page_root_pnl.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_action_tile.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_network_row.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_node_card.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_storage_row.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_volume_row.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

class PageRootConsole extends StatefulWidget {
  const PageRootConsole({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootConsole> createState() => _PageRootConsoleState();
}

class _PageRootConsoleState extends State<PageRootConsole> {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  late final AdminStatsStream _stats = AdminStatsStream(_api);
  Map<String, ({double cpuMax, int memUsedMax})> _peaks24h = const {};
  bool _peaksLoading = true;

  @override
  void initState() {
    super.initState();
    if (!Session.instance.isRoot) return;
    unawaited(_stats.start());
    unawaited(_loadPeaks24h());
  }

  Future<void> _loadPeaks24h() async {
    final untilMs = Int64(DateTime.now().millisecondsSinceEpoch);
    final sinceMs = untilMs - Int64(86400000);
    try {
      final res = await _api.adminOpsPeaks(sinceMs: sinceMs, untilMs: untilMs, entityType: 'node');
      if (!mounted) return;
      setState(() {
        _peaks24h = _nodePeaksFromRows(res.rows);
        _peaksLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _peaksLoading = false);
    }
  }

  Map<String, ({double cpuMax, int memUsedMax})> _nodePeaksFromRows(List<OpsMetric1mRow> rows) {
    final out = <String, ({double cpuMax, int memUsedMax})>{};
    for (final r in rows) {
      if (r.entityType != 'node') continue;
      final node = r.nodeName.isNotEmpty ? r.nodeName : r.entityId;
      if (node.isEmpty) continue;
      final prev = out[node];
      final cpu = r.hasCpuMax() ? r.cpuMax : 0.0;
      final mem = r.hasMemUsedMax() ? r.memUsedMax.toInt() : 0;
      out[node] = (
        cpuMax: prev == null ? cpu : (cpu > prev.cpuMax ? cpu : prev.cpuMax),
        memUsedMax: prev == null ? mem : (mem > prev.memUsedMax ? mem : prev.memUsedMax),
      );
    }
    return out;
  }

  @override
  void dispose() {
    _stats.dispose();
    super.dispose();
  }

  void _openLogs() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootLogs(chatConn: widget.chatConn)));

  void _openInst() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootInst(chatConn: widget.chatConn)));

  void _openObjects() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootObjects(chatConn: widget.chatConn)));

  void _openPnl() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootPnl(chatConn: widget.chatConn)));

  DiskDeviceStat? _bootStorage(NodeStat node) {
    final storages = _stats.storagesFor(node);
    if (storages.isEmpty) return null;
    for (final d in storages) {
      if (d.isBoot) return d;
    }
    return storages.first;
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.instance.isRoot) {
      return UiPage(
        title: 'Admin',
        onBack: () => Navigator.pop(context),
        body: const Center(child: Text('Root access required', style: TextStyle(color: adminMuted))),
      );
    }
    return UiPage(
      title: 'Root console',
      onBack: () => Navigator.pop(context),
      body: ListenableBuilder(
        listenable: _stats,
        builder: (context, _) {
          final nodes = _stats.nodes;
          final selected = _stats.selectedNode;
          final multiNode = nodes.length > 1;
          final volumes = selected != null ? _stats.volumesForNode(selected.nodeName) : const <VolumeStat>[];

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: adminDashboardMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (nodes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Waiting for node stats…', style: TextStyle(color: adminMuted, fontSize: 13))),
                    )
                  else if (multiNode)
                    for (final node in nodes) ...[
                      Builder(
                        builder: (context) {
                          final boot = _bootStorage(node);
                          return UiAdminNodeCard(
                            nodeName: node.nodeName,
                            cpuPct: node.cpuPct,
                            cpuCores: node.cpuCores,
                            memUsed: node.memUsedBytes,
                            memTotal: node.memTotalBytes,
                            storagePct: boot == null ? null : adminPct(boot.usedBytes, boot.totalBytes),
                            storageLabel: boot?.device.isNotEmpty == true ? boot!.device : 'sda',
                            tsMs: node.tsMs,
                            selected: selected?.nodeName == node.nodeName,
                            expanded: selected?.nodeName == node.nodeName,
                            onTap: () => _stats.selectNode(node.nodeName),
                            expandedBody: _NodeStatsBody(stats: _stats, node: node, embedded: true),
                          );
                        },
                      ),
                    ]
                  else if (selected != null)
                    UiAdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NodeHeader(node: selected),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: adminBorder),
                          const SizedBox(height: 10),
                          _NodeStatsBody(stats: _stats, node: selected),
                        ],
                      ),
                    ),
                  if (volumes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const UiAdminSectionTitle('Volumes'),
                    UiAdminPanel(
                      child: Column(
                        children: volumes.map((v) => UiAdminVolumeRow(volume: v, showNode: multiNode)).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const UiAdminSectionTitle('24h peaks'),
                  UiAdminPanel(
                    child: _peaksLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Loading rollup peaks…', style: TextStyle(color: adminMuted, fontSize: 12)),
                          )
                        : _peaks24h.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No 1m rollup data yet', style: TextStyle(color: adminMuted, fontSize: 12)),
                              )
                            : Column(
                                children: [
                                  for (final e in _peaks24h.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(e.key, style: const TextStyle(color: adminText, fontSize: 13, fontWeight: FontWeight.w500)),
                                          ),
                                          Text(
                                            'CPU ${e.value.cpuMax.toStringAsFixed(0)}%',
                                            style: const TextStyle(color: adminMuted, fontSize: 12),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'RAM ${adminFmtBytes(Int64(e.value.memUsedMax))}',
                                            style: const TextStyle(color: adminMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 18),
                  const UiAdminSectionTitle('Quick actions'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      UiAdminActionTile(
                        icon: Icons.article_outlined,
                        title: 'Logs',
                        subtitle: 'ai.log tail',
                        primary: true,
                        compact: true,
                        onTap: _openLogs,
                      ),
                      UiAdminActionTile(
                        icon: Icons.tune_outlined,
                        title: 'Inst',
                        subtitle: 'prompt steering',
                        compact: true,
                        onTap: _openInst,
                      ),
                      UiAdminActionTile(
                        icon: Icons.category_outlined,
                        title: 'Objects',
                        subtitle: 'aliases & taxonomy',
                        compact: true,
                        onTap: _openObjects,
                      ),
                      UiAdminActionTile(
                        icon: Icons.insights_outlined,
                        title: 'P&L',
                        subtitle: 'revenue & COGS',
                        compact: true,
                        onTap: _openPnl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NodeHeader extends StatelessWidget {
  const _NodeHeader({required this.node});

  final NodeStat node;

  bool get _healthOk {
    final ts = node.tsMs.toInt();
    if (ts <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < 60000;
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _healthOk ? adminHealthOk : adminHealthStale),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node.nodeName.isNotEmpty ? node.nodeName : 'Node',
              style: const TextStyle(color: adminText, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (node.cpuCores > 0) Text('${node.cpuCores} cores', style: const TextStyle(color: adminMuted, fontSize: 11)),
        ],
      );
}

class _NodeStatsBody extends StatelessWidget {
  const _NodeStatsBody({required this.stats, required this.node, this.embedded = false});

  final AdminStatsStream stats;
  final NodeStat node;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final storages = stats.storagesFor(node);
    final hostSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UiAdminSectionTitle('Host'),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final cpu = UiAdminStatBar(
              label: 'CPU',
              detail: '${node.cpuCores} cores',
              pct: node.cpuPct.clamp(0, 100),
              dense: true,
            );
            final mem = UiAdminStatBar(
              label: 'Memory',
              detail: '${adminFmtBytes(node.memUsedBytes)} / ${adminFmtBytes(node.memTotalBytes)}',
              pct: adminPct(node.memUsedBytes, node.memTotalBytes),
              dense: true,
            );
            if (!wide) {
              return Column(children: [cpu, mem]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cpu),
                const SizedBox(width: 16),
                Expanded(child: mem),
              ],
            );
          },
        ),
        if (node.swapTotalBytes > 0)
          UiAdminStatBar(
            label: 'Swap',
            detail: '${adminFmtBytes(node.swapUsedBytes)} / ${adminFmtBytes(node.swapTotalBytes)}',
            pct: adminPct(node.swapUsedBytes, node.swapTotalBytes),
            warnPct: 50,
            critPct: 80,
            dense: true,
          ),
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 2),
          child: Text('Network', style: TextStyle(color: adminMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        UiAdminNetworkRow(
          inBps: node.netInBps,
          outBps: node.netOutBps,
          maxBps: stats.networkMaxBps(node.nodeName),
        ),
      ],
    );

    final devicesSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UiAdminSectionTitle('Block devices'),
        if (storages.isEmpty)
          const Text('No block devices reported', style: TextStyle(color: adminMuted, fontSize: 12))
        else
          for (final d in storages)
            UiAdminStorageRow(
              device: d.device,
              label: d.label,
              usedBytes: d.usedBytes.toInt(),
              totalBytes: d.totalBytes.toInt(),
              readBps: d.readBps,
              writeBps: d.writeBps,
              isBoot: d.isBoot,
            ),
      ],
    );

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hostSection,
          const SizedBox(height: 8),
          const Divider(height: 1, color: adminBorder),
          const SizedBox(height: 8),
          devicesSection,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hostSection,
        const SizedBox(height: 12),
        const Divider(height: 1, color: adminBorder),
        const SizedBox(height: 4),
        devicesSection,
      ],
    );
  }
}
