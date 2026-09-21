import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_apk_sideload.dart';
import 'package:alienai_c35/c/update/app_update_prefs.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

int _localBuild() => int.tryParse(csaiVersion.trim()) ?? 0;

bool appUpdatePlayNotOwned(Object error) {
  if (error is! PlatformException) return false;
  final message = error.message ?? '';
  return error.code == 'TASK_FAILURE' && (message.contains('ERROR_APP_NOT_OWNED') || message.contains('Install Error(-10)'));
}

Future<void> appUpdateAndroidCheck({
  required Future<bool> Function({required bool force, required bool apkSideload}) askToUpdate,
  required Future<bool> Function() askToRestart,
}) async {
  AppUpdateInfo? info;
  var playOwned = true;
  try {
    info = await InAppUpdate.checkForUpdate();
  } on PlatformException catch (e) {
    if (appUpdatePlayNotOwned(e)) {
      playOwned = false;
    } else {
      rethrow;
    }
  }

  if (!playOwned) {
    await appUpdateAndroidSideloadCheck(askToUpdate: askToUpdate);
    return;
  }

  final playInfo = info!;
  if (playInfo.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
    if (playInfo.installStatus == InstallStatus.downloaded && await askToRestart()) await InAppUpdate.completeFlexibleUpdate();
    return;
  }

  if (playInfo.updateAvailability != UpdateAvailability.updateAvailable) return;

  final versionCode = playInfo.availableVersionCode;
  if (versionCode != null && versionCode > 0 && await appUpdateDismissedVersion(versionCode)) return;

  var force = false;
  try {
    final base = await serverHostActiveBase();
    final remote = await appReleaseGet(base, platform: 'android');
    if (remote != null && remote.min > 0) force = _localBuild() < remote.min;
  } catch (_) {}

  final accepted = await askToUpdate(force: force, apkSideload: false);
  if (!accepted) {
    if (!force && versionCode != null && versionCode > 0) await appUpdateDismissedVersionPut(versionCode);
    return;
  }

  if (playInfo.flexibleUpdateAllowed) {
    final result = await InAppUpdate.startFlexibleUpdate();
    if (result == AppUpdateResult.success && await askToRestart()) await InAppUpdate.completeFlexibleUpdate();
    return;
  }

  if (playInfo.immediateUpdateAllowed) await InAppUpdate.performImmediateUpdate();
}
