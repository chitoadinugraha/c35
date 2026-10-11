import 'dart:io';

import 'package:flutter/foundation.dart';

/// `play` / `store` — Google Play AAB (in-app billing only).
/// `direct` / `apk` / `cas` / `sideload` — CAS APK / sideload (Midtrans + transfer allowed).
/// Empty on Android release defaults to Play compliance (legacy).
const _billingDistribution = String.fromEnvironment('C35_BILLING_DISTRIBUTION', defaultValue: '');

/// Android Play vs direct distribution (compile-time from [C35_BILLING_DISTRIBUTION]).
bool billingAndroidStoreCheckoutFromDefine(String distribution, bool releaseMode) {
  final d = distribution.trim().toLowerCase();
  if (d == 'play' || d == 'store') return true;
  if (d == 'direct' || d == 'apk' || d == 'cas' || d == 'sideload') return false;
  return releaseMode;
}

bool _androidPlayStoreDistribution() =>
    billingAndroidStoreCheckoutFromDefine(_billingDistribution, kReleaseMode);

/// Google Play / App Store in-app checkout (mobile store builds).
bool billingUseNativeStoreCheckout() {
  if (kIsWeb) return false;
  if (Platform.isIOS) return kReleaseMode;
  if (Platform.isAndroid) return _androidPlayStoreDistribution();
  return false;
}

/// Subscription plans via native store (not wallet / Midtrans).
bool billingUsePlayPlans() => billingUseNativeStoreCheckout();

/// Legacy alias.
bool billingUsePlayCheckout() => billingUseNativeStoreCheckout();

/// Midtrans, Stripe, and manual bank transfer top-up UI.
bool billingShowInAppTopup() {
  if (kIsWeb) return true;
  if (Platform.isIOS) return false;
  if (Platform.isAndroid) return !_androidPlayStoreDistribution();
  return true;
}

String billingNativeStoreLabel() {
  if (kIsWeb) return 'Store';
  if (Platform.isIOS) return 'App Store';
  if (Platform.isAndroid) return 'Google Play';
  return 'Store';
}
