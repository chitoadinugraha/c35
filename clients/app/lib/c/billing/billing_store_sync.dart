import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:fixnum/fixnum.dart';

@Deprecated('Use NATS push for balance updates; direct store writes for plan changes.')
Future<BillingAccount> billingStoreRefresh(ReferralConn conn) async {
  final summary = await billingSummaryGet(conn);
  final account = billingAccountFromSummary(summary, base: AppStore.instance.billing);
  AppStore.instance.billingPut(account, force: true);
  return account;
}

BillingAccount billingAccountApplyPlanChange(BillingAccount base, ResBillingPlanChange change) {
  final out = base.deepCopy();
  out.planTier = change.planTier.isNotEmpty ? change.planTier : out.planTier;
  out.balanceUsd = change.balanceUsd;
  out.balanceIdr = change.balanceIdr;
  out.alienAllow5hLimit = change.alienAllow5hLimit;
  out.alienAllowWeeklyLimit = change.alienAllowWeeklyLimit;
  if (change.hasPlanExpiresTsMs()) out.planExpiresTsMs = change.planExpiresTsMs;
  out.updatedTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
  return out;
}

Future<ResBillingPlanChange> billingPlanChangeAndSync(
  ReferralConn conn, {
  required String planSlug,
  String billingPeriod = 'monthly',
  String currency = 'IDR',
}) async {
  final change = await billingPlanChange(conn, planSlug: planSlug, billingPeriod: billingPeriod, currency: currency);
  final base = AppStore.instance.billing ?? BillingAccount(billingCurrency: currency);
  AppStore.instance.billingPut(billingAccountApplyPlanChange(base, change), force: true);
  // v2: billing_profile/wallet updated via NATS push after server applies change.
  return change;
}

Future<ResBillingPackageRedeem> billingPackageRedeemAndSync(ReferralConn conn, {required String code}) async {
  final redeem = await billingPackageRedeem(conn, code: code);
  try {
    await billingStoreRefresh(conn);
  } catch (_) {}
  return redeem;
}

