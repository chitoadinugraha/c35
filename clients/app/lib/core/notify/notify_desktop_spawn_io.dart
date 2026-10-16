import 'dart:io';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/update/app_update_paths.dart';
import 'package:flutter/foundation.dart';

/// Start `alienai_notify.exe` beside `alienai.exe` if it is not already listening.
Future<void> ensureNotifyDesktopHelperRunning() async {
  if (kIsWeb || !Platform.isWindows) return;
  final dir = appInstallDir();
  final exe = File('$dir${Platform.pathSeparator}alienai_notify.exe');
  if (!exe.existsSync()) return;
  try {
    final probe = await Socket.connect('127.0.0.1', 19831, timeout: const Duration(milliseconds: 400));
    await probe.close();
    return;
  } on Object {
    // Helper not listening — spawn detached copy next to the app.
  }
  try {
    await Process.start(
      exe.path,
      const [],
      mode: ProcessStartMode.detached,
      workingDirectory: dir,
    );
  } catch (e) {
    lError('notify helper spawn: $e');
  }
}
