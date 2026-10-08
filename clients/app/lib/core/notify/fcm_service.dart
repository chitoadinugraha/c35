import 'package:flutter/foundation.dart';

import 'package:alienai_c35/core/notify/fcm_bind_stub.dart'
    if (dart.library.io) 'package:alienai_c35/core/notify/fcm_bind_io.dart';

/// FCM registration. Desktop and web no-op. Android and iOS no-op until
/// `android/app/google-services.json` exists (`kNotifyFcmCredentials`).
class FcmService {
  static Future<String?> start(void Function(Map<String, String> data) onData) {
    if (kIsWeb) return Future<String?>.value(null);
    return fcmBind(onData);
  }
}
