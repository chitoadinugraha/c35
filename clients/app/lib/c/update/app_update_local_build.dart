import 'dart:io';

import 'package:alienai_c35/c/update/app_release.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('id.alienai/app_update');

/// Compare against server `version` using the installed Android [versionCode] when available.
Future<int> appUpdateLocalBuild() async {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final v = await _channel.invokeMethod<int>('getBuildNumber');
      if (v != null && v > 0) return v;
    } catch (_) {}
  }
  return appReleaseLocalVersion();
}
