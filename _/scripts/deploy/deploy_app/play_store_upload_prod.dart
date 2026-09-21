import 'dart:io';

import '../deploy_lib.dart';
import 'cleanup_app_artifacts.dart';
import 'build_android.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';
import 'publish_app_version.dart';
import 'upload_android_release.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final versionCode = await playStoreBuildAndUpload((buildDir) => uploadAabToPlayStoreProduction(buildDir));
    final apk = buildAndroidApk();
    await uploadAndroidApkRelease(apk);
    await publishAndroidAppVersion(versionCode, apkHash: apk.hash, apkSize: apk.size);
    await maybePruneAppArtifactsAfterPublish();
    deployAppBumpVersion();
    stdout.writeln('Build and upload complete!');
    final version = await playStoreShowDeployedStatus();
    deployDone(version: version, detail: 'AAB ${aabBundleSizeLabel()}');
  } catch (e) {
    phaseFail('Play Store upload failed', e.toString());
  }
}
