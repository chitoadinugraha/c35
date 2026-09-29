import '../deploy_lib.dart';
import 'agent_version.dart';
import 'build_chrome_extension.dart';
import 'upload_chrome_extension_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final build = await buildChromeExtensionRelease();
    await uploadAndPublishChromeExtensionRelease(build);
    agentVersionBump(repoRoot(), RemoteAgentProduct.chromeExtension);
    deployDone(
      version: 'chrome-extension ${build.versionName}+${build.version}',
      detail: 'zip ${formatBytes(build.size)}',
    );
  } catch (e) {
    phaseFail('Chrome extension upload failed', e.toString());
  }
}
