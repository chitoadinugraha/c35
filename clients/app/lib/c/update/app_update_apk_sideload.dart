import 'dart:io';

import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_download.dart';
import 'package:alienai_c35/c/update/app_update_prefs.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

int _localBuild() => int.tryParse(csaiVersion.trim()) ?? 0;

Future<void> appUpdateAndroidSideloadCheck({
  required Future<bool> Function({required bool force, required bool apkSideload}) askToUpdate,
}) async {
  final base = await serverHostActiveBase();
  final remote = await appReleaseGet(base, platform: 'android');
  if (remote == null || remote.apkUrl.isEmpty) return;
  final local = _localBuild();
  if (!appReleaseNeedsUpdate(local: local, remote: remote)) return;
  final force = appReleaseForceUpdate(local: local, remote: remote);
  if (!force && await appUpdateDismissedVersion(remote.version)) return;
  final accepted = await askToUpdate(force: force, apkSideload: true);
  if (!accepted) {
    if (!force) await appUpdateDismissedVersionPut(remote.version);
    return;
  }
  await _apkDownloadInstall(remote);
}

Future<void> _apkDownloadInstall(AppRelease release) async {
  final ctx = c35NavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  await showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) => _ApkDownloadDialog(release: release),
  );
}

class _ApkDownloadDialog extends StatefulWidget {
  const _ApkDownloadDialog({required this.release});
  final AppRelease release;

  @override
  State<_ApkDownloadDialog> createState() => _ApkDownloadDialogState();
}

class _ApkDownloadDialogState extends State<_ApkDownloadDialog> {
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
      final path = '${dir.path}${Platform.pathSeparator}alienai-${widget.release.version}.apk';
      final ok = await appUpdateDownloadFile(
        url: widget.release.apkUrl,
        dest: path,
        expectSize: widget.release.apkSize,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!ok) throw StateError('Download failed');
      if (widget.release.apkHash.isNotEmpty && !appUpdateBlake3Match(path, widget.release.apkHash)) {
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
        title: const Text('Downloading update', style: TextStyle(color: Color(0xFFF4F4F5))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
