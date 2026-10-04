import 'dart:io';

import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_download.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> remoteAgentAndroidInstall() async {
  final base = await serverHostActiveBase();
  final remote = await appReleaseGet(base, platform: 'remote-android');
  if (remote == null || remote.apkUrl.isEmpty) {
    throw StateError('Remote Android agent is not published yet');
  }
  final ctx = c35NavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  await showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => _RemoteApkDownloadDialog(release: remote),
  );
}

class _RemoteApkDownloadDialog extends StatefulWidget {
  const _RemoteApkDownloadDialog({required this.release});
  final AppRelease release;

  @override
  State<_RemoteApkDownloadDialog> createState() => _RemoteApkDownloadDialogState();
}

class _RemoteApkDownloadDialogState extends State<_RemoteApkDownloadDialog> {
  var _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}${Platform.pathSeparator}alienai-remote-${widget.release.version}.apk';
      final ok = await appUpdateDownloadFile(
        url: widget.release.apkUrl,
        dest: path,
        expectSize: widget.release.apkSize,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!ok) throw StateError('Download failed');
      final hash = widget.release.apkHash.isNotEmpty ? widget.release.apkHash : widget.release.hash;
      if (hash.isNotEmpty && !appUpdateBlake3Match(path, hash)) {
        try {
          File(path).deleteSync();
        } catch (_) {}
        throw StateError('APK verification failed');
      }
      final result = await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) throw StateError(result.message);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      lError(e);
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Install Remote Agent', style: TextStyle(color: Color(0xFFF4F4F5))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Downloads id.alienai.remote (separate app). After install, open it and pair from Devices.',
              style: TextStyle(color: Color(0xFFA1A1AA), height: 1.45),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFF87171), height: 1.45))
            else ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null, color: const Color(0xFF34D399)),
              const SizedBox(height: 12),
              Text(
                _progress < 1 ? '${(_progress * 100).round()}%' : 'Opening installer…',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFA1A1AA)),
              ),
            ],
          ],
        ),
        actions: [
          if (_error != null) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      );
}
