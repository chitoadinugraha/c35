import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/admin/admin_stats_stream.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/pages/page_root_inst.dart';
import 'package:alienai_c35/pages/page_root_logs.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_stat_bar.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_volume_row.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _panel = Color(0xFF111114);
const _border = Color(0xFF27272A);
const _accent = Color(0xFF34D399);

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
          final node = _stats.primaryNode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (node != null) ...[
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
                const SizedBox(height: 8),
                for (final m in node.mounts)
                  UiAdminMountRow(
                    label: m.label.isNotEmpty ? m.label : m.mount,
                    usedBytes: m.usedBytes.toInt(),
                    totalBytes: m.totalBytes.toInt(),
                    readBps: m.readBps,
                    writeBps: m.writeBps,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Network  In ${adminFmtBps(node.netInBps)}  Out ${adminFmtBps(node.netOutBps)}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Waiting for node stats…', style: TextStyle(color: _muted, fontSize: 13))),
                ),
              if (_stats.volumes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Volumes', style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                  child: Column(children: _stats.volumes.map((v) => UiAdminVolumeRow(volume: v)).toList()),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _openLogs,
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: const Text('Logs'),
                      style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openInst,
                      icon: const Icon(Icons.tune_outlined, size: 18, color: _text),
                      label: const Text('Inst', style: TextStyle(color: _text)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: _border)),
                    ),
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
