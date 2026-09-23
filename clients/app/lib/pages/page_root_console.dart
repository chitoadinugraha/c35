import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/admin/admin_stats_stream.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/pages/page_root_inst.dart';
import 'package:alienai_c35/pages/page_root_logs.dart';
import 'package:alienai_c35/pages/page_root_objects.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_action_tile.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_network_row.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_node_card.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_storage_row.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_volume_row.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _panel = Color(0xFF111114);
const _border = Color(0xFF27272A);

class PageRootConsole extends StatefulWidget {
  const PageRootConsole({super.key, required this.chatConn});

  final ChatConn chatConn;

  @override
  State<PageRootConsole> createState() => _PageRootConsoleState();
}

class _PageRootConsoleState extends State<PageRootConsole> {
  late final AdminApi _api = AdminApi.chat(widget.chatConn);
  late final AdminStatsStream _stats = AdminStatsStream(_api);

  @override
  void initState() {
    super.initState();
    if (!Session.instance.isRoot) return;
    unawaited(_stats.start());
  }

  @override
  void dispose() {
    _stats.dispose();
    super.dispose();
  }

  void _openLogs() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootLogs(chatConn: widget.chatConn)));

  void _openInst() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootInst(chatConn: widget.chatConn)));

  void _openObjects() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootObjects(chatConn: widget.chatConn)));

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
        body: const Center(child: Text('Root access required', style: TextStyle(color: _muted))),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (nodes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Waiting for node stats…', style: TextStyle(color: _muted, fontSize: 13))),
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
                        expandedBody: _NodeStatsBody(stats: _stats, node: node),
                      );
                    },
                  ),
                ]
              else if (selected != null)
                _NodeStatsBody(stats: _stats, node: selected),
              if (volumes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Volumes', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                  child: Column(
                    children: volumes.map((v) => UiAdminVolumeRow(volume: v, showNode: multiNode)).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  UiAdminActionTile(
                    icon: Icons.article_outlined,
                    title: 'Logs',
                    subtitle: 'ai.log tail',
                    primary: true,
                    onTap: _openLogs,
                  ),
                  UiAdminActionTile(
                    icon: Icons.tune_outlined,
                    title: 'Inst',
                    subtitle: 'prompt steering',
                    onTap: _openInst,
                  ),
                  UiAdminActionTile(
                    icon: Icons.category_outlined,
                    title: 'Objects',
                    subtitle: 'aliases & taxonomy',
                    onTap: _openObjects,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NodeStatsBody extends StatelessWidget {
  const _NodeStatsBody({required this.stats, required this.node});

  final AdminStatsStream stats;
  final NodeStat node;

  @override
  Widget build(BuildContext context) {
    final storages = stats.storagesFor(node);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiAdminStatBar(
          label: 'CPU',
          detail: '${node.cpuCores} cores',
          pct: node.cpuPct.clamp(0, 100),
        ),
        UiAdminStatBar(
          label: 'Memory',
          detail: '${adminFmtBytes(node.memUsedBytes)} / ${adminFmtBytes(node.memTotalBytes)}',
          pct: adminPct(node.memUsedBytes, node.memTotalBytes),
        ),
        UiAdminNetworkRow(
          inBps: node.netInBps,
          outBps: node.netOutBps,
          maxBps: stats.networkMaxBps(node.nodeName),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 4),
          child: Text('Storages', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
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
  }
}
