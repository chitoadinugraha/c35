import 'dart:convert';

import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppRelease {
  const AppRelease({
    required this.version,
    this.versionName = '',
    this.min = 0,
    this.hash = '',
    this.size = 0,
    this.url = '',
    this.apkHash = '',
    this.apkSize = 0,
    this.apkUrl = '',
  });
  final int version;
  final String versionName;
  final int min;
  final String hash;
  final int size;
  final String url;
  final String apkHash;
  final int apkSize;
  final String apkUrl;

  String get label => 'v$version';
}

int appReleaseLocalVersion() => int.tryParse(csaiVersion.trim()) ?? 0;

AppRelease? appReleaseParse(Map<String, dynamic> json) {
  final version = _jsonInt(json['version']);
  if (version == null || version <= 0) return null;
  return AppRelease(
    version: version,
    versionName: '${json['versionName'] ?? ''}',
    min: _jsonInt(json['min']) ?? 0,
    hash: '${json['hash'] ?? ''}'.trim().toLowerCase(),
    size: _jsonInt(json['size']) ?? 0,
    url: '${json['url'] ?? ''}'.trim(),
    apkHash: '${json['apkHash'] ?? ''}'.trim().toLowerCase(),
    apkSize: _jsonInt(json['apkSize']) ?? 0,
    apkUrl: '${json['apkUrl'] ?? ''}'.trim(),
  );
}

int? _jsonInt(Object? v) => v is int ? v : v is num ? v.toInt() : int.tryParse('$v');

bool appReleaseNeedsUpdate({required int local, required AppRelease remote}) => remote.version > local;

bool appReleaseForceUpdate({required int local, required AppRelease remote}) => remote.min > 0 && local < remote.min;

Future<AppRelease?> appReleaseGet(String apiBase, {String platform = 'windows'}) async {
  final base = apiBase.replaceAll(RegExp(r'/+$'), '');
  final p = platform.trim().toLowerCase();
  if (p.isEmpty) return null;
  try {
    final res = await http.get(Uri.parse('$base/version/$p')).timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return const AppRelease(version: 0);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return appReleaseParse(json);
  } catch (_) {
    return null;
  }
}

class AppReleasePlatforms {
  const AppReleasePlatforms({required this.byPlatform});
  final Map<String, AppRelease> byPlatform;

  int? versionOf(String platform) => byPlatform[platform.trim().toLowerCase()]?.version;
}

AppReleasePlatforms? appReleasePlatformsParse(Map<String, dynamic> json) {
  final raw = json['platforms'];
  if (raw is! Map) return null;
  final out = <String, AppRelease>{};
  for (final entry in raw.entries) {
    final key = '${entry.key}'.trim().toLowerCase();
    if (key.isEmpty || entry.value is! Map) continue;
    final release = appReleaseParse(Map<String, dynamic>.from(entry.value as Map));
    if (release != null && release.version > 0) out[key] = release;
  }
  return out.isEmpty ? null : AppReleasePlatforms(byPlatform: out);
}

String appReleasePlatformForDevice() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'android';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.macOS:
      return 'windows';
    case TargetPlatform.linux:
      return 'windows';
    default:
      return 'web';
  }
}

Future<AppReleasePlatforms?> appReleasePlatformsGet(String apiBase) async {
  final base = apiBase.replaceAll(RegExp(r'/+$'), '');
  try {
    final res = await http.get(Uri.parse('$base/version')).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return appReleasePlatformsParse(json);
  } catch (_) {
    return null;
  }
}
