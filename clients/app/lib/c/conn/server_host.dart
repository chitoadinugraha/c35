import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const serverHostProductionUrl = 'https://api.alienai.id';
const serverHostLocalUrl = 'http://127.0.0.1:8080';
const serverHostTailscaleUrl = 'http://100.100.1.10:8080';
const serverHostCompile = String.fromEnvironment('C35_SERVER', defaultValue: '');
const _serverHostPrefKey = '${C35AppId.id}.server_host';

const serverHostOptions = [serverHostProductionUrl, serverHostLocalUrl, serverHostTailscaleUrl];

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
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.isEmpty) return normalized;
  if (uri.host.toLowerCase() != 'ai.alienai.id') return normalized;
  return serverHostNormalize(uri.replace(host: 'alienai.id').toString());
}

void serverHostApply(String base) => C35Config.authApiBase = serverHostCanonicalize(base);

Future<String> serverHostActiveBase() async {
  String base;
  if (serverHostPickerVisible()) {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_serverHostPrefKey);
    if (stored != null && stored.isNotEmpty) {
      base = serverHostCanonicalize(stored);
    } else if (serverHostCompile.isNotEmpty) {
      base = serverHostCanonicalize(serverHostCompile);
    } else {
      base = kDebugMode ? serverHostLocalUrl : serverHostProductionUrl;
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

Future<void> serverHostWaitReady({Duration maxWait = const Duration(seconds: 30)}) async {
  final base = C35Config.authApiBase;
  final deadline = DateTime.now().add(maxWait);
  while (DateTime.now().isBefore(deadline)) {
    try {
      final res = await http.get(Uri.parse('$base/livez')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) return;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  lError('Local server not ready at $base after ${maxWait.inSeconds}s');
}

Future<void> serverHostInit() async {
  serverHostApply(await serverHostActiveBase());
  if (kDebugMode && serverHostNormalize(C35Config.authApiBase) == serverHostLocalUrl) {
    await serverHostWaitReady();
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
