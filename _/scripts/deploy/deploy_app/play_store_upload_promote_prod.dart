import 'dart:io';

import '../deploy_lib.dart';
import 'build_android.dart';
import 'cleanup_app_artifacts.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';
import 'publish_app_version.dart';
import 'upload_android_release.dart';

int? _parsePromoteOnlyVersionCode(List<String> args) {
  final idx = args.indexOf('--promote-only');
  if (idx == -1) return null;
  if (idx + 1 >= args.length) {
    throw StateError('Usage: dart run play_store_upload_promote_prod.dart --promote-only <versionCode>');
  }
  final n = int.tryParse(args[idx + 1]);
  if (n == null || n <= 0) throw StateError('Invalid versionCode: ${args[idx + 1]}');
  return n;
}

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final promoteOnly = _parsePromoteOnlyVersionCode(args);
    if (promoteOnly != null) {
      await runStep('Load Play Store credentials', playStoreCredentialsJson);
      await promotePlayStoreReleaseToProduction(promoteOnly);
      await publishAndroidAppVersion(promoteOnly);
      stdout.writeln('Promote-only complete!');
      final version = await playStoreShowDeployedStatus();
      deployDone(version: version);
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
    deployDone(version: version, detail: 'AAB ${aabBundleSizeLabel()}');
  } catch (e) {
    phaseFail('Play Store promote failed', e.toString());
  }
}
