import 'dart:io';

import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_channel.dart';
import 'package:alienai_c35/c/update/app_update_download.dart';
import 'package:alienai_c35/c/update/app_update_install_android.dart';
import 'package:alienai_c35/c/update/app_update_paths_android.dart';
import 'package:alienai_c35/c/update/app_update_prefs.dart';
import 'package:alienai_c35/c/update/app_update_service.dart';

int appUpdateApkLocalBuild() => int.tryParse(csaiVersion.trim()) ?? 0;

Future<void> appUpdateApkOtaCheck({
  required Future<bool> Function({required bool force, required bool apkSideload}) askToUpdate,
}) async {
  final base = await serverHostActiveBase();
  final remote = await appReleaseGet(base, platform: 'android');
  if (remote == null || remote.apkUrl.isEmpty) return;

  final local = appUpdateApkLocalBuild();
  if (!appReleaseNeedsUpdate(local: local, remote: remote)) {
    AppUpdateService.instance.setAndroidApkUpToDate(remote);
    return;
  }

  final force = appReleaseForceUpdate(local: local, remote: remote);
  if (await appUpdateApkStagedReady(remote.version)) {
    AppUpdateService.instance.setAndroidApkReady(remote, force: force);
    if (force) await appUpdateApkInstallStaged(remote.version);
    return;
  }

  if (!force && await appUpdateDismissedVersion(remote.version)) return;

  if (force) {
    AppUpdateService.instance.setAndroidApkForceRequired(remote);
    await _downloadApkRelease(remote);
    if (await appUpdateApkStagedReady(remote.version)) {
      await appUpdateApkInstallStaged(remote.version);
    }
    return;
  }

  final accepted = await askToUpdate(force: false, apkSideload: true);
  if (!accepted) {
    await appUpdateDismissedVersionPut(remote.version);
    return;
  }

  await _downloadApkRelease(remote);
}

Future<bool> appUpdateApkDownloadStage(AppRelease release, {void Function(double progress)? onProgress}) async {
  try {
    final dest = await appUpdateApkFilePath(release.version);
    await appUpdateApkClearStage(release.version);
    final ok = await appUpdateDownloadFile(
      url: release.apkUrl,
      dest: dest,
      expectSize: release.apkSize,
      onProgress: onProgress,
    );
    if (!ok) return false;
    final hash = release.apkHash.isNotEmpty ? release.apkHash : release.hash;
    if (hash.isNotEmpty && !appUpdateBlake3Match(dest, hash)) {
      lError('apk update hash mismatch');
      try {
        File(dest).deleteSync();
      } catch (_) {}
      return false;
    }
    await appUpdateApkWriteReadyMarker(release.version);
    return true;
  } catch (e) {
    lError(e);
    return false;
  }
}

Future<void> appUpdateApkInstallStaged(int version) async {
  if (!await appUpdateApkStagedReady(version)) return;
  if (!await appUpdateAndroidCanInstallApk()) {
    await appUpdateAndroidOpenInstallPermissionSettings();
    return;
  }
  final path = await appUpdateApkFilePath(version);
  await appUpdateAndroidInstallApk(path);
}

Future<void> appUpdateApkManualFetchAndInstall() async {
  await appUpdateChannelPreferApk();
  final base = await serverHostActiveBase();
  final remote = await appReleaseGet(base, platform: 'android');
  if (remote == null || remote.apkUrl.isEmpty) return;
  AppUpdateService.instance.setAndroidApkDownloading(remote, force: false);
  final ok = await appUpdateApkDownloadStage(
    remote,
    onProgress: (p) => AppUpdateService.instance.setAndroidApkProgress(remote, p, force: false),
  );
  if (!ok) {
    AppUpdateService.instance.setAndroidApkFailed(remote, 'Download or verify failed');
    return;
  }
  AppUpdateService.instance.setAndroidApkReady(remote, force: false);
  await appUpdateApkInstallStaged(remote.version);
}

Future<void> _downloadApkRelease(AppRelease release) async {
  final force = AppUpdateService.instance.state.value.phase == AppUpdatePhase.forceRequired;
  AppUpdateService.instance.setAndroidApkDownloading(release, force: force);
  final ok = await appUpdateApkDownloadStage(
    release,
    onProgress: (p) => AppUpdateService.instance.setAndroidApkProgress(release, p, force: force),
  );
  if (!ok) {
    AppUpdateService.instance.setAndroidApkFailed(release, 'Download or verify failed');
    return;
  }
  AppUpdateService.instance.setAndroidApkReady(release, force: force);
}
