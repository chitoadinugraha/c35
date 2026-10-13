import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('id.alienai/app_update');

Future<bool> appUpdateAndroidCanInstallApk() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final v = await _channel.invokeMethod<bool>('canInstallApk');
    return v == true;
  } catch (_) {
    return false;
  }
}

Future<void> appUpdateAndroidOpenInstallPermissionSettings() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  } catch (_) {}
}

Future<bool> appUpdateAndroidInstallApk(String path) async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final v = await _channel.invokeMethod<bool>('installApk', {'path': path});
    return v == true;
  } catch (_) {
    return false;
  }
}
