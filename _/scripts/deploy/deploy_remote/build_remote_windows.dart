import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../deploy_app/hash_blake3.dart';
import '../deploy_lib.dart';
import 'agent_version.dart';

class RemoteWindowsBuildResult {
  const RemoteWindowsBuildResult({
    required this.version,
    required this.versionName,
    required this.zipPath,
    required this.hash,
    required this.size,
    this.setupPath,
    this.setupHash,
    this.setupSize,
  });
  final int version;
  final String versionName;
  final String zipPath;
  final String hash;
  final int size;
  final String? setupPath;
  final String? setupHash;
  final int? setupSize;
}

String remoteCacheDir(String root) => p.join(root, '.cache', 'c_remote', 'remote-windows');

String remoteZipPath(String root, int version) => p.join(remoteCacheDir(root), remoteWindowsZipFileName(version));

String remoteSetupPath(String root, int version) => p.join(remoteCacheDir(root), remoteWindowsSetupFileName(version));

String remoteStageDir(String root) => p.join(remoteCacheDir(root), 'stage');

const _vcRedistUrl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe';

String _vcRedistCachePath(String root) => p.join(root, '.cache', 'c_remote', 'vendor', 'vc_redist.x64.exe');

String _issPath(String root) => p.join(root, '_', 'scripts', 'deploy', 'deploy_remote', 'vendor', 'alienai_remote_windows.iss');

String _setupBuildScript(String root) => p.join(root, '_', 'scripts', 'deploy', 'deploy_remote', 'build_remote_windows_setup.ps1');

String _agentIconPath(String root) => p.join(root, 'remotes', 'c_remote_windows', 'resources', 'alien_rounded.ico');

String _installScriptPath(String root) => p.join(root, '_', 'scripts', 'deploy', 'deploy_remote', 'vendor', 'install_remote_windows.ps1');

String _runtimeScriptPath(String root) => p.join(root, '_', 'scripts', 'deploy', 'deploy_remote', 'vendor', 'remote_runtime.ps1');

Future<File> _ensureVcRedist(String root) async {
  final dest = File(_vcRedistCachePath(root));
  if (dest.existsSync() && dest.lengthSync() > 1000000) return dest;
  dest.parent.createSync(recursive: true);
  stdout.writeln('Downloading VC++ redist for installer bundle...');
  final res = await http.get(Uri.parse(_vcRedistUrl));
  if (res.statusCode != 200) {
    throw StateError('vc_redist download failed (${res.statusCode})');
  }
  dest.writeAsBytesSync(res.bodyBytes);
  stdout.writeln('✓ vc_redist.x64.exe ${formatBytes(dest.lengthSync())}');
  return dest;
}

Future<String?> _buildSetupExe({
  required String root,
  required String stageDir,
  required String outputDir,
  required String versionName,
  required int build,
}) async {
  final iss = _issPath(root);
  if (!File(iss).existsSync()) throw StateError('Inno Setup script missing: $iss');
  final script = _setupBuildScript(root);
  if (!File(script).existsSync()) throw StateError('Setup build script missing: $script');

  final proc = await Process.run(
    'powershell',
    [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script,
      '-StageDir',
      stageDir,
      '-OutputDir',
      outputDir,
      '-AppVersion',
      versionName,
      '-AppBuild',
      '$build',
      '-IssPath',
      iss,
    ],
    runInShell: false,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) {
    stdout.writeln('⚠ Setup.exe build failed (see errors above)');
    return null;
  }
  final built = p.join(outputDir, 'AlienAI_Remote_Windows_Setup.exe');
  if (!File(built).existsSync()) return null;
  final versioned = remoteSetupPath(root, build);
  File(built).copySync(versioned);
  return versioned;
}

Future<RemoteWindowsBuildResult> buildRemoteWindowsRelease({bool bundleVcRedist = true, bool buildSetup = true}) async {
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

  final exe = File(p.join(root, '.cache', 'c_remote', 'release', remoteWindowsExeName));
  if (!exe.existsSync()) throw StateError('release exe not found: ${exe.path}');

  final cache = Directory(remoteCacheDir(root));
  if (cache.existsSync()) cache.deleteSync(recursive: true);
  cache.createSync(recursive: true);

  final stage = Directory(remoteStageDir(root));
  stage.createSync(recursive: true);
  final stagedExe = File(p.join(stage.path, remoteWindowsExeName));
  exe.copySync(stagedExe.path);

  final icon = File(_agentIconPath(root));
  if (icon.existsSync()) {
    icon.copySync(p.join(stage.path, 'alien_rounded.ico'));
  }

  if (bundleVcRedist) {
    final vc = await _ensureVcRedist(root);
    vc.copySync(p.join(stage.path, 'vc_redist.x64.exe'));
  }

  File(_runtimeScriptPath(root)).copySync(p.join(stage.path, 'remote_runtime.ps1'));
  File(_installScriptPath(root)).copySync(p.join(stage.path, 'install_remote_windows.ps1'));

  // OTA zip: agent binary only (small; static CRT + server push).
  final archive = Archive()..addFile(ArchiveFile(remoteWindowsExeName, stagedExe.lengthSync(), stagedExe.readAsBytesSync()));
  final zipPath = remoteZipPath(root, build);
  File(zipPath).parent.createSync(recursive: true);
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) throw StateError('zip encode failed');
  File(zipPath).writeAsBytesSync(zipBytes);

  final hash = blake3HexOfFile(zipPath, root: root);
  final size = File(zipPath).lengthSync();
  stdout.writeln('✓ OTA zip ${formatBytes(size)} hash=$hash');

  String? setupPath;
  String? setupHash;
  int? setupSize;
  if (buildSetup && Platform.isWindows && bundleVcRedist) {
    setupPath = await _buildSetupExe(root: root, stageDir: stage.path, outputDir: cache.path, versionName: name, build: build);
    if (setupPath != null) {
      setupHash = blake3HexOfFile(setupPath, root: root);
      setupSize = File(setupPath).lengthSync();
      stdout.writeln('✓ Setup ${formatBytes(setupSize)} hash=$setupHash');
      stdout.writeln('  Give users: ${p.basename(setupPath)} (installs VC++ only if needed)');
    }
  }

  return RemoteWindowsBuildResult(
    version: build,
    versionName: name,
    zipPath: zipPath,
    hash: hash,
    size: size,
    setupPath: setupPath,
    setupHash: setupHash,
    setupSize: setupSize,
  );
}
