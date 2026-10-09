import 'dart:async';

import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Pending voucher code from id.alienai://voucher/CODE or /app/voucher/CODE.
class VoucherLink {
  static String? pending;
  static final List<VoidCallback> _listeners = [];
  static var _bound = false;
  static String? _lastCode;
  static DateTime? _lastAt;

  static void listen(VoidCallback cb) => _listeners.add(cb);

  static void unlisten(VoidCallback cb) => _listeners.remove(cb);

  static void offer(String code) {
    if (code.isEmpty) return;
    final now = DateTime.now();
    if (_lastCode == code && _lastAt != null && now.difference(_lastAt!) < const Duration(seconds: 2)) return;
    _lastCode = code;
    _lastAt = now;
    pending = code;
    for (final cb in List<VoidCallback>.of(_listeners)) {
      cb();
    }
  }
}

Future<void> voucherLinkBind() async {
  if (VoucherLink._bound) return;
  VoucherLink._bound = true;
  final links = AppLinks();
  try {
    final initial = await links.getInitialLink();
    final code = initial == null ? null : voucherCodeFromUri(initial);
    if (code != null) VoucherLink.offer(code);
  } catch (e) {
    debugPrint('voucher link initial: $e');
  }
  links.uriLinkStream.listen((uri) {
    final code = voucherCodeFromUri(uri);
    if (code != null) VoucherLink.offer(code);
  }, onError: (Object e) {
    debugPrint('voucher link: $e');
  });
}
