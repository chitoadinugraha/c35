import 'dart:async';

import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const serverHostProductionUrl = 'https://api.alienai.id';
const serverHostLocalUrl = 'http://127.0.0.1:8080';
/// Android emulator alias for the host machine's loopback (see `adb reverse` in dev_app_android.ps1).
const serverHostAndroidEmulatorLocalUrl = 'http://10.0.2.2:8080';
const serverHostTailscaleUrl = 'http://100.100.1.10:8080';
const serverHostCompile = String.fromEnvironment('C35_SERVER', defaultValue: '');
const _serverHostPrefKey = C35AppId.serverHostKey;

const serverHostOptions = [
  serverHostProductionUrl,
  serverHostLocalUrl,
  serverHostAndroidEmulatorLocalUrl,
  serverHostTailscaleUrl,
];

bool serverHostLooksValid(String url) {
  final u = Uri.tryParse(serverHostNormalize(url));
  if (u == null || u.host.isEmpty) return false;
  return u.scheme == 'http' || u.scheme == 'https';
}

bool serverHostIsLocalDev(String url) {
  final u = Uri.tryParse(serverHostNormalize(url));
  if (u == null || u.scheme != 'http') return false;
  final host = u.host.toLowerCase();
  return host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2';
}

String serverHostDebugDefault() {
  // dev_app_android.ps1 runs `adb reverse` on USB devices; [serverHostResolveReachable] probes fallbacks.
  return serverHostLocalUrl;
}

Future<bool> serverHostProbe(String base) async {
  try {
    final res = await http.get(Uri.parse('${serverHostNormalize(base)}/livez')).timeout(const Duration(seconds: 2));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Debug Android/desktop: pick the first API base that answers `/livez`.
Future<String> serverHostResolveReachable(String preferred) async {
  if (!kDebugMode || kIsWeb) return serverHostCanonicalize(preferred);
  final compile = serverHostCompile.trim();
  final localFirst = compile.isNotEmpty || serverHostIsLocalDev(preferred);
  final candidates = localFirst
      ? <String>[
          preferred,
          serverHostLocalUrl,
          serverHostAndroidEmulatorLocalUrl,
          serverHostTailscaleUrl,
          serverHostProductionUrl,
        ]
      : <String>[
          preferred,
          serverHostProductionUrl,
          serverHostLocalUrl,
          serverHostAndroidEmulatorLocalUrl,
          serverHostTailscaleUrl,
        ];
  final seen = <String>{};
  for (final raw in candidates) {
    final url = serverHostCanonicalize(raw);
    final key = serverHostNormalize(url);
    if (seen.contains(key)) continue;
    seen.add(key);
    if (await serverHostProbe(url)) return url;
  }
  return serverHostCanonicalize(preferred);
}

final serverHostTick = ValueNotifier(0);

bool serverHostPickerVisible() => kDebugMode || Session.instance.isRoot || Session.instance.isTester;

String serverHostLabelFromUrl(String url) {
  try {
    final u = Uri.parse(url);
    if (u.host.isEmpty) return url;
    final port = u.hasPort ? u.port : null;
    if (port != null && port != 80 && port != 443) return '${u.host}:$port';
    return u.host;
  } catch (_) {
    return url;
  }
}

String serverHostNormalize(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

String serverHostCanonicalize(String url) {
  final normalized = serverHostNormalize(url);
  if (normalized.isEmpty) return serverHostProductionUrl;
  if (!serverHostLooksValid(normalized)) {
    return kDebugMode ? serverHostDebugDefault() : serverHostProductionUrl;
  }
  final uri = Uri.parse(normalized);
  if (uri.host.toLowerCase() != 'ai.alienai.id') return normalized;
  return serverHostNormalize(uri.replace(host: 'alienai.id').toString());
}

void serverHostApplyGuestOrigin(String apiBase) {
  C35Config.guestSiteOrigin = serverHostIsLocalDev(apiBase) ? serverHostLocalUrl : 'https://alienai.id';
}

void serverHostApply(String base) {
  final url = serverHostCanonicalize(base);
  C35Config.authApiBase = url;
  serverHostApplyGuestOrigin(url);
}

Future<String> serverHostActiveBase() async {
  String base;
  if (serverHostPickerVisible()) {
    final p = await SharedPreferences.getInstance();
    var stored = p.getString(_serverHostPrefKey);
    if (stored != null && stored.isNotEmpty && !serverHostLooksValid(stored)) {
      await p.remove(_serverHostPrefKey);
      stored = null;
    }
    final compile = serverHostCompile.trim();
    if (stored != null && stored.isNotEmpty) {
      base = serverHostCanonicalize(stored);
    } else if (compile.isNotEmpty && serverHostLooksValid(compile)) {
      base = serverHostCanonicalize(compile);
    } else {
      base = kDebugMode ? serverHostDebugDefault() : serverHostProductionUrl;
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        kDebugMode &&
        serverHostNormalize(base) == serverHostNormalize(serverHostAndroidEmulatorLocalUrl)) {
      base = serverHostLocalUrl;
    }
    if (stored != null && stored.isNotEmpty && base != serverHostNormalize(stored)) {
      await p.setString(_serverHostPrefKey, base);
    }
  } else if (serverHostCompile.isNotEmpty) {
    base = serverHostCanonicalize(serverHostCompile);
  } else {
    base = serverHostProductionUrl;
  }
  return base;
}

Future<void> serverHostWaitReady({Duration? maxWait}) async {
  final base = C35Config.authApiBase;
  // Local dev_server waits on remote YB/NATS (~30–45s cold start) plus cargo-watch rebuilds.
  final wait = maxWait ?? (serverHostIsLocalDev(base) ? const Duration(seconds: 90) : const Duration(seconds: 30));
  final deadline = DateTime.now().add(wait);
  while (DateTime.now().isBefore(deadline)) {
    try {
      final res = await http.get(Uri.parse('$base/livez')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) return;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  lError('Local server not ready at $base after ${wait.inSeconds}s');
}

Future<void> serverHostInit() async {
  final preferred = await serverHostActiveBase();
  final resolved = await serverHostResolveReachable(preferred);
  if (serverHostNormalize(resolved) != serverHostNormalize(preferred)) {
    l('server host: $preferred unreachable, using $resolved');
  } else {
    l('server host: $resolved');
  }
  serverHostApply(resolved);
  if (kDebugMode && serverHostIsLocalDev(C35Config.authApiBase)) {
    // Do not block app boot — local dev_server can take 30–90s (YB/NATS cold start).
    unawaited(serverHostWaitReady());
  }
}

Future<String> serverHostFooterLabel() async => serverHostLabelFromUrl(await serverHostActiveBase());

Future<String> serverHostSet(String base) async {
  final url = serverHostCanonicalize(base);
  if (!serverHostPickerVisible()) return await serverHostActiveBase();
  final p = await SharedPreferences.getInstance();
  await p.setString(_serverHostPrefKey, url);
  serverHostApply(url);
  serverHostTick.value++;
  return url;
}

Future<String> serverHostCycle() async {
  if (!serverHostPickerVisible()) return await serverHostActiveBase();
  final current = await serverHostActiveBase();
  final idx = serverHostOptions.indexWhere((o) => serverHostNormalize(o) == serverHostNormalize(current));
  final next = serverHostOptions[(idx < 0 ? 0 : idx + 1) % serverHostOptions.length];
  return serverHostSet(next);
}
