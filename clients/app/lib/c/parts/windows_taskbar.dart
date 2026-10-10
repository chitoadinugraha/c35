import 'dart:io';

import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:alienai_c35/c/site/pos_shortcut_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

/// Main Alien AI window (Home, dev server, debug `flutter run`). Not POS shortcuts.
const windowsMainAppUserModelId = 'id.alienai.main';

/// Per-site POS desktop shortcut / cold start with `id.alienai://pos/<iid>`.
String windowsPosAppUserModelId(String siteIid) => 'id.alienai.pos.${siteIid.trim()}';

/// Reads POS launch args passed on the Windows command line (POS `.lnk` or manual).
String? windowsPosSiteIidFromExecutableArguments(List<String> args) {
  for (final arg in args) {
    final uri = Uri.tryParse(arg);
    if (uri == null) continue;
    final id = posSiteIidFromUri(uri);
    if (id != null) return id;
  }
  return null;
}

bool windowsLaunchedForPosShortcut([List<String>? args]) {
  if (!Platform.isWindows) return false;
  return windowsPosSiteIidFromExecutableArguments(args ?? Platform.executableArguments) != null;
}

/// Bundled `.ico` next to the runner exe (absolute path for `window_manager` on Windows).
String? windowsBundledAppIconIcoPath() {
  if (!Platform.isWindows) return null;
  final path = p.join(
    File(Platform.resolvedExecutable).parent.path,
    'data',
    'flutter_assets',
    'assets',
    'icons',
    'app_icon.ico',
  );
  return File(path).existsSync() ? path : null;
}

/// Alien AI icon on the taskbar. Skipped for POS shortcut launches (site composite icon).
Future<void> windowsTaskbarApplyAppIcon() async {
  if (!Platform.isWindows || windowsLaunchedForPosShortcut()) return;
  final path = windowsBundledAppIconIcoPath();
  if (path == null) return;
  try {
    await windowManager.setIcon(path);
  } catch (e) {
    debugPrint('windows taskbar app icon: $e');
  }
}

/// Site + badge icon when opened via a POS shortcut / deep link only.
Future<void> windowsTaskbarApplyPosIcon({required String sitePic}) async {
  if (!Platform.isWindows || !windowsLaunchedForPosShortcut()) return;
  try {
    final png = await posShortcutCompositeIconPng(sitePic: sitePic);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'pos_taskbar_icon.ico'));
    await file.writeAsBytes(posShortcutCompositeIconIco(png), flush: true);
    await windowManager.setIcon(file.path);
  } catch (e) {
    debugPrint('windows taskbar pos icon: $e');
  }
}
