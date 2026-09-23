import 'dart:io';

import '../deploy_lib.dart';
import 'build_android.dart';
import 'build_web.dart';
import 'build_windows.dart';
import 'cleanup_app_artifacts.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';
import 'publish_app_version.dart';
import 's3_upload.dart';
import 'update_version.dart';
import 'upload_android_release.dart';
import 'upload_windows_release.dart';

Future<void> main(List<String> args) async {
  try {
    final tester = args.contains('--tester');
    final androidOnly = args.contains('--android-only');
    final windowsOnly = args.contains('--windows-only');
    final webOnly = args.contains('--web-only');
    if (androidOnly && windowsOnly) throw StateError('Cannot use --android-only and --windows-only together');
    if (webOnly && (androidOnly || windowsOnly)) {
      throw StateError('Cannot combine --web-only with --android-only or --windows-only');
    }

    deployStart();
    deployLoadEnvLocal();

    if (webOnly) {
      S3UploadConfig.fromEnv();
      final versionCode = int.parse(versionStampSync(repoRoot()));
      final webDir = buildWebRelease();
      await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
      await publishWebAppVersion(versionCode);
      deployAppBumpVersion();
      deployDone(version: 'v$versionCode', detail: 'web ${dirSizeLabel(webDir)}');
      return;
    }

    if (windowsOnly) {
      final build = buildWindowsRelease();
      await runStep('Upload Windows zip to CAS', () => uploadWindowsReleaseOnly(build));
      await publishWindowsAppVersion(version: build.version, hash: build.hash, size: build.size);
      deployAppBumpVersion();
      deployDone(version: 'v${build.version}', detail: 'zip ${formatBytes(build.size)}');
      return;
    }

    await runStep('Load Play Store credentials', playStoreCredentialsJson);

    if (tester) {
      final versionCode = await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
      deployAppBumpVersion();
      deployDone(version: 'v$versionCode', detail: 'internal AAB only');
      return;
    }

    final versionCode = await playStoreAlignVersionToNext();
    stdout.writeln('Release build number: $versionCode');

    await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
    await promotePlayStoreReleaseToProduction(versionCode);

    Platform.environment['DEPLOY_SKIP_VERSION_BUMP'] = '1';

    final apk = buildAndroidApk();
    await uploadAndroidApkRelease(apk);

    WindowsBuildResult? win;
    String? webDir;
    if (!androidOnly) {
      win = buildWindowsRelease();
      await runStep('Upload Windows zip to CAS', () => uploadWindowsReleaseOnly(win!));
      webDir = buildWebRelease();
      await s3UploadWebBuild(versionCode: versionCode, webBuildDir: webDir);
    }

    await publishAppReleaseProd(
      version: versionCode,
      apkHash: apk.hash,
      apkSize: apk.size,
      windowsHash: win?.hash ?? '',
      windowsSize: win?.size ?? 0,
      includeWeb: webDir != null,
    );

    await maybePruneAppArtifactsAfterPublish();
    deployAppBumpVersion();

    final parts = <String>['AAB', 'APK'];
    if (win != null) parts.add('ZIP');
    if (webDir != null) parts.add('web');
    deployDone(version: 'v$versionCode', detail: parts.join('+'));
  } catch (e) {
    phaseFail('App release failed', e.toString());
  }
}
