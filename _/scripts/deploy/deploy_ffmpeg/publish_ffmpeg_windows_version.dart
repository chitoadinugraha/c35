import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 'ffmpeg_version.dart';

Future<void> publishFfmpegWindowsVersion({
  required int version,
  required String versionName,
  required String hash,
  required int size,
  int minAgentBuild = 0,
  bool skipNats = false,
}) async {
  if (version <= 0) throw StateError('Invalid ffmpeg version: $version');
  final h = hash.trim().toLowerCase();
  if (h.isEmpty) throw StateError('hash required for ffmpeg publish');
  if (size <= 0) throw StateError('Invalid ffmpeg zip size: $size');

  await runStep('Publish ffmpeg-windows version $version to ai.config', () async {
    final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
    final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
    final database = deployEnv('YB_DATABASE', 'c35');
    final username = deployEnv('YB_USER', 'csa');
    final password = deployEnv('YB_PASSWORD', '');
    if (password.isEmpty) throw StateError('YB_PASSWORD required to publish ffmpeg release');
    final ssl = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
    final conn = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: username, password: password),
      settings: ConnectionSettings(sslMode: (ssl == 'disable' || ssl == 'false') ? SslMode.disable : SslMode.require),
    );
    try {
      final configValue = jsonEncode({
        'version': version,
        'versionName': versionName,
        'min': minAgentBuild,
        'hash': h,
        'size': size,
      });
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
        '''),
        parameters: {'key': ffmpegWindowsConfigKey, 'value': configValue},
      );
      stdout.writeln('ai.config $ffmpegWindowsConfigKey min=$minAgentBuild');
    } finally {
      await conn.close();
    }
  });

  if (!skipNats) {
    await runStep('Broadcast ffmpeg release over NATS', () async {
      final script = p.join(repoRoot(), '_', 'scripts', 'deploy', 'deploy_ffmpeg', 'nats_broadcast_ffmpeg_release.ps1');
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
        stdout.writeln('NATS cluster broadcast failed (exit ${proc.exitCode}); clients still poll /version/ffmpeg-windows');
      }
    });
  }

  stdout.writeln('GET /version/ffmpeg-windows -> $version ($versionName)');
}
