import 'package:flutter/foundation.dart';

void l(Object msg) {
  if (kDebugMode) debugPrint('$msg');
}

void lError(Object err) {
  if (kDebugMode) debugPrint('ERR: $err');
}
