import 'dart:io';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

String billingPlayStorePlatformWire() {
  if (kIsWeb) return '';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return '';
}

Future<ResBillingPlayProductList> billingPlayProductList(ReferralConn conn, {String? currency}) async {
  final cur = (currency ?? billingCurrencyForDeviceLocale()).trim().toUpperCase();
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingPlayProductList: ReqBillingPlayProductList(currency: cur == 'USD' ? 'USD' : 'IDR'),
    ),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load Play products');
  if (!res.hasBillingPlayProductList()) throw 'No Play product list response';
  return res.billingPlayProductList;
}

Future<ResBillingPlayVerify> billingPlayVerify(
  ReferralConn conn, {
  required String productId,
  required String purchaseToken,
  String packageName = '',
}) async {
  final res = await conn.invoke(
    InvokeReq(
      reqId: const Uuid().v4(),
      billingPlayVerify: ReqBillingPlayVerify(
        productId: productId,
        purchaseToken: purchaseToken,
        packageName: packageName,
        storePlatform: billingPlayStorePlatformWire(),
      ),
    ),
    timeout: const Duration(seconds: 45),
  );
  invokeResThrow(res, fallback: 'Failed to verify Play purchase');
  if (!res.hasBillingPlayVerify()) throw 'No Play verify response';
  return res.billingPlayVerify;
}
