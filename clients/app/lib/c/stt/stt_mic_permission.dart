import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> sttMicPermissionEnsure() async {
  if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
  try {
    final status = await Permission.microphone.request();
    return status.isGranted;
  } catch (_) {
    return true;
  }
}

Future<bool> sttMicPermissionGranted() async {
  if (kIsWeb || Platform.isWindows || Platform.isLinux) return true;
  try {
    return (await Permission.microphone.status).isGranted;
  } catch (_) {
    return true;
  }
}

@visibleForTesting
String sttMicErrorMessageForPlatform({
  required bool isWeb,
  required bool isWindows,
  required bool isAndroid,
  required bool isIOS,
  required bool isMacOS,
  Object? cause,
}) {
  final raw = cause?.toString().trim() ?? '';
  if (raw.isNotEmpty && !raw.toLowerCase().contains('permission')) return raw;
  if (!isWeb && isWindows) {
    return 'Microphone access is blocked or unavailable. Open Settings → Privacy & security → Microphone, '
        'turn on "Microphone access", and ensure a microphone is connected.';
  }
  if (!isWeb && isAndroid) {
    return 'Microphone permission required. Allow microphone access for Alien AI in app settings.';
  }
  if (!isWeb && isIOS) {
    return 'Microphone permission required. Enable Microphone for Alien AI in Settings.';
  }
  if (!isWeb && isMacOS) {
    return 'Microphone permission required. Enable Microphone for Alien AI in System Settings → Privacy & Security.';
  }
  if (isWeb) {
    return 'Microphone blocked or unavailable. Open site settings in the browser address bar, allow microphone access for this site, then try again.';
  }
  return 'Microphone permission required for voice input.';
}

String sttMicErrorMessage({Object? cause}) {
  if (kIsWeb) {
    return sttMicErrorMessageForPlatform(
      isWeb: true,
      isWindows: false,
      isAndroid: false,
      isIOS: false,
      isMacOS: false,
      cause: cause,
    );
  }
  return sttMicErrorMessageForPlatform(
    isWeb: false,
    isWindows: Platform.isWindows,
    isAndroid: Platform.isAndroid,
    isIOS: Platform.isIOS,
    isMacOS: Platform.isMacOS,
    cause: cause,
  );
}
