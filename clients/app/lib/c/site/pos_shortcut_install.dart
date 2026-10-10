import 'dart:io';

import 'package:alienai_c35/c/parts/windows_taskbar.dart';
import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:alienai_c35/c/site/pos_shortcut_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    return _windowsDesktopLnk(siteIid: id, label: label, siteName: siteName, uri: uri, iconPng: iconPng);
  }
  return PosShortcutInstallResult.unsupported;
}

/// Refreshes a pinned Android home-screen POS shortcut icon when the site avatar changes.
Future<void> posShortcutSyncPinnedIcon({
  required String siteIid,
  required String siteName,
  required String sitePic,
}) async {
  if (kIsWeb || !Platform.isAndroid) return;
  final id = siteIid.trim();
  if (id.isEmpty) return;
  Uint8List? iconPng;
  try {
    iconPng = await posShortcutCompositeIconPng(sitePic: sitePic);
  } catch (e) {
    debugPrint('pos shortcut icon sync: $e');
    return;
  }
  final iconPath = await _androidShortcutIconPath(posShortcutId(id), iconPng);
  if (iconPath == null) return;
  try {
    await _androidChannel.invokeMethod<Map<Object?, Object?>>('updatePosShortcut', <String, Object>{
      'id': posShortcutId(id),
      'label': posShortcutLabel(siteName),
      'uri': posAppSchemeUrl(id),
      'iconPath': iconPath,
    });
  } catch (e) {
    debugPrint('pos shortcut icon sync: $e');
  }
}

Future<String?> _androidShortcutIconPath(String shortcutId, Uint8List? iconPng) async {
  if (iconPng == null || iconPng.isEmpty) return null;
  try {
    final dir = await getTemporaryDirectory();
    final safe = shortcutId.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    final file = File(p.join(dir.path, 'pos_shortcut_$safe.png'));
    await file.writeAsBytes(iconPng, flush: true);
    return file.path;
  } catch (e) {
    debugPrint('pos shortcut icon file: $e');
    return null;
  }
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
    final iconPath = await _androidShortcutIconPath(posShortcutId(id), iconPng);
    if (iconPath != null) {
      args['iconPath'] = iconPath;
    } else if (iconPng != null && iconPng.isNotEmpty) {
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
  required String siteIid,
  required String label,
  required String siteName,
  required String uri,
  Uint8List? iconPng,
}) async {
  try {
    final profile = Platform.environment['USERPROFILE'];
    if (profile == null || profile.isEmpty) return PosShortcutInstallResult.failed;
    final desktop = p.join(profile, 'Desktop');
    await _windowsRemoveLegacyPosShortcut(desktop, siteName);
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
      description: label,
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
    final appId = windowsPosAppUserModelId(siteIid);
    final idScript = _psSetShortcutAppUserModelId(lnkPath: lnkPath, appId: appId);
    final idRun = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', idScript],
      runInShell: false,
    );
    if (idRun.exitCode != 0) {
      debugPrint('pos shortcut app id: ${idRun.stderr}');
    }
    return PosShortcutInstallResult.ok;
  } catch (e) {
    debugPrint('pos shortcut windows: $e');
    return PosShortcutInstallResult.failed;
  }
}

Future<void> _windowsRemoveLegacyPosShortcut(String desktopDir, String siteName) async {
  final legacyStem = posShortcutLegacyFileStem(siteName);
  final nextStem = posShortcutFileStem(siteName);
  if (legacyStem == nextStem) return;
  for (final ext in ['lnk', 'ico']) {
    final path = p.join(desktopDir, '$legacyStem.$ext');
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (e) {
      debugPrint('pos shortcut legacy cleanup $path: $e');
    }
  }
}

String _psSingleQuote(String s) => "'${s.replaceAll("'", "''")}'";

String _psSetShortcutAppUserModelId({required String lnkPath, required String appId}) {
  return '''
Add-Type -Language CSharp @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, Pack = 4)]
public struct PROPERTYKEY { public Guid fmtid; public uint pid; }
[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPropertyStore {
  void GetCount(out uint cProps);
  void GetAt(uint iProp, out PROPERTYKEY pkey);
  void GetValue(ref PROPERTYKEY key, out PropVariant pv);
  void SetValue(ref PROPERTYKEY key, ref PropVariant pv);
  void Commit();
}
[StructLayout(LayoutKind.Explicit, Size = 16)]
public struct PropVariant {
  [FieldOffset(0)] public ushort vt;
  [FieldOffset(8)] public IntPtr ptr;
}
public static class LnkAppId {
  static readonly PROPERTYKEY Pkey = new PROPERTYKEY { fmtid = new Guid("9F4C2855-9F79-4F39-A8D0-E1D42DE1D5F3"), pid = 5 };
  [DllImport("shell32.dll", CharSet = CharSet.Unicode)] static extern int SHGetPropertyStoreFromParsingName(string path, IntPtr rb, int flags, out IPropertyStore pps);
  public static void Set(string path, string appId) {
    IPropertyStore store;
    int hr = SHGetPropertyStoreFromParsingName(path, IntPtr.Zero, 2, out store);
    if (hr != 0) throw new System.ComponentModel.Win32Exception(hr);
    var pv = new PropVariant { vt = 31, ptr = Marshal.StringToCoTaskMemUni(appId) };
    try {
      store.SetValue(ref Pkey, ref pv);
      store.Commit();
    } finally { Marshal.FreeCoTaskMem(pv.ptr); }
  }
}
"@
[LnkAppId]::Set(${_psSingleQuote(lnkPath)}, ${_psSingleQuote(appId)})
''';
}

String _psCreateShortcut({
  required String lnkPath,
  required String target,
  required String arguments,
  required String workingDir,
  String? description,
  String? iconPath,
}) {
  final iconLine = iconPath == null || iconPath.isEmpty
      ? ''
      : '\$sc.IconLocation = ${_psSingleQuote(iconPath)}\n';
  final descLine = description == null || description.isEmpty
      ? ''
      : '\$sc.Description = ${_psSingleQuote(description)}\n';
  return '''
\$sh = New-Object -ComObject WScript.Shell
\$sc = \$sh.CreateShortcut(${_psSingleQuote(lnkPath)})
\$sc.TargetPath = ${_psSingleQuote(target)}
\$sc.Arguments = ${_psSingleQuote(arguments)}
\$sc.WorkingDirectory = ${_psSingleQuote(workingDir)}
$descLine$iconLine\$sc.Save()
''';
}
