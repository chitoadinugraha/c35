import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';

const configKey = 'app.release.c35.remote-windows';

Future<void> publishRemoteAgentVersion({required int version, required String versionName, required String hash, required int size, int min = 0}) async {
  if (version <= 0) throw StateError('Invalid remote agent version: $version');
  final h = hash.trim().toLowerCase();
  if (h.isEmpty) throw StateError('hash required for remote agent publish');
  if (size <= 0) throw StateError('Invalid remote agent zip size: $size');

  final configValue = jsonEncode({'version': version, 'versionName': versionName, 'min': min, 'hash': h, 'size': size});
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
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
        '''),
        parameters: {'key': configKey, 'value': configValue},
      );
    } finally {
      await conn.close();
    }
  });

  await runStep('Broadcast release over NATS', () async {
    final natsHost = deployEnv('NATS_HOST', '127.0.0.1');
    final natsPort = int.tryParse(deployEnv('NATS_PORT', '4222')) ?? 4222;
    try {
      final socket = await Socket.connect(natsHost, natsPort, timeout: const Duration(seconds: 3));
      final payload = jsonEncode({'platform': 'remote-windows', 'version': version, 'versionName': versionName, 'hash': h, 'size': size});
      final payloadBytes = utf8.encode(payload);
      socket.write('CONNECT {"verbose":false,"pedantic":false}\r\n');
      socket.write('PUB c35.release.remote-windows ${payloadBytes.length}\r\n');
      socket.add(payloadBytes);
      socket.write('\r\nPING\r\n');
      await socket.flush();
      await socket.close();
      stdout.writeln('✓ NATS broadcasted to c35.release.remote-windows ($version)');
    } catch (e) {
      stdout.writeln('ℹ NATS broadcast notice: $e (agents will still pick up update via periodic poll)');
    }
  });

  stdout.writeln('✓ GET /version/remote-windows → $version ($versionName)');
}
