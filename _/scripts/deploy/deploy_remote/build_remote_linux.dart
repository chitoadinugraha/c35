import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../deploy_app/hash_blake3.dart';
import '../deploy_lib.dart';
import 'agent_version.dart';

class RemoteLinuxBuildResult {
  const RemoteLinuxBuildResult({
    required this.version,
    required this.versionName,
    required this.zipPath,
    required this.hash,
    required this.size,
  });
  final int version;
  final String versionName;
  final String zipPath;
  final String hash;
  final int size;
}

const remoteLinuxExeName = 'c_remote_linux';

String remoteLinuxCacheDir(String root) => p.join(root, '.cache', 'c_remote', 'remote-linux');

String remoteLinuxZipPath(String root, int version) =>
    p.join(remoteLinuxCacheDir(root), 'c_remote_linux-$version.zip');

String remoteLinuxStageDir(String root) => p.join(remoteLinuxCacheDir(root), 'stage');

/// Scaffold: build Linux agent on the host (cross-compile / CI to be added).
Future<RemoteLinuxBuildResult> buildRemoteLinuxRelease() async {
  final root = repoRoot();
  final (build, name) = agentVersionRead(root, RemoteAgentProduct.linux);
  stdout.writeln('Building remote-linux agent release ($name+$build)...');

  final proc = Process.runSync(
    'cargo',
    ['build', '--release', '-p', 'c_remote_linux'],
    workingDirectory: remotesDir(root),
    runInShell: Platform.isWindows,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) {
    throw StateError('cargo build c_remote_linux failed (exit ${proc.exitCode})');
  }

  final exe = File(p.join(root, '.cache', 'c_remote', 'release', remoteLinuxExeName));
  if (!exe.existsSync()) {
    throw StateError('release binary not found: ${exe.path}');
  }

  final cache = Directory(remoteLinuxCacheDir(root));
  if (cache.existsSync()) cache.deleteSync(recursive: true);
  cache.createSync(recursive: true);

  final stage = Directory(remoteLinuxStageDir(root));
  stage.createSync(recursive: true);
  final stagedExe = File(p.join(stage.path, remoteLinuxExeName));
  exe.copySync(stagedExe.path);

  final resourcesDir = p.join(root, 'remotes', 'c_remote_linux', 'resources');
  final service = File(p.join(resourcesDir, 'alienai-agent.service'));
  if (service.existsSync()) {
    service.copySync(p.join(stage.path, 'alienai-agent.service'));
  }
  final applySh = File(p.join(resourcesDir, 'apply.sh'));
  if (applySh.existsSync()) {
    applySh.copySync(p.join(stage.path, 'apply.sh'));
  }
  final readme = File(p.join(resourcesDir, 'README.md'));
  if (readme.existsSync()) {
    readme.copySync(p.join(stage.path, 'README.md'));
  }

  final archive = Archive();
  void addStaged(String name) {
    final f = File(p.join(stage.path, name));
    if (f.existsSync()) {
      archive.addFile(ArchiveFile(name, f.lengthSync(), f.readAsBytesSync()));
    }
  }

  addStaged(remoteLinuxExeName);
  addStaged('alienai-agent.service');
  addStaged('apply.sh');
  addStaged('README.md');
  final zipPath = remoteLinuxZipPath(root, build);
  File(zipPath).parent.createSync(recursive: true);
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) throw StateError('zip encode failed');
  File(zipPath).writeAsBytesSync(zipBytes);

  final hash = blake3HexOfFile(zipPath, root: root);
  final size = File(zipPath).lengthSync();
  stdout.writeln('✓ OTA zip ${formatBytes(size)} hash=$hash');

  return RemoteLinuxBuildResult(
    version: build,
    versionName: name,
    zipPath: zipPath,
    hash: hash,
    size: size,
  );
}
