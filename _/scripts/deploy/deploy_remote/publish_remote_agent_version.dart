import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 'agent_version.dart';

const configKey = 'app.release.c35.remote-windows';

Future<void> publishRemoteAgentVersion({
  required int version,
  required String versionName,
  required String hash,
  required int size,
  required String setupHash,
  required int setupSize,
  int min = 0,
}) async {
  if (version <= 0) throw StateError('Invalid remote agent version: $version');
  final h = hash.trim().toLowerCase();
  if (h.isEmpty) throw StateError('hash required for remote agent publish');
  if (size <= 0) throw StateError('Invalid remote agent zip size: $size');
  final setup = setupHash.trim().toLowerCase();
  if (setup.isEmpty) throw StateError('setupHash required for remote agent publish');
  if (setupSize <= 0) throw StateError('Invalid remote agent setup size: $setupSize');

  await runStep('Publish remote-windows version $version to ai.config', () async {
    final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
    final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
    final database = deployEnv('YB_DATABASE', 'c35');
    final username = deployEnv('YB_USER', 'csa');
    final password = deployEnv('YB_PASSWORD', '');
    if (password.isEmpty) throw StateError('YB_PASSWORD required to publish remote agent release');
    final ssl = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
    final conn = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: username, password: password),
      settings: ConnectionSettings(sslMode: (ssl == 'disable' || ssl == 'false') ? SslMode.disable : SslMode.require),
    );
    try {
      final minPublish = await remoteReleaseMinPublish(conn, min);
      final configValue = jsonEncode({
        'version': version,
        'versionName': versionName,
        'min': minPublish,
        'hash': h,
        'size': size,
        'setupHash': setup,
        'setupSize': setupSize,
      });
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
        '''),
        parameters: {'key': configKey, 'value': configValue},
      );
      stdout.writeln('✓ ai.config min=$minPublish (floor≥$remoteAgentMinBuild)');
    } finally {
      await conn.close();
    }
  });

  await runStep('Broadcast release over NATS', () async {
    final script = p.join(repoRoot(), '_', 'scripts', 'deploy', 'deploy_remote', 'nats_broadcast_remote_release.ps1');
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
        h,
        '-Size',
        '$size',
      ],
      runInShell: false,
    );
    stdout.write(proc.stdout);
    stderr.write(proc.stderr);
    if (proc.exitCode != 0) {
      stdout.writeln('ℹ NATS cluster broadcast failed (exit ${proc.exitCode}); agents still poll alienai.id');
    }
  });

  stdout.writeln('✓ GET /version/remote-windows → $version ($versionName)');
}
