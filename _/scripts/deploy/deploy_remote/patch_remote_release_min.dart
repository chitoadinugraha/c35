// Patch prod remote-windows release min floor without bumping version (idempotent).
// Usage: dart run deploy_remote/patch_remote_release_min.dart

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';
import 'agent_version.dart';

Future<void> main() async {
  deployStart();
  deployLoadEnvLocal();
  final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: deployEnv('YB_DATABASE', 'c35'),
      username: deployEnv('YB_USER', 'csa'),
      password: deployEnv('YB_PASSWORD', ''),
    ),
    settings: ConnectionSettings(
      sslMode: deployEnv('YB_SSLMODE', 'disable').toLowerCase() == 'disable' ? SslMode.disable : SslMode.require,
    ),
  );
  try {
    final minPublish = await remoteReleaseMinPublish(conn, 0);
    final rows = await conn.execute(
      Sql.named(r"SELECT value FROM ai.config WHERE key = 'app.release.c35.remote-windows'"),
    );
    if (rows.isEmpty) throw StateError('remote-windows release row missing');
    final value = rows.first[0];
    Map<String, dynamic> doc;
    if (value is Map) {
      doc = Map<String, dynamic>.from(value);
    } else {
      doc = jsonDecode(value.toString()) as Map<String, dynamic>;
    }
    doc['min'] = minPublish;
    await conn.execute(
      Sql.named(r'''
        UPDATE ai.config SET value = @value::jsonb, updated_at = now()
        WHERE key = 'app.release.c35.remote-windows'
      '''),
      parameters: {'value': jsonEncode(doc)},
    );
    stdout.writeln('✓ remote-windows min=$minPublish (version=${doc['version']})');
  } finally {
    await conn.close();
  }
  deployDone(version: 'remote-windows min floor', detail: '≥$remoteAgentMinBuild');
}
