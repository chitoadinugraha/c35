import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';

final _versionRegex = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$');

String remotesDir(String root) => p.join(root, 'remotes');

String versionFilePath(String root) => p.join(remotesDir(root), 'VERSION');

(int build, String name) agentVersionRead(String root) {
  final line = File(versionFilePath(root)).readAsStringSync().trim().split('\n').first.trim();
  final m = _versionRegex.firstMatch(line);
  if (m == null) throw StateError('Invalid remotes/VERSION: $line (expected X.Y.Z+BUILD)');
  return (int.parse(m.group(2)!), m.group(1)!);
}

void agentVersionWrite(String root, String name, int build) {
  File(versionFilePath(root)).writeAsStringSync('$name+$build\n');
}

String agentVersionStampSync(String root) {
  final (build, _) = agentVersionRead(root);
  return '$build';
}

/// Minimum supported remote agent build; raise on breaking wire/session (see app-release-min.mdc).
const remoteAgentMinBuild = 2;

int remoteReleaseMinResolve({int min = 0}) {
  final env = int.tryParse(deployEnv('REMOTE_AGENT_MIN', '')) ?? 0;
  final floor = env > 0 ? env : remoteAgentMinBuild;
  final requested = min > 0 ? min : floor;
  return requested > floor ? requested : floor;
}

Future<int> remoteReleaseMinPublish(Connection conn, int min) async {
  const configKey = 'app.release.c35.remote-windows';
  final base = remoteReleaseMinResolve(min: min);
  final rows = await conn.execute(
    Sql.named(r"SELECT COALESCE((value->>'min')::bigint, 0) AS m FROM ai.config WHERE key = @key"),
    parameters: {'key': configKey},
  );
  final existing = rows.isEmpty ? 0 : (rows.first[0] as int? ?? 0);
  return base > existing ? base : existing;
}

void agentVersionBump(String root) {
  final (build, name) = agentVersionRead(root);
  final next = build + 1;
  final parts = name.split('.');
  final major = parts.isNotEmpty ? parts[0] : '1';
  final patch = parts.length > 2 ? parts[2] : '0';
  final nextName = '$major.$next.$patch';
  agentVersionWrite(root, nextName, next);
  stdout.writeln('✓ Remote agent version bumped to $nextName+$next');
}
