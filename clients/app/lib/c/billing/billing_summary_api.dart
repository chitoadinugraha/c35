import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Future<ResBillingSummary> billingSummaryGet(ReferralConn conn, {Int64 billingAccountId = Int64.ZERO}) async {
  final res = await conn.invoke(
    InvokeReq(reqId: const Uuid().v4(), billingSummary: ReqBillingSummary(billingAccountId: billingAccountId)),
    timeout: const Duration(seconds: 15),
  );
  invokeResThrow(res, fallback: 'Failed to load billing summary');
  if (!res.hasBillingSummary()) throw 'No billing summary data';
  return res.billingSummary;
}

BillingAccount billingAccountFromSummary(ResBillingSummary summary, {BillingAccount? base}) {
  final currency = billingCurrencyResolve(
    fromAccount: base?.billingCurrency,
    fromSummary: summary.hasBillingCurrency() ? summary.billingCurrency : null,
  );
  final fx = summary.hasFxMicroPerUsd()
      ? summary.fxMicroPerUsd
      : (base?.hasFxMicroPerUsd() == true ? base!.fxMicroPerUsd : Int64(moneyDefaultFxMicroPerUsd));
  final b = base;
  final account = BillingAccount(
    id: base?.id ?? Int64.ZERO,
    ownerIid: base?.ownerIid ?? Int64.ZERO,
    name: base?.name ?? '',
    balanceUsd: summary.balanceUsd,
    balanceIdr: summary.balanceIdr,
    planTier: summary.planTier.isNotEmpty ? summary.planTier : (base?.planTier ?? 'free'),
    alienAllow5hUsed: summary.alienAllow5hUsed,
    alienAllow5hLimit: summary.alienAllow5hLimit,
    alienAllowWeeklyUsed: summary.alienAllowWeeklyUsed,
    alienAllowWeeklyLimit: summary.alienAllowWeeklyLimit,
    frontierAllow5hUsed: summary.frontierAllow5hUsed > 0 ? summary.frontierAllow5hUsed : (b?.frontierAllow5hUsed ?? 0),
    frontierAllow5hLimit: summary.frontierAllow5hLimit,
    frontierAllowWeeklyUsed: summary.frontierAllowWeeklyUsed > 0 ? summary.frontierAllowWeeklyUsed : (b?.frontierAllowWeeklyUsed ?? 0),
    frontierAllowWeeklyLimit: summary.frontierAllowWeeklyLimit,
    commissionAvailableUsd: summary.commissionAvailableUsd,
    commissionAvailableIdr: summary.commissionAvailableIdr,
    freemiumActive: summary.freemiumActive,
    freemiumMsgsUsed: summary.freemiumMsgsUsed,
    freemiumMsgsLimit: summary.freemiumMsgsLimit,
    freemiumTokensUsed: summary.freemiumTokensUsed,
    freemiumTokensLimit: summary.freemiumTokensLimit,
    planExpiresTsMs: summary.planExpiresTsMs,
    trialExpiresTsMs: summary.trialExpiresTsMs,
    billingCurrency: currency,
    fxMicroPerUsd: fx,
    commissionEarnedUsd: base?.commissionEarnedUsd ?? 0,
    commissionEarnedIdr: base?.commissionEarnedIdr ?? 0,
    window5hStartMs: base?.window5hStartMs ?? Int64.ZERO,
    windowWeeklyStartMs: base?.windowWeeklyStartMs ?? Int64.ZERO,
    updatedTsMs: base?.updatedTsMs ?? Int64.ZERO,
    createdTsMs: base?.createdTsMs ?? Int64.ZERO,
    metaJson: base?.metaJson ?? '{}',
  );
  return billingAccountPackageReconcile(account);
}
