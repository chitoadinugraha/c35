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

BillingAccount billingAccountMerge(BillingAccount base, {BillingPushBalance? balance, BillingPushQuota? quota, BillingPushCommission? commission}) {
  final out = base.deepCopy();
  if (balance != null && !billingPushBalanceIsStale(base, balance)) {
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
    out.frontierAllow5hUsed = quota.frontierAllow5hUsed;
    out.frontierAllow5hLimit = quota.frontierAllow5hLimit;
    out.frontierAllowWeeklyUsed = quota.frontierAllowWeeklyUsed;
    out.frontierAllowWeeklyLimit = quota.frontierAllowWeeklyLimit;
  }
  if (commission != null) {
    out.commissionAvailableUsd = commission.commissionAvailableUsd;
    out.commissionEarnedUsd = commission.commissionEarnedUsd;
    out.commissionAvailableIdr = commission.commissionAvailableIdr;
    out.commissionEarnedIdr = commission.commissionEarnedIdr;
  }
  return out;
}
