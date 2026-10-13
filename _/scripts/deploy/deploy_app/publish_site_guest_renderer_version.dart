import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';

const configKey = 'site.guest_renderer_version';
const rustPath = 'servers/crates/mod_site/src/guest_renderer.rs';

SslMode ybSslMode() {
  final raw = deployEnv('YB_SSLMODE', 'disable').toLowerCase();
  return (raw == 'disable' || raw == 'false' || raw == '0' || raw == 'no') ? SslMode.disable : SslMode.require;
}

Future<Connection> openPg() async {
  final host = deployEnv('YB_HOST', 'yb-tservers.yugabyte.svc.cluster.local');
  final port = int.tryParse(deployEnv('YB_PORT', '5433')) ?? 5433;
  final database = deployEnv('YB_DATABASE', 'c35');
  final username = deployEnv('YB_USER', 'csa');
  final password = deployEnv('YB_PASSWORD', '');
  if (password.isEmpty) throw StateError('YB_PASSWORD required to publish guest renderer version');
  return Connection.open(
    Endpoint(host: host, port: port, database: database, username: username, password: password),
    settings: ConnectionSettings(sslMode: ybSslMode(), connectTimeout: const Duration(seconds: 15)),
  );
}

int readGuestRendererVersionFromRust() {
  final file = File('${repoRoot()}/$rustPath');
  if (!file.existsSync()) {
    throw StateError('Missing $rustPath');
  }
  final text = file.readAsStringSync();
  final match = RegExp(r'pub const GUEST_RENDERER_VERSION:\s*i32\s*=\s*(\d+)\s*;').firstMatch(text);
  if (match == null) {
    throw StateError('GUEST_RENDERER_VERSION not found in $rustPath');
  }
  final v = int.parse(match.group(1)!);
  if (v < 1) throw StateError('GUEST_RENDERER_VERSION must be >= 1');
  return v;
}

Future<void> main(List<String> args) async {
  deployLoadEnvLocal();
  final version = readGuestRendererVersionFromRust();
  await runStep('Publish site guest renderer version $version to ai.config', () async {
    final conn = await openPg();
    try {
      final value = jsonEncode({'version': version});
      await conn.execute(
        Sql.named('''
          INSERT INTO ai.config (key, value, updated_at)
          VALUES (@key, @value::jsonb, now())
          ON CONFLICT (key) DO UPDATE SET
            value = EXCLUDED.value,
            updated_at = now()
        '''),
        parameters: {'key': configKey, 'value': value},
      );
    } finally {
      await conn.close();
    }
  });
  stdout.writeln('Cluster guest renderer version is now $version ($configKey).');
  stdout.writeln('Sites with site.config.guest_render_version < $version recompile on first guest visit.');
}
