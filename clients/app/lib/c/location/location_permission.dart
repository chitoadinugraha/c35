import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> locationPermissionEnsure() async {
  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;
  try {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  } catch (_) {
    return false;
  }
}

Future<bool> locationPermissionGranted() async {
  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;
  try {
    return (await Permission.locationWhenInUse.status).isGranted;
  } catch (_) {
    return false;
  }
}

String locationPermissionErrorMessage({Object? cause}) {
  final raw = cause?.toString().trim() ?? '';
  if (raw.isNotEmpty && !raw.toLowerCase().contains('permission')) return raw;
  if (!kIsWeb && Platform.isAndroid) {
    return 'Location permission required. Allow location access for Alien AI in app settings.';
  }
  if (!kIsWeb && Platform.isIOS) {
    return 'Location permission required. Enable Location for Alien AI in Settings.';
  }
  return 'Location permission required for device-based recommendations.';
}
