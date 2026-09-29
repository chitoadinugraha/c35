import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';

import '../deploy_lib.dart';

final _versionRegex = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$');

/// Windows desktop remote agent (`/version/remote-windows`, agent.exe).
enum RemoteAgentProduct { windows, browser }

String remotesDir(String root) => p.join(root, 'remotes');

String agentVersionFileName(RemoteAgentProduct product) => switch (product) {
      RemoteAgentProduct.windows => 'VERSION.windows',
      RemoteAgentProduct.browser => 'VERSION.browser',
    };

String versionFilePath(String root, [RemoteAgentProduct product = RemoteAgentProduct.windows]) =>
    p.join(remotesDir(root), agentVersionFileName(product));

(int build, String name) agentVersionRead(String root, [RemoteAgentProduct product = RemoteAgentProduct.windows]) {
  final path = versionFilePath(root, product);
  final line = File(path).readAsStringSync().trim().split('\n').first.trim();
  final m = _versionRegex.firstMatch(line);
  if (m == null) {
    throw StateError('Invalid $path: $line (expected X.Y.Z+BUILD)');
  }
  return (int.parse(m.group(2)!), m.group(1)!);
}

void agentVersionWrite(String root, String name, int build, [RemoteAgentProduct product = RemoteAgentProduct.windows]) {
  File(versionFilePath(root, product)).writeAsStringSync('$name+$build\n');
}

String agentVersionStampSync(String root, [RemoteAgentProduct product = RemoteAgentProduct.windows]) {
  final (build, _) = agentVersionRead(root, product);
  return '$build';
}

/// Minimum supported remote agent build; raise on breaking wire/session (see app-release-min.mdc).
const remoteWindowsExeName = 'alienai_remote_windows.exe';
const remoteWindowsLegacyExeName = 'c_remote_windows.exe';
String remoteWindowsZipFileName(int version) => 'alienai_remote_windows-$version.zip';
String remoteWindowsSetupFileName(int version) => 'AlienAI_Remote_Windows_Setup-$version.exe';
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

void agentVersionBump(String root, [RemoteAgentProduct product = RemoteAgentProduct.windows]) {
  final (build, name) = agentVersionRead(root, product);
  final next = build + 1;
  final parts = name.split('.');
  final major = parts.isNotEmpty ? parts[0] : '1';
  final patch = parts.length > 2 ? parts[2] : '0';
  final nextName = '$major.$next.$patch';
  agentVersionWrite(root, nextName, next, product);
  final label = product == RemoteAgentProduct.browser ? 'remote-browser' : 'remote-windows';
  stdout.writeln('✓ $label version bumped to $nextName+$next');
}
