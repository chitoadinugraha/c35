import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:fixnum/fixnum.dart';
const billingFreemiumMsgsLimit = 30;
const billingFreemiumTokensLimit = 30000;

const _billingPaidPlanTiers = {'lite', 'plus', 'pro', 'ultra'};

/// User-plan monthly pools: frontier_pool_idr / alien_pool_idr (same ratio all tiers).
const billingFrontierAlienPoolRatio = 0.2;

bool billingPlanTierIsPaid(String tier) => _billingPaidPlanTiers.contains(tier.trim().toLowerCase());

/// Paid signup-trial caps are 0.0125 / 0.25 — below any retail plan ring row.
bool billingAccountPaidEntitlement(BillingAccount? account) {
  if (account == null) return false;
  if (billingPlanTierIsPaid(account.planTier)) return true;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (account.hasPlanExpiresTsMs() && account.planExpiresTsMs.toInt() > now && account.alienAllow5hLimit > 0.04) {
    return true;
  }
  return account.alienAllow5hLimit >= 0.2 || account.alienAllowWeeklyLimit >= 4.0;
}

String billingPlanTierInferFromRings(double alien5h, double alienWeek) {
  if (alien5h >= 3.5 && alienWeek >= 60) return 'ultra';
  if (alien5h >= 0.75 && alienWeek >= 15) return 'pro';
  if (alien5h >= 0.15 && alienWeek >= 3) return 'plus';
  if (alien5h >= 0.04 && alienWeek >= 0.75) return 'lite';
  return 'free';
}

String billingPlanTierDisplay(BillingAccount account) {
  final reconciled = billingAccountPackageReconcile(account);
  final tier = reconciled.planTier.trim();
  return tier.isNotEmpty ? tier : 'free';
}

bool billingQuotaPushHasFrontierLimits(BillingPushQuota quota) =>
    quota.frontierAllow5hLimit > 0 || quota.frontierAllowWeeklyLimit > 0;

/// Server fallback when billing account row cannot be resolved (see billing_summary_resolve_account_id).
bool billingSummaryLooksLikeDefault(ResBillingSummary summary) =>
    summary.planTier == 'free' &&
    summary.freemiumActive &&
    summary.balanceIdr == 0 &&
    summary.balanceUsd == 0 &&
    summary.alienAllow5hLimit <= 0.05;

/// Backfill missing Frontier 5h/7d caps from Alien rings (matches server `frontier_rings_from_alien`).
({double limit5h, double limitWeekly}) billingFrontierRingLimitsDerive({
  required String planTier,
  required double alien5hLimit,
  required double alienWeeklyLimit,
  required double frontier5hLimit,
  required double frontierWeeklyLimit,
}) {
  if (frontier5hLimit > 0 || frontierWeeklyLimit > 0) {
    return (limit5h: frontier5hLimit, limitWeekly: frontierWeeklyLimit);
  }
  if (!billingPlanTierIsPaid(planTier) || (alien5hLimit <= 0 && alienWeeklyLimit <= 0)) {
    return (limit5h: frontier5hLimit, limitWeekly: frontierWeeklyLimit);
  }
  return (
    limit5h: alien5hLimit * billingFrontierAlienPoolRatio,
    limitWeekly: alienWeeklyLimit * billingFrontierAlienPoolRatio,
  );
}

BillingAccount billingAccountPackageReconcile(BillingAccount account) {
  var out = billingAccountFrontierRingsResolve(account);
  if (billingAccountPaidEntitlement(out)) {
    if (!billingPlanTierIsPaid(out.planTier)) {
      out = out.deepCopy();
      out.planTier = billingPlanTierInferFromRings(out.alienAllow5hLimit, out.alienAllowWeeklyLimit);
    }
    if (out.freemiumActive) {
      out = out.deepCopy();
      out.freemiumActive = false;
    }
  }
  return out;
}

