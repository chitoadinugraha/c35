import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_play_api.dart';
import 'package:alienai_c35/c/billing/billing_store_sync.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Generates all potential candidate product IDs across naming conventions
/// (e.g., with/without package prefix, underscores, short slug).
List<String> billingPlayProductCandidateIds(String productId) {
  final clean = productId.trim();
  final set = <String>{clean};

  final withoutPrefix = clean.replaceFirst('id.alienai.', '');
  set.add(withoutPrefix);

  if (clean.contains('.plan.')) {
    final parts = clean.split('.');
    if (parts.length >= 4) {
      final slug = parts[parts.length - 2].toLowerCase();
      final period = parts.last.toLowerCase();
      set.add('plan.$slug.$period');
      set.add('plan_${slug}_$period');
      set.add('$slug.$period');
      set.add('${slug}_$period');
      set.add('plan.$slug');
      set.add('plan_$slug');
      set.add(slug);
    }
  } else if (clean.contains('.credit.')) {
    final amountStr = clean.split('.').last;
    final amount = int.tryParse(amountStr) ?? 0;
    set.add('credit.$amountStr');
    set.add('credit_$amountStr');
    set.add(amountStr);
    if (amount >= 1000) {
      final k = '${amount ~/ 1000}k';
      set.add('id.alienai.credit.$k');
      set.add('credit.$k');
      set.add('credit_$k');
    }
  }
  return set.toList();
}

ProductDetails? billingPlayProductDetailsPick(ProductDetailsResponse catalog, List<String> candidateIds) {
  // 1. Exact match with active offerToken (subscriptions)
  for (final id in candidateIds) {
    for (final p in catalog.productDetails) {
      if (p.id == id && p is GooglePlayProductDetails && (p.offerToken ?? '').isNotEmpty) {
        return p;
      }
    }
  }
  // 2. Exact match
  for (final id in candidateIds) {
    for (final p in catalog.productDetails) {
      if (p.id == id) return p;
    }
  }
  // 3. Suffix match
  for (final p in catalog.productDetails) {
    for (final id in candidateIds) {
      if (p.id.endsWith(id) || id.endsWith(p.id)) return p;
    }
  }
  return catalog.productDetails.isNotEmpty ? catalog.productDetails.first : null;
}

Future<ResBillingPlayVerify> billingPlayPurchaseAndVerify(
  ReferralConn conn, {
  required BillingPlayProductDoc product,
}) async {
  final iap = InAppPurchase.instance;
  if (!await iap.isAvailable()) {
    throw 'Google Play Billing is not available on this device.\n'
        'Check that Google Play Store is installed, updated, and signed into a Google account.';
  }
  final productId = product.productId.trim();
  if (productId.isEmpty) throw 'Missing Play product id';

  final candidates = billingPlayProductCandidateIds(productId);
  final catalog = await iap.queryProductDetails(candidates.toSet());
  if (catalog.error != null) throw catalog.error!.message;

  final details = billingPlayProductDetailsPick(catalog, candidates);
  if (details == null) {
    final missing = catalog.notFoundIDs.isEmpty ? candidates.join(', ') : catalog.notFoundIDs.join(', ');
    throw 'Subscription or product not found in Google Play ($missing).\n'
        'Check that SKU "$productId" is set to Active in Google Play Console (id.alienai), '
        'and your Google account is added as a License Tester under Setup → License testing.';
  }

  final purchase = await _awaitPurchase(iap, details, product.kind == 'credit');
  final token = purchase.verificationData.serverVerificationData.trim().isNotEmpty
      ? purchase.verificationData.serverVerificationData
      : purchase.verificationData.localVerificationData;
  if (token.trim().isEmpty) throw 'Missing purchase token from Google Play';

  // Send the actual matched Google Play product ID to backend verification
  final verified = await billingPlayVerify(conn, productId: details.id, purchaseToken: token);
  if (purchase.pendingCompletePurchase) await iap.completePurchase(purchase);
  await billingStoreRefresh(conn);
  return verified;
}

Future<PurchaseDetails> _awaitPurchase(InAppPurchase iap, ProductDetails details, bool consumable) async {
  final completer = Completer<PurchaseDetails>();
  late final StreamSubscription<List<PurchaseDetails>> sub;
  sub = iap.purchaseStream.listen((purchases) {
    for (final p in purchases) {
      final matches = p.productID == details.id ||
          details.id.endsWith(p.productID) ||
          p.productID.endsWith(details.id);
      if (!matches) continue;
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
  }, onError: (Object err) {
    if (!completer.isCompleted) completer.completeError(err);
  });

  try {
    final param = details is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(productDetails: details)
        : PurchaseParam(productDetails: details);
    final started = consumable ? await iap.buyConsumable(purchaseParam: param) : await iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      throw 'Could not start Google Play purchase.\n'
          'Ensure Google Play Store is up to date and signed into an active Google account.';
    }
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
