import 'dart:io';

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_windows.dart';
import 'upload_remote_windows_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final build = buildRemoteWindowsRelease();
    await uploadAndPublishRemoteRelease(build);
    agentVersionBump(repoRoot());
    deployDone(version: 'remote-windows ${build.versionName}+${build.version}', detail: 'zip ${formatBytes(build.size)}');
  } catch (e) {
    phaseFail('Remote agent upload failed', e.toString());
  }
}
