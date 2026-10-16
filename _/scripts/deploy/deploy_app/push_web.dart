import 'dart:io';

import '../deploy_lib.dart';
import 'build_web.dart';
import 'deploy_app_lib.dart';
import 'publish_app_version.dart';
import 's3_upload.dart';
import 'update_version.dart';

/// Build + upload Flutter web only → `app/web/current/` (serves `alienai.id/app/`).
/// Bumps pubspec once after publish (same as `--web-only`); skip with `DEPLOY_SKIP_VERSION_BUMP=1`.
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
    deployAppBumpVersionUnlessSkipped();

    stdout.writeln('✓ Web: $webAppUrl');
    deployDone(version: 'v$versionCode', detail: 'web ${dirSizeLabel(webDir)}', target: 'web-release');
  } catch (e) {
    phaseFail('push_web failed', e.toString());
  }
}
