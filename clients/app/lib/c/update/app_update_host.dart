import 'package:alienai_c35/c/log.dart';
import 'dart:async';

import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_android.dart';
import 'package:alienai_c35/c/update/app_update_apk_ota.dart';
import 'package:alienai_c35/c/update/app_update_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppUpdateHost extends StatefulWidget {
  const AppUpdateHost({super.key, required this.child, required this.appReady});
  final Widget child;
  final bool appReady;

  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost> with WidgetsBindingObserver {
  var _checking = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.android) return;
    WidgetsBinding.instance.addObserver(this);
    AppUpdateService.instance.registerAndroidCheck(_check);
    AppUpdateService.instance.registerAndroidInstall(appUpdateApkInstallStaged);
    AppUpdateService.instance.registerAutoUpdatePrompt(_androidIdleInstall);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(AppUpdateHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appReady && !oldWidget.appReady) {
      _scheduleCheck();
      AppUpdateService.instance.start();
    }
  }

  @override
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.removeObserver(this);
      AppUpdateService.instance.registerAndroidCheck(null);
      AppUpdateService.instance.registerAndroidInstall(null);
      AppUpdateService.instance.registerAutoUpdatePrompt(null);
      AppUpdateService.instance.dispose();
    }
    super.dispose();
  }

  void _androidIdleInstall(AppRelease release) {
    final ctx = c35NavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      AppUpdateService.instance.countdownDismissed();
      return;
    }
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Install update', style: TextStyle(color: Color(0xFFF4F4F5))),
        content: Text(
          'Update ${release.label} is ready. Install now?',
          style: const TextStyle(color: Color(0xFFA1A1AA), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppUpdateService.instance.postponeAutoUpdate();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              unawaited(appUpdateApkInstallStaged(release.version));
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
            child: const Text('Install'),
          ),
        ],
      ),
    ).then((_) => AppUpdateService.instance.countdownDismissed());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleCheck();
  }

  void _scheduleCheck() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (kDebugMode || !widget.appReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.instance.start();
      _check();
    });
  }

  Future<void> _check() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (kDebugMode || !widget.appReady || _checking) return;
    _checking = true;
    try {
      await appUpdateAndroidCheck(askToUpdate: ({required force, required apkSideload}) => _askToUpdate(force: force, apkSideload: apkSideload), askToRestart: _askToRestart);
    } catch (e, st) {
      lError(e);
      l(st);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _askToUpdate({required bool force, required bool apkSideload}) async {
    final ctx = c35NavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final body = force
        ? 'This version is no longer supported. Update to continue.'
        : apkSideload
            ? 'A new version is available. Download and install the update APK.'
            : 'A new version is available on Google Play.';
    return await showDialog<bool>(
          context: ctx,
          barrierDismissible: !force,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Text('Update available', style: TextStyle(color: Color(0xFFF4F4F5))),
            content: Text(body, style: const TextStyle(color: Color(0xFFA1A1AA), height: 1.45)),
            actions: [
              if (!force) TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Later')),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                child: const Text('Update'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _askToRestart() async {
    final ctx = c35NavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    return await showDialog<bool>(
          context: ctx,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Text('Update ready', style: TextStyle(color: Color(0xFFF4F4F5))),
            content: const Text('Restart to finish installing the update.', style: TextStyle(color: Color(0xFFA1A1AA), height: 1.45)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Later')),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                child: const Text('Restart'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
