// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> appUpdateWebHardRefresh() async {
  try {
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final regs = await sw.getRegistrations();
      for (final reg in regs) {
        await reg.unregister();
      }
    }
  } catch (_) {}

  try {
    final caches = html.window.caches;
    if (caches != null) {
      final keys = await caches.keys();
      for (final key in keys) {
        await caches.delete(key);
      }
    }
  } catch (_) {}

  html.window.location.reload();
}
