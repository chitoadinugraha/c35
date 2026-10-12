import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/widgets/admin/ui_admin_theme.dart';
import 'package:flutter/material.dart';

String _formatElapsed(Duration d) {
  final s = d.inSeconds;
  if (s < 60) return '${s}s';
  final m = d.inMinutes;
  final rem = s % 60;
  if (m < 60) return '${m}m ${rem}s';
  final h = d.inHours;
  return '${h}h ${m % 60}m';
}

Future<void> showAdminDiskCleanFlow({
  required BuildContext context,
  required AdminApi api,
  required String nodeName,
  required AdminDiskCleanKind kind,
  required String diskTitle,
  bool confirmBeforeStart = true,
  bool full = false,
}) async {
  if (confirmBeforeStart) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: adminPanel,
        title: Text('Clean $diskTitle?', style: const TextStyle(color: adminText, fontSize: 15)),
        content: Text(_confirmBody(kind), style: const TextStyle(color: adminMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clean')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }

  if (!context.mounted) return;
  unawaited(_runCleanWithProgress(
    context: context,
    api: api,
    nodeName: nodeName,
    kind: kind,
    full: full,
    force: false,
  ));
}

String _confirmBody(AdminDiskCleanKind kind) {
  switch (kind) {
    case AdminDiskCleanKind.ADMIN_DISK_CLEAN_BOOT:
      return 'Vacuum journal, trim old logs, stale temp files, apt cache, and unused container images on the boot disk.';
    case AdminDiskCleanKind.ADMIN_DISK_CLEAN_YUGABYTE:
      return 'Run Yugabyte log cleanup on this node. Compaction may add load but does not stop the database.';
    case AdminDiskCleanKind.ADMIN_DISK_CLEAN_BUILDKIT:
      return 'Prune buildkit cache (7 day retention). Next publish may be slower if cache was large.';
    default:
      return 'Run disk cleanup?';
  }
}

Future<void> _runCleanWithProgress({
  required BuildContext context,
  required AdminApi api,
  required String nodeName,
  required AdminDiskCleanKind kind,
  required bool full,
  required bool force,
}) async {
  final started = DateTime.now();
  final elapsedNotifier = ValueNotifier<Duration>(Duration.zero);
  Timer? ticker;

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        elapsedNotifier.value = DateTime.now().difference(started);
      });
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: adminPanel,
          content: ValueListenableBuilder<Duration>(
            valueListenable: elapsedNotifier,
            builder: (_, elapsed, __) => Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: adminHealthOk),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Cleaning up ${_formatElapsed(elapsed)}...',
                    style: const TextStyle(color: adminText, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  ResAdminDiskClean? res;
  Object? err;
  try {
    res = await api.adminDiskClean(
      nodeName: nodeName,
      kind: kind,
      full: full,
      force: force,
    );
  } catch (e) {
    err = e;
  } finally {
    ticker?.cancel();
    elapsedNotifier.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;

  if (err != null) {
    final msg = err.toString();
    if (msg.contains('buildkit_active')) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: adminPanel,
          title: const Text('Buildkit is running', style: TextStyle(color: adminText)),
          content: const Text(
            'A build may be in progress. Pruning can slow or fail in-flight builds. Continue anyway?',
            style: TextStyle(color: adminMuted, fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Prune anyway')),
          ],
        ),
      );
      if (retry == true && context.mounted) {
        await _runCleanWithProgress(
          context: context,
          api: api,
          nodeName: nodeName,
          kind: kind,
          full: full,
          force: true,
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    return;
  }

  final result = res;
  if (result == null) return;
  final ok = result.ok;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok ? result.message : (result.message.isNotEmpty ? result.message : 'Cleanup failed'))),
  );
  final steps = result.steps;
  if (steps.isNotEmpty && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: adminPanel,
        title: Text(ok ? 'Cleanup done' : 'Cleanup issues', style: const TextStyle(color: adminText)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${s.ok ? "[ok]" : "[!]"} ${s.name}${s.detail.isNotEmpty ? ": ${s.detail}" : ""}',
                      style: TextStyle(color: s.ok ? adminMuted : Colors.orangeAccent, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