BillingAccount billingAccountFrontierRingsResolve(BillingAccount account) {
  final derived = billingFrontierRingLimitsDerive(
    planTier: account.planTier,
    alien5hLimit: account.alienAllow5hLimit,
    alienWeeklyLimit: account.alienAllowWeeklyLimit,
    frontier5hLimit: account.frontierAllow5hLimit,
    frontierWeeklyLimit: account.frontierAllowWeeklyLimit,
  );
  if (derived.limit5h == account.frontierAllow5hLimit && derived.limitWeekly == account.frontierAllowWeeklyLimit) {
    return account;
  }
  final out = account.deepCopy();
  out.frontierAllow5hLimit = derived.limit5h;
  out.frontierAllowWeeklyLimit = derived.limitWeekly;
  return out;
}

bool billingTrialActive(BillingAccount? account) {
  if (account == null || !account.hasTrialExpiresTsMs()) return false;
  return account.trialExpiresTsMs.toInt() > DateTime.now().millisecondsSinceEpoch;
}

/// Daily free tier UI — not for paid plans, signup trial, or loading placeholders.
bool billingFreemiumActive(BillingAccount? account) {
  if (account == null) return false;
  if (billingAccountPaidEntitlement(account)) return false;
  if (billingTrialActive(account)) return false;
  return account.freemiumActive;
}

String billingFreemiumTokensShort(int tokens) {
  if (tokens >= 1000) return '${(tokens / 1000).round()}k';
  return '$tokens';
}

String billingFreemiumUsageLabel(BillingAccount account) {
  final msgLimit = account.freemiumMsgsLimit > 0 ? account.freemiumMsgsLimit : billingFreemiumMsgsLimit;
  final tokLimit = account.freemiumTokensLimit > 0 ? account.freemiumTokensLimit : billingFreemiumTokensLimit;
  return '${account.freemiumMsgsUsed}/$msgLimit msgs · ${billingFreemiumTokensShort(account.freemiumTokensUsed)}/${billingFreemiumTokensShort(tokLimit)} tokens';
}

String billingMeterStateFreemium(BillingAccount account) {
  final msgLimit = account.freemiumMsgsLimit > 0 ? account.freemiumMsgsLimit : billingFreemiumMsgsLimit;
  final tokLimit = account.freemiumTokensLimit > 0 ? account.freemiumTokensLimit : billingFreemiumTokensLimit;
  final msgPct = msgLimit > 0 ? account.freemiumMsgsUsed / msgLimit : 0.0;
  final tokPct = tokLimit > 0 ? account.freemiumTokensUsed / tokLimit : 0.0;
  final pct = msgPct > tokPct ? msgPct : tokPct;
  return billingMeterState(pct, 1);
}

String billingCurrencyResolve({String? fromAccount, String? fromSummary}) {
  for (final raw in [fromAccount, fromSummary]) {
    final c = raw?.trim().toUpperCase() ?? '';
    if (c.isNotEmpty) return c;
  }
  return moneyDefaultCurrency;
}

String billingPrimaryCurrency(BillingAccount account) => billingCurrencyResolve(fromAccount: account.billingCurrency);

List<String> billingCreditCurrencies(BillingAccount? account) {
  if (account == null) return [moneyDefaultCurrency];
  final primary = billingPrimaryCurrency(account);
  return {primary, 'IDR', 'USD'}.toList();
}

List<String> billingWalletCurrencies(BillingAccount? account) => billingCreditCurrencies(account);

double billingCreditBalance(BillingAccount account, String currency) {
  final cur = currency.toUpperCase();
  if (cur == 'IDR') return account.balanceIdr;
  if (cur == 'USD') return account.balanceUsd;
  return account.balanceUsd;
}

double billingWalletBalance(BillingAccount account, String currency) => billingCreditBalance(account, currency);

/// Single-currency prepaid credit balance (IDR / USD).
String billingCreditBalanceLabel(BillingAccount? account, String currency) {
  if (account == null) return '';
  final cur = currency.toUpperCase();
  if (cur == 'IDR') return moneyFmtIdr(billingCreditBalance(account, cur));
  if (cur == 'USD') return moneyFmtUsd(billingCreditBalance(account, cur));
  final fx = account.hasFxMicroPerUsd() ? account.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  return moneyBalanceLabel(account.balanceUsd, currency: cur, fxMicroPerUsd: fx);
}

