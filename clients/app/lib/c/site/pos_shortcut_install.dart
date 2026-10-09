import 'dart:io';

import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:alienai_c35/c/site/pos_shortcut_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

const _androidChannel = MethodChannel('id.alienai/pos_shortcut');

enum PosShortcutInstallResult { ok, unsupported, failed }

/// Pin POS launcher shortcut (Windows Desktop `.lnk`, Android home-screen pin).
Future<PosShortcutInstallResult> posShortcutInstall({
  required String siteIid,
  required String siteName,
  String sitePic = '',
}) async {
  final id = siteIid.trim();
  if (id.isEmpty) return PosShortcutInstallResult.failed;
  final label = posShortcutLabel(siteName);
  final uri = posAppSchemeUrl(id);
  if (kIsWeb) return PosShortcutInstallResult.unsupported;
  Uint8List? iconPng;
  try {
    iconPng = await posShortcutCompositeIconPng(sitePic: sitePic);
  } catch (e) {
    debugPrint('pos shortcut icon: $e');
  }
  if (Platform.isAndroid) {
    return _androidPin(id: id, label: label, uri: uri, iconPng: iconPng);
  }
  if (Platform.isWindows) {
    return _windowsDesktopLnk(siteName: siteName, uri: uri, iconPng: iconPng);
  }
  return PosShortcutInstallResult.unsupported;
}

Future<PosShortcutInstallResult> _androidPin({
  required String id,
  required String label,
  required String uri,
  Uint8List? iconPng,
}) async {
  try {
    final args = <String, Object>{
      'id': posShortcutId(id),
      'label': label,
      'uri': uri,
    };
    if (iconPng != null && iconPng.isNotEmpty) {
      args['iconPng'] = iconPng;
    }
    final res = await _androidChannel.invokeMethod<Map<Object?, Object?>>('pinPos', args);
    final ok = res?['ok'] == true;
    return ok ? PosShortcutInstallResult.ok : PosShortcutInstallResult.unsupported;
  } on PlatformException catch (e) {
    debugPrint('pos shortcut android: $e');
    return PosShortcutInstallResult.failed;
  } catch (e) {
    debugPrint('pos shortcut android: $e');
    return PosShortcutInstallResult.failed;
  }
}

Future<PosShortcutInstallResult> _windowsDesktopLnk({
  required String siteName,
  required String uri,
  Uint8List? iconPng,
}) async {
  try {
    final profile = Platform.environment['USERPROFILE'];
    if (profile == null || profile.isEmpty) return PosShortcutInstallResult.failed;
    final desktop = p.join(profile, 'Desktop');
    final stem = posShortcutFileStem(siteName);
    final lnkPath = p.join(desktop, '$stem.lnk');
    final icoPath = p.join(desktop, '$stem.ico');
    if (iconPng != null && iconPng.isNotEmpty) {
      await File(icoPath).writeAsBytes(posShortcutCompositeIconIco(iconPng), flush: true);
    }
    final exe = Platform.resolvedExecutable;
    final workDir = p.dirname(exe);
    final script = _psCreateShortcut(
      lnkPath: lnkPath,
      target: exe,
      arguments: uri,
      workingDir: workDir,
      iconPath: iconPng != null && iconPng.isNotEmpty ? icoPath : null,
    );
    final run = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      runInShell: false,
    );
    if (run.exitCode != 0) {
      debugPrint('pos shortcut ps: ${run.stderr}');
      return PosShortcutInstallResult.failed;
    }
    if (!File(lnkPath).existsSync()) return PosShortcutInstallResult.failed;
    return PosShortcutInstallResult.ok;
  } catch (e) {
    debugPrint('pos shortcut windows: $e');
    return PosShortcutInstallResult.failed;
  }
}

String _psSingleQuote(String s) => "'${s.replaceAll("'", "''")}'";

String _psCreateShortcut({
  required String lnkPath,
  required String target,
  required String arguments,
  required String workingDir,
  String? iconPath,
}) {
  final iconLine = iconPath == null || iconPath.isEmpty
      ? ''
      : '\$sc.IconLocation = ${_psSingleQuote(iconPath)}\n';
  return '''
\$sh = New-Object -ComObject WScript.Shell
\$sc = \$sh.CreateShortcut(${_psSingleQuote(lnkPath)})
\$sc.TargetPath = ${_psSingleQuote(target)}
\$sc.Arguments = ${_psSingleQuote(arguments)}
\$sc.WorkingDirectory = ${_psSingleQuote(workingDir)}
$iconLine\$sc.Save()
''';
}
