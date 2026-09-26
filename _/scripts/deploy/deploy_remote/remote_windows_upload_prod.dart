import 'dart:io';

import 'package:path/path.dart' as p;

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_windows.dart';
import 'upload_remote_windows_release.dart';

Future<void> _runRemoteReleaseSmoke(int publishedVersion) async {
  final script = p.join(repoRoot(), '_', 'scripts', 'deploy', 'deploy_remote', 'smoke_remote_release.ps1');
  final proc = await Process.run(
    'powershell',
    [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script,
      '-MinVersion',
      '$publishedVersion',
      '-MinBuild',
      '$remoteAgentMinBuild',
    ],
    runInShell: false,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('smoke_remote_release failed (exit ${proc.exitCode})');
}

Future<void> _runProdOtaDryRun(int minVersion) async {
  final script = p.join(repoRoot(), '_', 'scripts', 'dev', 'test_remote_ota_prod.ps1');
  final proc = await Process.run(
    'powershell',
    [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script,
      '-MinVersion',
      '$minVersion',
      '-MinBuild',
      '$remoteAgentMinBuild',
    ],
    runInShell: false,
  );
  stdout.write(proc.stdout);
  stderr.write(proc.stderr);
  if (proc.exitCode != 0) throw StateError('test_remote_ota_prod failed (exit ${proc.exitCode})');
}

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final build = buildRemoteWindowsRelease();
    await uploadAndPublishRemoteRelease(build);
    await _runRemoteReleaseSmoke(build.version);
    await _runProdOtaDryRun(build.version);
    agentVersionBump(repoRoot());
    deployDone(version: 'remote-windows ${build.versionName}+${build.version}', detail: 'zip ${formatBytes(build.size)}');
  } catch (e) {
    phaseFail('Remote agent upload failed', e.toString());
  }
}
