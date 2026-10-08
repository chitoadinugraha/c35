import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:alienai_c35/core/notify/notify_router.dart';

/// Android/iOS data messages. Not called while [kNotifyFcmCredentials] is false.
Future<String?> fcmMobileStart(void Function(Map<String, String> data) onData) async {
  FirebaseMessaging.onBackgroundMessage(fcmUserNotifyBackground);
  await Firebase.initializeApp();
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  FirebaseMessaging.onMessage.listen((message) {
    onData(_dataOf(message));
  });
  return messaging.getToken();
}

@pragma('vm:entry-point')
Future<void> fcmUserNotifyBackground(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotifyRouter.deliverFcm(_dataOf(message), resumed: false);
}

Map<String, String> _dataOf(RemoteMessage message) => {
      for (final entry in message.data.entries) entry.key: '${entry.value}',
    };
