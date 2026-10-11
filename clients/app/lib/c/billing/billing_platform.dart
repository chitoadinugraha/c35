import 'dart:io';

import 'package:flutter/foundation.dart';

/// Google Play / App Store in-app checkout (mobile release builds).
bool billingUseNativeStoreCheckout() => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Subscription plans via native store (not wallet / Midtrans).
bool billingUsePlayPlans() => billingUseNativeStoreCheckout();

/// Legacy alias.
bool billingUsePlayCheckout() => billingUseNativeStoreCheckout();

/// QRIS / bank / web top-up UI (forbidden on mobile release — no external purchase steering).
bool billingShowInAppTopup() =>
    !kIsWeb && (!billingUseNativeStoreCheckout() || (!kReleaseMode && Platform.isAndroid));

String billingNativeStoreLabel() {
  if (kIsWeb) return 'Store';
  if (Platform.isIOS) return 'App Store';
  if (Platform.isAndroid) return 'Google Play';
  return 'Store';
}
