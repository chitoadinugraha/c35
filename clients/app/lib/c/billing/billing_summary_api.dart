import 'package:alienai_c35/c/api/referral_conn.dart';
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

BillingAccount billingAccountFromSummary(ResBillingSummary summary) => BillingAccount(
      balanceUsd: summary.balanceUsd,
      balanceIdr: summary.balanceIdr,
      planTier: summary.planTier.isNotEmpty ? summary.planTier : 'free',
      alienAllow5hUsed: summary.alienAllow5hUsed,
      alienAllow5hLimit: summary.alienAllow5hLimit,
      alienAllowWeeklyUsed: summary.alienAllowWeeklyUsed,
      alienAllowWeeklyLimit: summary.alienAllowWeeklyLimit,
      commissionAvailableUsd: summary.commissionAvailableUsd,
      commissionAvailableIdr: summary.commissionAvailableIdr,
      freemiumActive: summary.freemiumActive,
      freemiumMsgsUsed: summary.freemiumMsgsUsed,
      freemiumMsgsLimit: summary.freemiumMsgsLimit,
      freemiumTokensUsed: summary.freemiumTokensUsed,
      freemiumTokensLimit: summary.freemiumTokensLimit,
      planExpiresTsMs: summary.planExpiresTsMs,
      trialExpiresTsMs: summary.trialExpiresTsMs,
      billingCurrency: summary.balanceIdr > 0 ? 'IDR' : (summary.balanceUsd > 0 ? 'USD' : moneyDefaultCurrency),
    );
