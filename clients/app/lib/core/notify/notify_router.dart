import 'package:alienai_c35/core/notify/local_notif.dart';
import 'package:alienai_c35/widgets/notify/ui_notify_banner.dart';

/// Chooses in-app banner or local notification from the app resumed flag.
///
/// Resumed: banner only. Not resumed: local notification only. Never both.
class NotifyRouter {
  static LocalNotifPort localPort = LocalNotif.instance;

  /// Foreground flag the shell updates from the app lifecycle.
  static bool appResumed = true;

  /// Test hook. When set, [show] calls this instead of inserting the banner.
  static void Function(String title, String body, String routeJson)? onBanner;

  /// How many times the banner path ran. Tests assert this stays 0 when backgrounded.
  static int bannerCalls = 0;

  static Future<void> Function(int id)? markRead;
  static void Function(String routeJson)? openRoute;

  static Future<void> show(String title, String body, String routeJson, {required bool resumed, int? id}) async {
    if (resumed) {
      bannerCalls++;
      final hook = onBanner;
      if (hook != null) {
        hook(title, body, routeJson);
        return;
      }
      UiNotifyBanner.show(
        title: title,
        body: body,
        routeJson: routeJson,
        onTap: () {
          if (id != null && id > 0) {
            final mark = markRead;
            if (mark != null) {
              mark(id);
            }
          }
          openRoute?.call(routeJson);
        },
      );
      return;
    }
    if (localPort is LocalNotif) {
      LocalNotif.instance.onOpened = (route) => openRoute?.call(route);
    }
    await localPort.post(title: title, body: body, routeJson: routeJson);
  }

  /// Data-only FCM payload (type=user_notify) while this process is alive.
  static void deliverFcm(Map<String, String> data, {bool? resumed}) {
    if ((data['type'] ?? '') != 'user_notify') return;
    final id = int.tryParse(data['notify_id'] ?? '');
    show(
      data['title'] ?? '',
      data['body'] ?? '',
      data['route_json'] ?? '',
      resumed: resumed ?? appResumed,
      id: id,
    );
  }
}
