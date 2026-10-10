import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_remote_linux.dart';
import 'upload_remote_linux_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final build = await buildRemoteLinuxRelease();
    await uploadAndPublishRemoteLinuxRelease(build);
    agentVersionBump(repoRoot(), RemoteAgentProduct.linux);
    deployDone(version: 'remote-linux ${build.versionName}+${build.version}', detail: 'zip ${formatBytes(build.size)}');
  } catch (e) {
    phaseFail('Remote-linux agent upload failed', e.toString());
  }
}
