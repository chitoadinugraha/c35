import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_play_api.dart';
import 'package:alienai_c35/c/billing/billing_store_sync.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

Future<ResBillingPlayVerify> billingPlayPurchaseAndVerify(
  ReferralConn conn, {
  required BillingPlayProductDoc product,
  Set<String>? queryIds,
}) async {
  final iap = InAppPurchase.instance;
  if (!await iap.isAvailable()) throw 'Google Play Billing is not available';
  final ids = queryIds ?? {product.productId};
  final catalog = await iap.queryProductDetails(ids);
  if (catalog.error != null) throw catalog.error!.message;
  final details = catalog.productDetails.where((p) => p.id == product.productId).firstOrNull;
  if (details == null) throw 'Product not found in Play Store (${product.productId})';

  final purchase = await _awaitPurchase(iap, details, product.kind == 'credit');
  final token = purchase.verificationData.serverVerificationData.trim().isNotEmpty
      ? purchase.verificationData.serverVerificationData
      : purchase.verificationData.localVerificationData;
  if (token.trim().isEmpty) throw 'Missing purchase token from Google Play';

  final verified = await billingPlayVerify(conn, productId: product.productId, purchaseToken: token);
  if (purchase.pendingCompletePurchase) await iap.completePurchase(purchase);
  if (verified.balanceIdr > 0) await billingStoreRefresh(conn);
  return verified;
}

Future<PurchaseDetails> _awaitPurchase(InAppPurchase iap, ProductDetails details, bool consumable) async {
  final completer = Completer<PurchaseDetails>();
  late final StreamSubscription<List<PurchaseDetails>> sub;
  sub = iap.purchaseStream.listen((purchases) {
    for (final p in purchases) {
      if (p.productID != details.id) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!completer.isCompleted) completer.complete(p);
        case PurchaseStatus.error:
          if (!completer.isCompleted) completer.completeError(p.error?.message ?? 'Purchase failed');
        case PurchaseStatus.canceled:
          if (!completer.isCompleted) completer.completeError('Purchase canceled');
        case PurchaseStatus.pending:
          break;
      }
    }
  });

  try {
    final param = PurchaseParam(productDetails: details);
    final started = consumable ? await iap.buyConsumable(purchaseParam: param) : await iap.buyNonConsumable(purchaseParam: param);
    if (!started) throw 'Could not start Google Play purchase';
    return await completer.future.timeout(const Duration(minutes: 8));
  } finally {
    await sub.cancel();
  }
}

BillingPlayProductDoc? billingPlayProductMatch(
  List<BillingPlayProductDoc> products, {
  String? planSlug,
  String? billingPeriod,
  double? creditIdr,
}) {
  for (final p in products) {
    if (creditIdr != null && p.kind == 'credit' && p.creditIdr.round() == creditIdr.round()) return p;
    if (planSlug != null &&
        p.kind == 'plan' &&
        p.planSlug.trim().toLowerCase() == planSlug.trim().toLowerCase() &&
        p.billingPeriod.trim().toLowerCase() == (billingPeriod ?? 'monthly').trim().toLowerCase()) {
      return p;
    }
  }
  return null;
}
