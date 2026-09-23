import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import '../deploy_app/hash_blake3.dart';
import 'agent_version.dart';

class RemoteWindowsBuildResult {
  const RemoteWindowsBuildResult({required this.version, required this.versionName, required this.zipPath, required this.hash, required this.size});
  final int version;
  final String versionName;
  final String zipPath;
  final String hash;
  final int size;
}

String remoteCacheDir(String root) => p.join(root, '.cache', 'agent', 'remote-windows');

String remoteZipPath(String root, int version) => p.join(remoteCacheDir(root), 'c_remote_windows-$version.zip');

RemoteWindowsBuildResult buildRemoteWindowsRelease() {
  final root = repoRoot();
  final (build, name) = agentVersionRead(root);
  stdout.writeln('Building remote agent release ($name+$build)...');

  final proc = Process.runSync(
    'cargo',
    ['build', '--release', '-p', 'c_remote_windows'],
    workingDirectory: remotesDir(root),
    runInShell: Platform.isWindows,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('cargo build c_remote_windows failed (exit ${proc.exitCode})');

  final exe = File(p.join(root, '.cache', 'agent', 'release', 'c_remote_windows.exe'));
  if (!exe.existsSync()) throw StateError('release exe not found: ${exe.path}');

  final cache = Directory(remoteCacheDir(root));
  if (cache.existsSync()) cache.deleteSync(recursive: true);
  cache.createSync(recursive: true);
  final staged = File(p.join(cache.path, 'c_remote_windows.exe'));
  exe.copySync(staged.path);

  final archive = Archive()..addFile(ArchiveFile('c_remote_windows.exe', staged.lengthSync(), staged.readAsBytesSync()));
  final zipPath = remoteZipPath(root, build);
  File(zipPath).parent.createSync(recursive: true);
  final bytes = ZipEncoder().encode(archive);
  if (bytes == null) throw StateError('zip encode failed');
  File(zipPath).writeAsBytesSync(bytes);

  final hash = blake3HexOfFile(zipPath, root: root);
  final size = File(zipPath).lengthSync();
  stdout.writeln('✓ Remote agent zip ${formatBytes(size)} hash=$hash');
  return RemoteWindowsBuildResult(version: build, versionName: name, zipPath: zipPath, hash: hash, size: size);
}
