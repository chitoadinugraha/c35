import 'dart:io';

import 'package:flutter/foundation.dart';

/// Google Play in-app checkout (production Android builds only).
bool billingUsePlayCheckout() => !kIsWeb && Platform.isAndroid && kReleaseMode;

/// Subscription plans via Play (not wallet top-up).
bool billingUsePlayPlans() => billingUsePlayCheckout();
