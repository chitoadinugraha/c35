import 'dart:io';

import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_android.dart';
import 'upload_remote_android_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final build = await buildRemoteAndroidRelease();
    await uploadAndPublishRemoteAndroidRelease(build);
    agentVersionBump(repoRoot(), RemoteAgentProduct.android);
    deployDone(version: 'remote-android ${build.versionName}+${build.version}', detail: 'apk ${formatBytes(build.size)}');
  } catch (e) {
    phaseFail('Remote android upload failed', e.toString());
  }
}
