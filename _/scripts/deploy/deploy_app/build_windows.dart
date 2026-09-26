import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'hash_blake3.dart';
import 'update_version.dart';

class WindowsBuildResult {
  const WindowsBuildResult({required this.version, required this.zipPath, required this.hash, required this.size});
  final int version;
  final String zipPath;
  final String hash;
  final int size;
}

String windowsCacheDir(String root) => p.join(root, '.cache', 'app', 'windows');

String windowsBundleDir(String root) => p.join(windowsCacheDir(root), 'release');

String windowsZipPath(String root, int version) => p.join(windowsCacheDir(root), 'alienai-windows-$version.zip');

String windowsFlutterReleaseDir(String root) => p.join(deployAppDir(root), 'build', 'windows', 'x64', 'runner', 'Release');

void _copyTree(Directory from, Directory to) {
  if (!to.existsSync()) to.createSync(recursive: true);
  for (final ent in from.listSync(recursive: false, followLinks: false)) {
    final name = p.basename(ent.path);
    final dst = File(p.join(to.path, name));
    if (ent is File) {
      dst.parent.createSync(recursive: true);
      ent.copySync(dst.path);
    } else if (ent is Directory) {
      _copyTree(ent, Directory(dst.path));
    }
  }
}

Archive _dirArchive(Directory dir, {String prefix = ''}) {
  final archive = Archive();
  for (final ent in dir.listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    final rel = p.relative(ent.path, from: dir.path);
    final name = prefix.isEmpty ? rel : p.join(prefix, rel);
    archive.addFile(ArchiveFile(name, ent.lengthSync(), ent.readAsBytesSync()));
  }
  return archive;
}

void _writeZip(Directory bundleDir, String zipPath) {
  final archive = _dirArchive(bundleDir);
  final bytes = ZipEncoder().encode(archive);
  if (bytes == null) throw StateError('zip encode failed');
  File(zipPath).parent.createSync(recursive: true);
  File(zipPath).writeAsBytesSync(bytes);
}

WindowsBuildResult buildWindowsRelease({String? serverUrl}) {
  final root = repoRoot();
  final version = int.parse(versionStampSync(root));
  final apiServer = serverUrl?.trim().isNotEmpty == true
      ? serverUrl!.trim()
      : (deployEnv('C35_SERVER', 'https://alienai.id'));
  stdout.writeln('Building Windows release (version $version, server $apiServer)...');

  final clientApp = deployAppDir(root);
  deployRunSync('flutter_windows', () {
    final flutterProc = Process.runSync(
      'flutter',
      ['build', 'windows', '--release', '--dart-define=C35_SERVER=$apiServer'],
      workingDirectory: clientApp,
      runInShell: Platform.isWindows,
    );
    stdout.write(flutterProc.stdout);
    stderr.write(flutterProc.stderr);
    if (flutterProc.exitCode != 0) throw StateError('flutter build windows failed (exit ${flutterProc.exitCode})');
  });

  final flutterOut = windowsFlutterReleaseDir(root);
  if (!Directory(flutterOut).existsSync()) throw StateError('Flutter Windows release dir not found: $flutterOut');

  final bundle = Directory(windowsBundleDir(root));
  if (bundle.existsSync()) bundle.deleteSync(recursive: true);
  bundle.createSync(recursive: true);
  _copyTree(Directory(flutterOut), bundle);

  final zipPath = windowsZipPath(root, version);
  deployRunSync('windows_zip', () => _writeZip(bundle, zipPath));
  final hash = blake3HexOfFile(zipPath, root: root);
  final size = File(zipPath).lengthSync();
  deployArtifact('windows_zip', size);
  stdout.writeln('✓ Windows zip ${formatBytes(size)} hash=$hash');
  return WindowsBuildResult(version: version, zipPath: zipPath, hash: hash, size: size);
}
