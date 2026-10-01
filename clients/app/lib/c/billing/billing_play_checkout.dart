import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_play_api.dart';
import 'package:alienai_c35/c/billing/billing_store_sync.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

ProductDetails? billingPlayProductDetailsPick(ProductDetailsResponse catalog, String productId) {
  final matches = catalog.productDetails.where((p) => p.id == productId).toList();
  if (matches.isEmpty) return null;
  for (final p in matches) {
    if (p is GooglePlayProductDetails && (p.offerToken ?? '').isNotEmpty) return p;
  }
  return matches.first;
}

Future<ResBillingPlayVerify> billingPlayPurchaseAndVerify(
  ReferralConn conn, {
  required BillingPlayProductDoc product,
}) async {
  final iap = InAppPurchase.instance;
  if (!await iap.isAvailable()) throw 'Google Play Billing is not available';
  final productId = product.productId.trim();
  if (productId.isEmpty) throw 'Missing Play product id';
  final catalog = await iap.queryProductDetails({productId});
  if (catalog.error != null) throw catalog.error!.message;
  final details = billingPlayProductDetailsPick(catalog, productId);
  if (details == null) {
    final missing = catalog.notFoundIDs.isEmpty ? productId : catalog.notFoundIDs.join(', ');
    throw 'Subscription not found in Google Play ($missing). '
        'Confirm SKU "$productId" is active in Play Console for id.alienai and this app build is on internal/testing or production.';
  }

  final purchase = await _awaitPurchase(iap, details, product.kind == 'credit');
  final token = purchase.verificationData.serverVerificationData.trim().isNotEmpty
      ? purchase.verificationData.serverVerificationData
      : purchase.verificationData.localVerificationData;
  if (token.trim().isEmpty) throw 'Missing purchase token from Google Play';

  final verified = await billingPlayVerify(conn, productId: productId, purchaseToken: token);
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
    final param = details is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(productDetails: details)
        : PurchaseParam(productDetails: details);
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

List<BillingPlayProductDoc> billingPlayPlanProducts(List<BillingPlayProductDoc> products) =>
    products.where((p) => p.kind == 'plan').toList();
