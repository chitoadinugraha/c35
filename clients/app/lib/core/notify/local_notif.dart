import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Port the router calls so tests can record posts without the plugin.
abstract class LocalNotifPort {
  Future<void> post({
    required String title,
    required String body,
    required String routeJson,
    String? category,
  });
}

/// Local shade for a backgrounded app. Desktop and web no-op; Android and iOS post.
class LocalNotif implements LocalNotifPort {
  LocalNotif._();

  static final LocalNotif instance = LocalNotif._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _seq = 0;

  /// Fired when the user taps a local notification. Payload is `route_json`.
  void Function(String routeJson)? onOpened;

  bool get _mobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  static AndroidNotificationDetails _androidDetails(String? category) {
    final cat = category?.trim().toLowerCase() ?? '';
    switch (cat) {
      case 'site_order':
        return const AndroidNotificationDetails(
          'alien_site_order',
          'Orders',
          channelDescription: 'New guest orders and POS alerts',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
      case 'mail':
        return const AndroidNotificationDetails(
          'alien_mail',
          'Mail',
          channelDescription: 'New mail messages',
          importance: Importance.high,
          priority: Priority.high,
        );
      case 'task':
        return const AndroidNotificationDetails(
          'alien_task',
          'Tasks',
          channelDescription: 'Task run finished or failed',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      default:
        return const AndroidNotificationDetails(
          'user_notify',
          'Notifications',
          channelDescription: 'Reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
        );
    }
  }

  @override
  Future<void> post({
    required String title,
    required String body,
    required String routeJson,
    String? category,
  }) async {
    if (!_mobile) return;
    await _ensure();
    _seq = (_seq + 1) & 0x7fffffff;
    await _plugin.show(
      id: _seq,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: _androidDetails(category),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: routeJson,
    );
  }

  Future<void> _ensure() async {
    if (_ready || !_mobile) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';
        if (payload.isEmpty) return;
        onOpened?.call(payload);
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }
    _ready = true;
  }
}
