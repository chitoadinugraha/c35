import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/update/app_update_service.dart';
import 'package:flutter/foundation.dart';

Timer? _appUpdateNudgeDebounce;
DateTime? _appUpdateNudgeLastHandled;

/// WS [AppReleaseNudge] from server (NATS `c35.release.windows`).
void appUpdateOnReleaseNudge(AppReleaseNudge nudge) {
  if (kIsWeb || kDebugMode || !Platform.isWindows) return;
  if (nudge.platform.isNotEmpty && nudge.platform != 'windows') return;

  final now = DateTime.now();
  if (_appUpdateNudgeLastHandled != null &&
      now.difference(_appUpdateNudgeLastHandled!) < const Duration(seconds: 2)) {
    return;
  }

  _appUpdateNudgeDebounce?.cancel();
  _appUpdateNudgeDebounce = Timer(const Duration(milliseconds: 250), () {
    _appUpdateNudgeLastHandled = DateTime.now();
    unawaited(AppUpdateService.instance.checkNow());
  });
}
