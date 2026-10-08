import 'package:flutter/foundation.dart';

import 'package:alienai_c35/core/notify/fcm_mobile.dart';

/// Flip when `clients/app/android/app/google-services.json` is added.
/// Missing credentials must not call Firebase.initializeApp.
const kNotifyFcmCredentials = false;

Future<String?> fcmBind(void Function(Map<String, String> data) onData) async {
  if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
    return null;
  }
  if (!kNotifyFcmCredentials) return null;
  // ignore: dead_code
  return fcmMobileStart(onData);
}
