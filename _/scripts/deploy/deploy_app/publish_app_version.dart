import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 'update_version.dart';

const androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=id.alienai.agent';
const webAppUrl = 'https://alienai.id/app/';
const configKeyPrefix = 'app.release.c35.';

SslMode _ybSslMode() {
  final raw = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
  return (raw == 'disable' || raw == 'false' || raw == '0' || raw == 'no') ? SslMode.disable : SslMode.require;
}

Future<Connection> _openPg() async {
  final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final database = deployEnv('YB_DATABASE', 'c35');
  final username = deployEnv('YB_USER', 'csa');
  final password = deployEnv('YB_PASSWORD', '');
  if (password.isEmpty) throw StateError('YB_PASSWORD required to publish app release');
  return Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: ConnectionSettings(sslMode: _ybSslMode(), connectTimeout: const Duration(seconds: 15)),
  );
}

Future<void> publishPlatformAppVersion({
  required String platform,
  required int version,
  required String storeUrl,
  String apkHash = '',
  int apkSize = 0,
}) async {
  if (version <= 0) throw StateError('Invalid version for version publish: $version');
  final p = platform.trim();
  if (p.isEmpty) throw StateError('platform required');
  final (major, _) = versionReadPubspec(repoRoot());
  final versionName = '$major.$version.0';
  final configKey = '$configKeyPrefix$p';
  final config = <String, Object>{
    'version': version,
    'versionName': versionName,
    'min': 0,
    'url': storeUrl.trim(),
  };
  final apk = apkHash.trim().toLowerCase();
  if (apk.isNotEmpty && apkSize > 0) {
    config['apkHash'] = apk;
    config['apkSize'] = apkSize;
  }
  final configValue = jsonEncode(config);
  await runStep('Publish $p version $version to ai.config', () async {
    final conn = await _openPg();
    try {
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET
            value = EXCLUDED.value,
            updated_at = now()
        '''),
        parameters: {'key': configKey, 'value': configValue},
      );
    } finally {
      await conn.close();
    }
  });
  stdout.writeln('✓ GET /version $p → $version ($versionName)');
}

Future<void> publishWindowsAppVersion({required int version, required String hash, required int size, int min = 0}) async {
  if (deployEnv('PLATFORM_APP_VERSION_PUBLISH', '1') == '0') {
    stdout.writeln('[skip] PLATFORM_APP_VERSION_PUBLISH=0 — not publishing /version');
    return;
  }
  final h = hash.trim().toLowerCase();
  if (h.isEmpty) throw StateError('hash required for Windows version publish');
  if (size <= 0) throw StateError('Invalid size for Windows version publish: $size');
  try {
    await publishPlatformAppVersionWindows(version: version, hash: h, size: size, min: min);
  } on StateError catch (e) {
    if (e.message.contains('YB_PASSWORD')) {
      stdout.writeln('[skip] ${e.message}');
      return;
    }
    rethrow;
  }
}

Future<void> publishPlatformAppVersionWindows({required int version, required String hash, required int size, int min = 0}) async {
  if (version <= 0) throw StateError('Invalid version for version publish: $version');
  final (major, _) = versionReadPubspec(repoRoot());
  final versionName = '$major.$version.0';
  final configKey = '${configKeyPrefix}windows';
  final configValue = jsonEncode({'version': version, 'versionName': versionName, 'min': min, 'hash': hash, 'size': size});
  await runStep('Publish windows version $version to ai.config', () async {
    final conn = await _openPg();
    try {
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET
            value = EXCLUDED.value,
            updated_at = now()
        '''),
        parameters: {'key': configKey, 'value': configValue},
      );
    } finally {
      await conn.close();
    }
  });
  stdout.writeln('✓ GET /version windows → $version ($versionName)');
}

Future<void> publishWebAppVersion(int versionCode) => publishPlatformAppVersion(
  platform: 'web',
  version: versionCode,
  storeUrl: webAppUrl,
);

Future<void> publishAppReleaseProd({
  required int version,
  String apkHash = '',
  int apkSize = 0,
  String windowsHash = '',
  int windowsSize = 0,
  bool includeWeb = false,
}) async {
  await publishAndroidAppVersion(version, apkHash: apkHash, apkSize: apkSize);
  if (windowsHash.isNotEmpty && windowsSize > 0) {
    await publishWindowsAppVersion(version: version, hash: windowsHash, size: windowsSize);
  }
  if (includeWeb) await publishWebAppVersion(version);
}

Future<void> publishAndroidAppVersion(int versionCode, {String apkHash = '', int apkSize = 0}) async {
  if (deployEnv('PLATFORM_APP_VERSION_PUBLISH', '1') == '0') {
    stdout.writeln('[skip] PLATFORM_APP_VERSION_PUBLISH=0 — not publishing /version');
    return;
  }
  try {
    await publishPlatformAppVersion(platform: 'android', version: versionCode, storeUrl: androidPlayStoreUrl, apkHash: apkHash, apkSize: apkSize);
  } on StateError catch (e) {
    if (e.message.contains('YB_PASSWORD')) {
      stdout.writeln('[skip] ${e.message}');
      return;
    }
    rethrow;
  }
}
