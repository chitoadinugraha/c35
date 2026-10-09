import 'dart:async';

import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Pending POS deep link until Home can open [sitePosOpen].
class PosLink {
  static String? pending;
  static final List<VoidCallback> _listeners = [];
  static var _bound = false;
  static String? _lastId;
  static DateTime? _lastAt;

  static void listen(VoidCallback cb) => _listeners.add(cb);

  static void unlisten(VoidCallback cb) => _listeners.remove(cb);

  static void offer(String siteIid) {
    final id = siteIid.trim();
    if (id.isEmpty) return;
    final now = DateTime.now();
    if (_lastId == id && _lastAt != null && now.difference(_lastAt!) < const Duration(seconds: 2)) return;
    _lastId = id;
    _lastAt = now;
    pending = id;
    for (final cb in List<VoidCallback>.of(_listeners)) {
      cb();
    }
  }
}

Future<void> posLinkBind() async {
  if (PosLink._bound) return;
  PosLink._bound = true;
  final links = AppLinks();
  try {
    final initial = await links.getInitialLink();
    final id = initial == null ? null : posSiteIidFromUri(initial);
    if (id != null) PosLink.offer(id);
  } catch (e) {
    debugPrint('pos link initial: $e');
  }
  links.uriLinkStream.listen((uri) {
    final id = posSiteIidFromUri(uri);
    if (id != null) PosLink.offer(id);
  }, onError: (Object e) {
    debugPrint('pos link: $e');
  });
}
