import 'package:flutter/foundation.dart';

import 'web_notif_stub.dart' if (dart.library.html) 'web_notif_web.dart' as impl;

/// Browser `Notification` API when the tab is hidden (web only).
class WebNotif {
  WebNotif._();

  static Future<void> post({
    required String title,
    required String body,
    required String routeJson,
    void Function(String routeJson)? onTap,
  }) async {
    if (!kIsWeb) return;
    await impl.webNotifPost(title: title, body: body, routeJson: routeJson, onTap: onTap);
  }
}
