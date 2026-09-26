import 'dart:io';

import '../deploy_lib.dart';
import 'build_android.dart';
import 'cleanup_app_artifacts.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';
import 'publish_app_version.dart';
import 'upload_android_release.dart';

int? _parseFlagVersionCode(List<String> args, String flag) {
  final idx = args.indexOf(flag);
  if (idx == -1) return null;
  if (idx + 1 >= args.length) {
    throw StateError('Usage: dart run play_store_upload_promote_prod.dart $flag <versionCode>');
  }
  final n = int.tryParse(args[idx + 1]);
  if (n == null || n <= 0) throw StateError('Invalid versionCode: ${args[idx + 1]}');
  return n;
}

int? _parsePromoteOnlyVersionCode(List<String> args) => _parseFlagVersionCode(args, '--promote-only');

int? _parseFinishCasOnlyVersionCode(List<String> args) => _parseFlagVersionCode(args, '--finish-cas-only');

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final finishCasOnly = _parseFinishCasOnlyVersionCode(args);
    if (finishCasOnly != null) {
      final apk = androidApkResultFromExisting(version: finishCasOnly);
      await uploadAndroidApkRelease(apk);
      await publishAndroidAppVersion(finishCasOnly, apkHash: apk.hash, apkSize: apk.size);
      await maybePruneAppArtifactsAfterPublish();
      deployAppBumpVersionUnlessSkipped();
      stdout.writeln('CAS upload and /version/android publish complete!');
      final version = await playStoreShowDeployedStatus();
      deployDone(version: version, detail: 'APK hash ${apk.hash}', target: 'android-promote-prod');
      return;
    }
    final promoteOnly = _parsePromoteOnlyVersionCode(args);
    if (promoteOnly != null) {
      await runStep('Load Play Store credentials', playStoreCredentialsJson);
      await promotePlayStoreReleaseToProduction(promoteOnly);
      await publishAndroidAppVersion(promoteOnly);
      stdout.writeln('Promote-only complete!');
      final version = await playStoreShowDeployedStatus();
      deployDone(version: version, target: 'android-promote-only');
      return;
    }
    await runStep('Load Play Store credentials', playStoreCredentialsJson);
    final versionCode = await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
    await promotePlayStoreReleaseToProduction(versionCode);
    final apk = buildAndroidApk();
    await uploadAndroidApkRelease(apk);
    await publishAndroidAppVersion(versionCode, apkHash: apk.hash, apkSize: apk.size);
    await maybePruneAppArtifactsAfterPublish();
    deployAppBumpVersionUnlessSkipped();
    stdout.writeln('Build, internal upload, promote, and APK upload complete!');
    final version = await playStoreShowDeployedStatus();
    deployDone(version: version, detail: 'AAB ${aabBundleSizeLabel()}', target: 'android-promote-prod');
  } catch (e) {
    phaseFail('Play Store promote failed', e.toString());
  }
}
