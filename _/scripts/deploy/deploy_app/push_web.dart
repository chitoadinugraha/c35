import 'dart:io';

import '../deploy_lib.dart';
import 'build_web.dart';
import 'publish_app_version.dart';
import 's3_upload.dart';
import 'update_version.dart';

/// Build + upload Flutter web only → `app/web/current/` (serves `alienai.id/app/`).
Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    S3UploadConfig.fromEnv();

    final (_, versionCode) = versionReadPubspec(repoRoot());
    versionStampSync(repoRoot());
    stdout.writeln('Push web for build $versionCode');

    final webDir = await runStep('Build Flutter web', () async => buildWebRelease());
    await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
    await publishWebAppVersion(versionCode);

    stdout.writeln('✓ Web: $webAppUrl');
    deployDone(version: 'v$versionCode', detail: 'web ${dirSizeLabel(webDir)}');
  } catch (e) {
    phaseFail('push_web failed', e.toString());
  }
}
