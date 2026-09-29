import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 'agent_version.dart';

Future<void> publishChromeExtensionVersion({
  required int version,
  required String versionName,
  required String hash,
  required int size,
  int min = 0,
}) async {
  if (version <= 0) throw StateError('Invalid chrome extension version: $version');
  final h = hash.trim().toLowerCase();
  if (h.isEmpty) throw StateError('hash required for chrome extension publish');
  if (size <= 0) throw StateError('Invalid chrome extension zip size: $size');

  await runStep('Publish chrome-extension version $version to ai.config', () async {
    final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
    final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
    final database = deployEnv('YB_DATABASE', 'c35');
    final username = deployEnv('YB_USER', 'csa');
    final password = deployEnv('YB_PASSWORD', '');
    if (password.isEmpty) throw StateError('YB_PASSWORD required to publish chrome extension release');
    final ssl = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
    final conn = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: username, password: password),
      settings: ConnectionSettings(sslMode: (ssl == 'disable' || ssl == 'false') ? SslMode.disable : SslMode.require),
    );
    try {
      final minPublish = await _chromeExtensionMinPublish(conn, min);
      final configValue = jsonEncode({
        'version': version,
        'versionName': versionName,
        'min': minPublish,
        'hash': h,
        'size': size,
      });
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
        '''),
        parameters: {'key': chromeExtensionConfigKey, 'value': configValue},
      );
    } finally {
      await conn.close();
    }
    stdout.writeln('✓ GET /version/chrome-extension → $version ($versionName)');
  });

  if (deployEnv('C35_SKIP_NATS_BROADCAST', '0') == '1') {
    stdout.writeln('SKIP NATS broadcast (C35_SKIP_NATS_BROADCAST=1)');
    return;
  }
  await runStep('Broadcast chrome-extension release over NATS (optional)', () async {
    final script = p.join(repoRoot(), '_', 'scripts', 'deploy', 'deploy_remote', 'nats_broadcast_chrome_extension_release.ps1');
    if (!File(script).existsSync()) {
      stdout.writeln('WARN: $script missing — skip NATS');
      return;
    }
    final proc = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script,
        '-Version',
        '$version',
        '-VersionName',
        versionName,
        '-Hash',
        hash,
        '-Size',
        '$size',
      ],
    );
    stdout.write(proc.stdout);
    stderr.write(proc.stderr);
    if (proc.exitCode != 0) {
      stdout.writeln('WARN: NATS broadcast failed (${proc.exitCode}) — OTA still available via GET /version/chrome-extension');
    }
  });
}

Future<int> _chromeExtensionMinPublish(Connection conn, int min) async {
  final base = min > 0 ? min : 1;
  final rows = await conn.execute(
    Sql.named(r"SELECT COALESCE((value->>'min')::bigint, 0) AS m FROM ai.config WHERE key = @key"),
    parameters: {'key': chromeExtensionConfigKey},
  );
  final existing = rows.isEmpty ? 0 : (rows.first[0] as int? ?? 0);
  return existing > base ? existing : base;
}