/// Plans checkout: `Credit: 1.234.567 IDR` (amount grouped, currency suffix).
String billingCreditCheckoutLabel(BillingAccount? account, String currency) {
  if (account == null) return '';
  final cur = currency.toUpperCase();
  final bal = billingCreditBalance(account, cur);
  if (cur == 'IDR') return 'Credit: ${moneyFmtIdrGrouped(bal.round())} IDR';
  if (cur == 'USD') return 'Credit: ${bal.toStringAsFixed(2)} USD';
  final fx = account.hasFxMicroPerUsd() ? account.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  final local = moneyUsdToLocal(bal, fx);
  return 'Credit: ${local.toStringAsFixed(2)} $cur';
}

String billingWalletBalanceLabel(BillingAccount? account, String currency) =>
    billingCreditBalanceLabel(account, currency);

/// Default (primary) credit balance.
String billingBalanceLabel(BillingAccount? account) =>
    billingCreditBalanceLabel(account, billingPrimaryCurrency(account ?? BillingAccount()));

bool billingCreditCoversCharge(BillingAccount account, {required String currency, double chargeIdr = 0, double chargeUsd = 0}) {
  final cur = currency.toUpperCase();
  if (cur == 'IDR') return chargeIdr <= 0 || billingCreditBalance(account, 'IDR') + 0.01 >= chargeIdr;
  return chargeUsd <= 0 || billingCreditBalance(account, 'USD') + 0.001 >= chargeUsd;
}

bool billingHistoryIncluded(BillingHistoryRow row) =>
    row.kind == 'usage' && row.status.trim().toLowerCase() == 'included';

String billingHistoryAmountLabel(BillingHistoryRow row) {
  if (row.hasCurrency() && row.currency.isNotEmpty) {
    final cur = row.currency.toUpperCase();
    final amt = row.hasAmount() ? row.amount.abs() : 0.0;
    if (cur == 'IDR') return moneyFmtIdrDetail(amt);
    if (cur == 'USD') return moneyFmtUsd(amt, decimals: 4);
    return '$cur ${uiFmtGroupedInt(amt.round())}';
  }
  if (row.amountIdr.abs() > 0) return moneyFmtIdrDetail(row.amountIdr.abs());
  return moneyFmtUsd(row.amountUsd.abs(), decimals: 4);
}

String billingMeterState(double used, double limit) {
  if (limit <= 0) return 'green';
  final pct = used / limit;
  if (pct >= 0.9) return 'red';
  if (pct >= 0.8) return 'orange';
  return 'green';
}

int _billingUpdatedTsMs(BillingAccount account) => account.hasUpdatedTsMs() ? account.updatedTsMs.toInt() : 0;

bool billingPushBalanceIsStale(BillingAccount base, BillingPushBalance push) {
  final pushTs = push.hasUpdatedTsMs() ? push.updatedTsMs.toInt() : 0;
  final baseTs = _billingUpdatedTsMs(base);
  return pushTs > 0 && baseTs > pushTs;
}

bool billingPushBalanceShouldApply(BillingAccount base, BillingPushBalance push) {
  if (billingPushBalanceIsStale(base, push)) return false;
  final pushTs = push.hasUpdatedTsMs() ? push.updatedTsMs.toInt() : 0;
  if (pushTs > 0) return true;
  return base.balanceIdr <= 0 && base.balanceUsd <= 0;
}

bool billingAccountPaidShell(BillingAccount account) =>
    billingPlanTierIsPaid(account.planTier) || billingAccountPaidEntitlement(account);

bool billingAccountIncomingDowngradesPaid(BillingAccount prev, BillingAccount incoming) {
  if (!billingAccountPaidShell(prev)) return false;
  return !billingPlanTierIsPaid(incoming.planTier) && !billingAccountPaidEntitlement(incoming);
}

double _billingMaxDouble(double a, double b) => a > b ? a : b;

Int64 _billingMaxInt64(Int64 a, Int64 b) => a.toInt() >= b.toInt() ? a : b;

