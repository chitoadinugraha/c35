import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_download.dart';
import 'package:alienai_c35/c/update/app_update_install.dart';
import 'package:flutter/foundation.dart';

enum AppUpdatePhase { idle, checking, downloading, ready, failed, upToDate, forceRequired }

class AppUpdateState {
  const AppUpdateState({this.phase = AppUpdatePhase.idle, this.release, this.progress = 0, this.error = ''});
  final AppUpdatePhase phase;
  final AppRelease? release;
  final double progress;
  final String error;

  AppUpdateState copyWith({AppUpdatePhase? phase, AppRelease? release, double? progress, String? error}) =>
      AppUpdateState(phase: phase ?? this.phase, release: release ?? this.release, progress: progress ?? this.progress, error: error ?? this.error);

  @override
  bool operator ==(Object other) =>
      other is AppUpdateState &&
      other.phase == phase &&
      other.progress == progress &&
      other.error == error &&
      other.release?.version == release?.version &&
      other.release?.hash == release?.hash;

  @override
  int get hashCode => Object.hash(phase, release?.version, release?.hash, progress, error);
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  final ValueNotifier<AppUpdateState> state = ValueNotifier(const AppUpdateState());
  Timer? _timer;
  Timer? _idleTimer;
  var _busy = false;
  var _countdownActive = false;
  DateTime _lastUserActivity = DateTime.now();
  Future<void> Function()? _androidCheck;
  bool Function()? _isBusy;
  void Function(AppRelease release)? _autoUpdatePrompt;

  void registerAndroidCheck(Future<void> Function()? check) => _androidCheck = check;
  void registerBusyCheck(bool Function()? isBusy) => _isBusy = isBusy;
  void registerAutoUpdatePrompt(void Function(AppRelease release)? prompt) => _autoUpdatePrompt = prompt;

  void recordUserActivity() => _lastUserActivity = DateTime.now();

  void postponeAutoUpdate([Duration duration = const Duration(minutes: 15)]) {
    _countdownActive = false;
    _lastUserActivity = DateTime.now().add(duration - const Duration(minutes: 5));
  }

  void countdownDismissed() {
    _countdownActive = false;
    _lastUserActivity = DateTime.now();
  }

  void start() {
    if (!Platform.isWindows || kDebugMode) return;
    _timer?.cancel();
    _idleTimer?.cancel();
    unawaited(checkNow());
    _timer = Timer.periodic(const Duration(hours: 6), (_) => checkNow());
    _idleTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkIdleAutoUpdate());
  }

  void dispose() {
    _timer?.cancel();
    _idleTimer?.cancel();
  }

  void _checkIdleAutoUpdate() {
    if (_countdownActive) return;
    final s = state.value;
    if (s.phase != AppUpdatePhase.ready || s.release == null) return;
    if (_isBusy?.call() == true) return;
    final idle = DateTime.now().difference(_lastUserActivity);
    if (idle >= const Duration(minutes: 5)) {
      _countdownActive = true;
      if (_autoUpdatePrompt != null) {
        _autoUpdatePrompt!(s.release!);
      } else {
        installNow();
      }
    }
  }

  void _setState(AppUpdateState next) {
    if (state.value == next) return;
    state.value = next;
  }

  String statusLabel() {
    final s = state.value;
    return switch (s.phase) {
      AppUpdatePhase.checking => 'Checking for updates…',
      AppUpdatePhase.downloading => 'Downloading update… ${(s.progress * 100).round()}%',
      AppUpdatePhase.ready => '${s.release?.label ?? 'Update'} ready',
      AppUpdatePhase.forceRequired => 'Update required',
      AppUpdatePhase.failed => s.error.isEmpty ? 'Update check failed' : s.error,
      AppUpdatePhase.upToDate => 'Up to date',
      AppUpdatePhase.idle => '',
    };
  }

  Future<void> checkNow() async {
    if (kDebugMode) return;
    if (Platform.isAndroid) {
      await _androidCheck?.call();
      return;
    }
    if (!Platform.isWindows || _busy) return;
    _busy = true;
    try {
      final local = appReleaseLocalVersion();
      final base = await serverHostActiveBase();
      final release = await appReleaseGet(base, platform: 'windows');
      if (release == null) {
        _setState(state.value.copyWith(phase: AppUpdatePhase.failed, error: 'Could not reach update server'));
        return;
      }
      if (appReleaseForceUpdate(local: local, remote: release)) {
        _setState(AppUpdateState(phase: AppUpdatePhase.forceRequired, release: release));
        await _downloadRelease(release);
        return;
      }
      if (!appReleaseNeedsUpdate(local: local, remote: release)) {
        _setState(state.value.copyWith(phase: AppUpdatePhase.upToDate, release: release));
        return;
      }
      if (appUpdateStagedReady(release.version)) {
        _setState(AppUpdateState(phase: AppUpdatePhase.ready, release: release, progress: 1));
        return;
      }
      _setState(state.value.copyWith(phase: AppUpdatePhase.checking, error: ''));
      await _downloadRelease(release);
    } catch (e) {
      lError(e);
      _setState(state.value.copyWith(phase: AppUpdatePhase.failed, error: '$e'));
    } finally {
      _busy = false;
    }
  }

  Future<void> _downloadRelease(AppRelease release) async {
    final force = state.value.phase == AppUpdatePhase.forceRequired;
    _setState(AppUpdateState(phase: force ? AppUpdatePhase.forceRequired : AppUpdatePhase.downloading, release: release));
    final ok = await appUpdateDownloadVerify(
      release: release,
      onProgress: (p) {
        final phase = force ? AppUpdatePhase.forceRequired : AppUpdatePhase.downloading;
        _setState(AppUpdateState(phase: phase, release: release, progress: p));
      },
    );
    if (!ok) {
      _setState(AppUpdateState(phase: AppUpdatePhase.failed, release: release, error: 'Download or verify failed'));
      return;
    }
    _setState(AppUpdateState(phase: force ? AppUpdatePhase.forceRequired : AppUpdatePhase.ready, release: release, progress: 1));
  }

  Future<void> installNow() async {
    final release = state.value.release;
    if (release == null) return;
    if (!appUpdateStagedReady(release.version)) {
      await _downloadRelease(release);
      if (!appUpdateStagedReady(release.version)) return;
    }
    await appUpdateInstallStaged(release.version);
  }
}
