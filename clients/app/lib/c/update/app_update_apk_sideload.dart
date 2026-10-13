import 'package:alienai_c35/c/update/app_update_apk_ota.dart';

/// Legacy entry — APK channel OTA lives in [appUpdateApkOtaCheck].
Future<void> appUpdateAndroidSideloadCheck({
  required Future<bool> Function({required bool force, required bool apkSideload}) askToUpdate,
}) =>
    appUpdateApkOtaCheck(askToUpdate: askToUpdate);
