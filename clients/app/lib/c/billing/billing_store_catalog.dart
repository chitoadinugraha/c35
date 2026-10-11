import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';

double billingStoreProductPrice(BillingPlayProductDoc product) {
  if (product.storePrice > 0) return product.storePrice;
  if (product.playPriceIdr > 0) return product.playPriceIdr;
  if (product.webPrice > 0) return product.webPrice;
  return product.webPriceIdr;
}

String billingStoreProductPriceLabel(BillingPlayProductDoc product, {required String currency}) {
  final cur = (product.currency.trim().isNotEmpty ? product.currency : currency).toUpperCase();
  final amount = billingStoreProductPrice(product);
  if (amount <= 0) return '—';
  if (cur == 'IDR') return billingFmtRp(amount);
  return moneyFmtUsd(amount);
}

BillingPlayProductDoc? billingStorePlanProduct(
  List<BillingPlayProductDoc> products, {
  required BillingPlanDoc plan,
  required bool yearly,
}) {
  final slug = plan.slug.trim().toLowerCase();
  final period = yearly ? 'yearly' : 'monthly';
  for (final p in products) {
    if (p.kind != 'plan') continue;
    if (p.planSlug.trim().toLowerCase() == slug && p.billingPeriod.trim().toLowerCase() == period) {
      return p;
    }
  }
  return null;
}

double billingStorePlanListPrice({
  required BillingPlanDoc plan,
  required bool yearly,
  required String currency,
  List<BillingPlayProductDoc> storeProducts = const [],
}) {
  final store = billingStorePlanProduct(storeProducts, plan: plan, yearly: yearly);
  if (store != null) return billingStoreProductPrice(store);
  return billingPlanPriceAmount(plan, currency: currency, yearly: yearly);
}

String billingStorePlanPriceLabel({
  required BillingPlanDoc plan,
  required bool yearly,
  required String currency,
  List<BillingPlayProductDoc> storeProducts = const [],
}) {
  final amount = billingStorePlanListPrice(
    plan: plan,
    yearly: yearly,
    currency: currency,
    storeProducts: storeProducts,
  );
  if (amount <= 0) return '—';
  if (currency.toUpperCase() == 'IDR') return '${billingFmtRp(amount)}/mo';
  return '\$${amount.toStringAsFixed(amount >= 10 ? 0 : 2)}/mo';
}
