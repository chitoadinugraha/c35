import 'dart:io';

import '../deploy_lib.dart';
import 'deploy_app_lib.dart';
import 'play_store.dart';

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    await runStep('Load Play Store credentials', playStoreCredentialsJson);
    final versionCode = await playStoreBuildAndUpload(uploadAabToPlayStoreInternal);
    // Internal only — no APK, no GET /version/android (prod clients must not sideload-update).
    deployAppBumpVersionUnlessSkipped();
    stdout.writeln('Tester upload complete (internal track, versionCode $versionCode)');
    final version = await playStoreShowDeployedStatus();
    deployDone(version: version ?? 'v$versionCode', detail: 'AAB ${aabBundleSizeLabel()}', target: 'android-tester');
  } catch (e) {
    phaseFail('Play Store tester upload failed', e.toString());
  }
}