/// Quota pushes are usage-only for paid users — never let them downgrade tier, rings, or balance.
BillingAccount billingAccountPackageRetainPaid(BillingAccount prev, BillingAccount incoming) {
  if (!billingAccountPaidShell(prev)) return incoming;
  final out = incoming.deepCopy();
  if (billingPlanTierIsPaid(prev.planTier)) out.planTier = prev.planTier;
  out.alienAllow5hLimit = _billingMaxDouble(prev.alienAllow5hLimit, out.alienAllow5hLimit);
  out.alienAllowWeeklyLimit = _billingMaxDouble(prev.alienAllowWeeklyLimit, out.alienAllowWeeklyLimit);
  out.frontierAllow5hLimit = _billingMaxDouble(prev.frontierAllow5hLimit, out.frontierAllow5hLimit);
  out.frontierAllowWeeklyLimit = _billingMaxDouble(prev.frontierAllowWeeklyLimit, out.frontierAllowWeeklyLimit);
  out.balanceIdr = _billingMaxDouble(prev.balanceIdr, out.balanceIdr);
  out.balanceUsd = _billingMaxDouble(prev.balanceUsd, out.balanceUsd);
  if (prev.hasPlanExpiresTsMs()) {
    out.planExpiresTsMs = _billingMaxInt64(prev.planExpiresTsMs, out.planExpiresTsMs);
  }
  out.freemiumActive = false;
  return out;
}

BillingAccount billingAccountMerge(BillingAccount base, {BillingPushBalance? balance, BillingPushQuota? quota, BillingPushCommission? commission}) {
  final out = base.deepCopy();
  if (balance != null && billingPushBalanceShouldApply(base, balance)) {
    out.balanceUsd = balance.balanceUsd;
    out.balanceIdr = balance.balanceIdr;
    if (balance.hasUpdatedTsMs()) out.updatedTsMs = balance.updatedTsMs;
    if (balance.hasCurrency() && balance.currency.isNotEmpty) out.billingCurrency = balance.currency;
    if (balance.hasBalance()) {
      final cur = billingCurrencyResolve(fromAccount: out.billingCurrency);
      if (cur == 'IDR') out.balanceIdr = balance.balance;
      if (cur == 'USD') out.balanceUsd = balance.balance;
    }
  }
  if (quota != null) {
    final paidShell = billingAccountPaidShell(base);
    out.alienAllow5hUsed = quota.alienAllow5hUsed;
    out.alienAllowWeeklyUsed = quota.alienAllowWeeklyUsed;
    out.frontierAllow5hUsed = quota.frontierAllow5hUsed;
    out.frontierAllowWeeklyUsed = quota.frontierAllowWeeklyUsed;
    if (quota.hasWindow5hStartMs()) out.window5hStartMs = quota.window5hStartMs;
    if (quota.hasWindowWeeklyStartMs()) out.windowWeeklyStartMs = quota.windowWeeklyStartMs;
    if (!paidShell) {
      out.alienAllow5hLimit = quota.alienAllow5hLimit;
      out.alienAllowWeeklyLimit = quota.alienAllowWeeklyLimit;
      out.freemiumMsgsUsed = quota.freemiumMsgsUsed;
      out.freemiumMsgsLimit = quota.freemiumMsgsLimit;
      out.freemiumTokensUsed = quota.freemiumTokensUsed;
      out.freemiumTokensLimit = quota.freemiumTokensLimit;
      out.freemiumActive = quota.freemiumActive;
      if (quota.hasPlanExpiresTsMs()) out.planExpiresTsMs = quota.planExpiresTsMs;
      if (quota.hasTrialExpiresTsMs()) out.trialExpiresTsMs = quota.trialExpiresTsMs;
      if (billingQuotaPushHasFrontierLimits(quota)) {
        out.frontierAllow5hLimit = quota.frontierAllow5hLimit;
        out.frontierAllowWeeklyLimit = quota.frontierAllowWeeklyLimit;
      }
    } else {
      out.freemiumActive = false;
      final qPlanExp = quota.hasPlanExpiresTsMs() ? quota.planExpiresTsMs.toInt() : 0;
      if (qPlanExp > 0) out.planExpiresTsMs = quota.planExpiresTsMs;
    }
  }
  if (commission != null) {
    out.commissionAvailableUsd = commission.commissionAvailableUsd;
    out.commissionEarnedUsd = commission.commissionEarnedUsd;
    out.commissionAvailableIdr = commission.commissionAvailableIdr;
    out.commissionEarnedIdr = commission.commissionEarnedIdr;
  }
  return billingAccountPackageReconcile(billingAccountPackageRetainPaid(base, out));
}
