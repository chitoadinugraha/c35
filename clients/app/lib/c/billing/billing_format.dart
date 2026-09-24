import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';

const billingFreemiumMsgsLimit = 30;
const billingFreemiumTokensLimit = 30000;

bool billingFreemiumActive(BillingAccount? account) => account?.freemiumActive == true;

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

String billingPrimaryCurrency(BillingAccount account) =>
    account.billingCurrency.isNotEmpty ? account.billingCurrency.toUpperCase() : moneyDefaultCurrency;

List<String> billingWalletCurrencies(BillingAccount? account) {
  if (account == null) return [moneyDefaultCurrency];
  final primary = billingPrimaryCurrency(account);
  return {primary, 'IDR', 'USD'}.toList();
}

double billingWalletBalance(BillingAccount account, String currency) {
  final cur = currency.toUpperCase();
  if (cur == 'IDR') return account.balanceIdr;
  if (cur == 'USD') return account.balanceUsd;
  return account.balanceUsd;
}

/// Single-currency balance for a wallet.
String billingWalletBalanceLabel(BillingAccount? account, String currency) {
  if (account == null) return '';
  final cur = currency.toUpperCase();
  if (cur == 'IDR') return moneyFmtIdr(billingWalletBalance(account, cur));
  if (cur == 'USD') return moneyFmtUsd(billingWalletBalance(account, cur));
  final fx = account.hasFxMicroPerUsd() ? account.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  return moneyBalanceLabel(account.balanceUsd, currency: cur, fxMicroPerUsd: fx);
}

/// Default (primary) wallet balance.
String billingBalanceLabel(BillingAccount? account) =>
    billingWalletBalanceLabel(account, billingPrimaryCurrency(account ?? BillingAccount()));

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

BillingAccount billingAccountMerge(BillingAccount base, {BillingPushBalance? balance, BillingPushQuota? quota, BillingPushCommission? commission}) {
  final out = base.deepCopy();
  if (balance != null) {
    out.balanceUsd = balance.balanceUsd;
    out.balanceIdr = balance.balanceIdr;
    if (balance.hasUpdatedTsMs()) out.updatedTsMs = balance.updatedTsMs;
    if (balance.hasCurrency() && balance.currency.isNotEmpty) out.billingCurrency = balance.currency;
  }
  if (quota != null) {
    out.alienAllow5hUsed = quota.alienAllow5hUsed;
    out.alienAllow5hLimit = quota.alienAllow5hLimit;
    out.alienAllowWeeklyUsed = quota.alienAllowWeeklyUsed;
    out.alienAllowWeeklyLimit = quota.alienAllowWeeklyLimit;
    if (quota.hasWindow5hStartMs()) out.window5hStartMs = quota.window5hStartMs;
    if (quota.hasWindowWeeklyStartMs()) out.windowWeeklyStartMs = quota.windowWeeklyStartMs;
    out.freemiumActive = quota.freemiumActive;
    out.freemiumMsgsUsed = quota.freemiumMsgsUsed;
    out.freemiumMsgsLimit = quota.freemiumMsgsLimit;
    out.freemiumTokensUsed = quota.freemiumTokensUsed;
    out.freemiumTokensLimit = quota.freemiumTokensLimit;
    if (quota.hasPlanExpiresTsMs()) out.planExpiresTsMs = quota.planExpiresTsMs;
    if (quota.hasTrialExpiresTsMs()) out.trialExpiresTsMs = quota.trialExpiresTsMs;
  }
  if (commission != null) {
    out.commissionAvailableUsd = commission.commissionAvailableUsd;
    out.commissionEarnedUsd = commission.commissionEarnedUsd;
    out.commissionAvailableIdr = commission.commissionAvailableIdr;
    out.commissionEarnedIdr = commission.commissionEarnedIdr;
  }
  return out;
}
