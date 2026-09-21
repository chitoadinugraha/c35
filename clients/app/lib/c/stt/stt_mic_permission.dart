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

String sttMicErrorMessage({Object? cause}) {
  final raw = cause?.toString().trim() ?? '';
  if (raw.isNotEmpty && !raw.toLowerCase().contains('permission')) return raw;
  if (!kIsWeb && Platform.isWindows) {
    return 'Microphone access is blocked or unavailable. Open Settings → Privacy & security → Microphone, '
        'turn on "Microphone access", and ensure a microphone is connected.';
  }
  if (!kIsWeb && Platform.isAndroid) {
    return 'Microphone permission required. Allow microphone access for Alien AI in app settings.';
  }
  if (!kIsWeb && Platform.isIOS) {
    return 'Microphone permission required. Enable Microphone for Alien AI in Settings.';
  }
  if (!kIsWeb && Platform.isMacOS) {
    return 'Microphone permission required. Enable Microphone for Alien AI in System Settings → Privacy & Security.';
  }
  return 'Microphone permission required for voice input.';
}
