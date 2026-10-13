import 'dart:io';

import '../deploy_lib.dart';
import 'build_android.dart';
import 'cleanup_app_artifacts.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';
import 'publish_app_version.dart';
import 'update_version.dart';
import 'upload_android_release.dart';

/// Production APK sideload: build signed release APK, CAS upload, GET /version/android.
/// Does not upload AAB or promote on Play (avoids production track queue reset).
Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();

    int versionCode;
    if (isPlayStoreUploadConfigured()) {
      await runStep('Load Play Store credentials', playStoreCredentialsJson);
      versionCode = await playStoreAlignVersionToNext();
    } else {
      versionCode = int.parse(versionStampSync(repoRoot()));
      stdout.writeln(
        '[warn] Play credentials not configured — using pubspec build $versionCode (no Play align)',
      );
    }
    stdout.writeln('APK release build number: $versionCode');

    final apk = buildAndroidApk();
    await uploadAndroidApkRelease(apk);
    await publishAndroidAppVersion(versionCode, apkHash: apk.hash, apkSize: apk.size);
    await maybePruneAppArtifactsAfterPublish();
    deployAppBumpVersionUnlessSkipped();
    stdout.writeln('APK build, CAS upload, and /version/android publish complete!');
    deployDone(
      version: 'v$versionCode',
      detail: 'APK ${formatBytes(apk.size)} hash=${apk.hash}',
      target: 'android-apk-prod',
    );
  } catch (e) {
    phaseFail('Android APK release failed', e.toString());
  }
}
