import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../deploy_app/hash_blake3.dart';
import '../deploy_lib.dart';
import 'agent_version.dart';

class RemoteBrowserBuildResult {
  const RemoteBrowserBuildResult({
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

const remoteBrowserExeName = 'alienai_remote_browser.exe';
const remoteBrowserConfigKey = 'app.release.c35.remote-browser';

String remoteBrowserCacheDir(String root) => p.join(root, '.cache', 'c_remote', 'remote-browser');

String remoteBrowserZipFileName(int version) => 'alienai_remote_browser-$version.zip';

String _engineDir(String root) => p.join(root, 'remotes', 'browser_engine');

/// Isolated from shared `remotes/.cargo` target-dir so Windows/Linux/browser publishes do not deadlock on `.cargo-lock`.
String remoteBrowserCargoTargetDir(String root) =>
    p.join(root, '.cache', 'c_remote_browser_target');

Future<void> _run(
  String cwd,
  String executable,
  List<String> args, {
  Map<String, String>? environment,
}) async {
  final env = {...Platform.environment, ...?environment};
  final proc = await Process.start(
    executable,
    args,
    workingDirectory: cwd,
    runInShell: true,
    environment: env,
  );
  await Future.wait([
    proc.stdout.forEach(stdout.add),
    proc.stderr.forEach(stderr.add),
  ]);
  final code = await proc.exitCode;
  if (code != 0) throw StateError('$executable ${args.join(' ')} failed ($code)');
}

Future<RemoteBrowserBuildResult> buildRemoteBrowserRelease() async {
  final root = repoRoot();
  final (build, name) = agentVersionRead(root, RemoteAgentProduct.browser);
  final cache = Directory(remoteBrowserCacheDir(root));
  cache.createSync(recursive: true);
  final stage = Directory(p.join(cache.path, 'stage'));
  if (stage.existsSync()) stage.deleteSync(recursive: true);
  stage.createSync(recursive: true);

  final engine = _engineDir(root);
  await _run(engine, 'npm', ['run', 'build']);

  final remotes = p.join(root, 'remotes');
  final cargoTarget = remoteBrowserCargoTargetDir(root);
  stdout.writeln('==> cargo build -p c_remote_browser (target=$cargoTarget)');
  await _run(
    remotes,
    'cargo',
    ['build', '--release', '-p', 'c_remote_browser'],
    environment: {'CARGO_TARGET_DIR': cargoTarget},
  );

  final targetDir = p.join(cargoTarget, 'release');
  final exe = File(p.join(targetDir, remoteBrowserExeName));
  if (!exe.existsSync()) {
    throw StateError('Missing ${exe.path} — run cargo build --release -p c_remote_browser from remotes/');
  }
  exe.copySync(p.join(stage.path, remoteBrowserExeName));

  final engineStage = p.join(stage.path, 'browser_engine');
  await _copyTree(p.join(engine, 'dist'), p.join(engineStage, 'dist'));
  File(p.join(engine, 'package.json')).copySync(p.join(engineStage, 'package.json'));
  final nm = p.join(engine, 'node_modules');
  if (Directory(nm).existsSync()) {
    await _copyTree(nm, p.join(engineStage, 'node_modules'));
  } else {
    stdout.writeln('WARN: browser_engine node_modules missing — run npm install in remotes/browser_engine');
  }

  final archive = Archive();
  for (final f in stage.listSync(recursive: true).whereType<File>()) {
    final rel = p.relative(f.path, from: stage.path).replaceAll('\\', '/');
    archive.addFile(ArchiveFile(rel, f.lengthSync(), f.readAsBytesSync()));
  }
  final zipPath = p.join(cache.path, remoteBrowserZipFileName(build));
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) throw StateError('zip encode failed');
  File(zipPath).writeAsBytesSync(zipBytes);
  final hash = blake3HexOfFile(zipPath, root: root);
  final size = File(zipPath).lengthSync();
  stdout.writeln('✓ remote-browser OTA zip ${formatBytes(size)} hash=$hash');
  return RemoteBrowserBuildResult(version: build, versionName: name, zipPath: zipPath, hash: hash, size: size);
}

Future<void> _copyTree(String src, String dest) async {
  final d = Directory(dest);
  d.createSync(recursive: true);
  await for (final ent in Directory(src).list(recursive: true, followLinks: false)) {
    final rel = p.relative(ent.path, from: src);
    final target = p.join(dest, rel);
    if (ent is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (ent is File) {
      File(target).parent.createSync(recursive: true);
      ent.copySync(target);
    }
  }
}
