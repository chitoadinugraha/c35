import 'dart:io';

import '../deploy_lib.dart';
import 'build_windows.dart';
import 'deploy_app_lib.dart';
import 'upload_windows_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final skipNats = args.contains('--skip-nats');
    final build = buildWindowsRelease();
    await uploadAndPublishWindowsRelease(build, skipNats: skipNats);
    deployAppBumpVersionUnlessSkipped();
    stdout.writeln('Windows build and upload complete!');
    deployDone(
      version: 'v${build.version}',
      detail: 'zip ${formatBytes(build.size)}',
      target: 'windows-app-prod',
    );
  } catch (e) {
    phaseFail('Windows upload failed', e.toString());
  }
}
