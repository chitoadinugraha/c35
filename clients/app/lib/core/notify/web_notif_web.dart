// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Future<void> webNotifPost({
  required String title,
  required String body,
  required String routeJson,
  void Function(String routeJson)? onTap,
}) async {
  if (!html.Notification.supported) return;
  if (html.document.visibilityState == 'visible') return;
  final perm = await html.Notification.requestPermission();
  if (perm != 'granted') return;
  final n = html.Notification(
    title.isEmpty ? 'Notification' : title,
    body: body.isEmpty ? null : body,
    tag: routeJson.hashCode.toString(),
  );
  n.onClick.listen((_) {
    html.window.focus();
    onTap?.call(routeJson);
  });
}
