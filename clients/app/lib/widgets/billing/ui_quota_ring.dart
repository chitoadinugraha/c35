import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const quotaRingWeeklyColor = Color(0xFF60A5FA);

Color quotaRingColor(String meterState) => switch (meterState) {
      'red' => const Color(0xFFF87171),
      'orange' => const Color(0xFFFBBF24),
      _ => const Color(0xFF34D399),
    };

class UiFreemiumQuotaPanel extends StatelessWidget {
  const UiFreemiumQuotaPanel({
    super.key,
    required this.msgsUsed,
    required this.msgsLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.meterState,
    this.onSubscribeTap,
  });

  final int msgsUsed;
  final int msgsLimit;
  final int tokensUsed;
  final int tokensLimit;
  final String meterState;
  final VoidCallback? onSubscribeTap;

  @override
  Widget build(BuildContext context) {
    final color = quotaRingColor(meterState);
    final msgRatio = msgsLimit > 0 ? (msgsUsed / msgsLimit).clamp(0.0, 1.0) : 0.0;
    final tokRatio = tokensLimit > 0 ? (tokensUsed / tokensLimit).clamp(0.0, 1.0) : 0.0;
    Widget bar(String label, double ratio) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(ratio * 100).round()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: color.withValues(alpha: 0.14), valueColor: AlwaysStoppedAnimation(color)),
            ),
          ],
        );
    return uiTooltip(
      message: 'Free daily limit\nSubscribe for full access',
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const UiAlienIcon(size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Free daily', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                if (onSubscribeTap != null)
                  TextButton(
                    onPressed: onSubscribeTap,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Subscribe', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            bar('$msgsUsed/$msgsLimit msgs', msgRatio),
            const SizedBox(height: 8),
            bar('${billingFreemiumTokensShort(tokensUsed)}/${billingFreemiumTokensShort(tokensLimit)} tokens', tokRatio),
          ],
        ),
      ),
    );
  }
}

class UiQuotaPackagePanel extends StatelessWidget {
  const UiQuotaPackagePanel({
    super.key,
    required this.planTier,
    this.planTierLoading = false,
    required this.alien5hUsed,
    required this.alien5hLimit,
    required this.alienWeeklyUsed,
    required this.alienWeeklyLimit,
    required this.api5hUsed,
    required this.api5hLimit,
    required this.apiWeeklyUsed,
    required this.apiWeeklyLimit,
    required this.meterState,
    this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd,
    this.balanceLabel = '',
    this.onBalanceTap,
    this.onPackageTap,
    this.freemiumActive = false,
    this.freemiumMsgsUsed = 0,
    this.freemiumMsgsLimit = billingFreemiumMsgsLimit,
    this.freemiumTokensUsed = 0,
    this.freemiumTokensLimit = billingFreemiumTokensLimit,
    this.trialExpiresTsMs,
    this.planExpiresTsMs,
  });

  final String planTier;
  final bool planTierLoading;
  final double alien5hUsed;
  final double alien5hLimit;
  final double alienWeeklyUsed;
  final double alienWeeklyLimit;
  final double api5hUsed;
  final double api5hLimit;
  final double apiWeeklyUsed;
  final double apiWeeklyLimit;
  final String meterState;
  final int fxMicroPerUsd;
  final String balanceLabel;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onPackageTap;
  final bool freemiumActive;
  final int freemiumMsgsUsed;
  final int freemiumMsgsLimit;
  final int freemiumTokensUsed;
  final int freemiumTokensLimit;
  final int? trialExpiresTsMs;
  final int? planExpiresTsMs;

  bool get _isPaidPlan => planTier.isNotEmpty && planTier != 'free';

  Widget _allowanceBar(String label, double used, double limit, Color color) {
    final remaining = (limit - used).clamp(0.0, limit);
    final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '${moneyAllowanceLabel(remaining, currency: 'IDR', fxMicroPerUsd: fxMicroPerUsd)} left',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final trialTs = trialExpiresTsMs;
    final showTrial = !_isPaidPlan && trialTs != null && trialTs > 0;
    final trialDaysLeft = showTrial ? ((trialTs - nowMs) / 86400000).ceil().clamp(0, 9999) : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBalanceTap != null) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBalanceTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 15, color: Color(0xFF71717A)),
                    const SizedBox(width: 8),
                    const Text('Balance', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(balanceLabel, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF71717A)),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF27272A)),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPackageTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 15, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 8),
                  const Text('Package', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    planTierLoading ? '…' : billingPlanTierLabel(planTier),
                    style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (onPackageTap != null) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 16, color: Color(0xFF71717A))],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF27272A)),
        if (freemiumActive)
          UiFreemiumQuotaPanel(
            msgsUsed: freemiumMsgsUsed,
            msgsLimit: freemiumMsgsLimit,
            tokensUsed: freemiumTokensUsed,
            tokensLimit: freemiumTokensLimit,
            meterState: meterState,
            onSubscribeTap: onPackageTap,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _allowanceBar('Alien AI · 5h', alien5hUsed, alien5hLimit, quotaRingColor(meterState)),
                const SizedBox(height: 8),
                _allowanceBar('Alien AI · 7d', alienWeeklyUsed, alienWeeklyLimit, quotaRingWeeklyColor),
                const SizedBox(height: 8),
                _allowanceBar('API · 5h', api5hUsed, api5hLimit, quotaRingColor(meterState)),
                const SizedBox(height: 8),
                _allowanceBar('API · 7d', apiWeeklyUsed, apiWeeklyLimit, quotaRingWeeklyColor),
                if (showTrial) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Trial · $trialDaysLeft day${trialDaysLeft == 1 ? '' : 's'} left',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

UiQuotaPackagePanel uiQuotaPackagePanelLimitPlaceholder({bool planTierLoading = false, VoidCallback? onPackageTap}) => UiQuotaPackagePanel(
      planTier: 'free',
      planTierLoading: planTierLoading,
      alien5hUsed: 0,
      alien5hLimit: 0,
      alienWeeklyUsed: 0,
      alienWeeklyLimit: 0,
      api5hUsed: 0,
      api5hLimit: 0,
      apiWeeklyUsed: 0,
      apiWeeklyLimit: 0,
      meterState: 'green',
      onPackageTap: onPackageTap,
      freemiumActive: true,
      freemiumMsgsUsed: 0,
      freemiumMsgsLimit: billingFreemiumMsgsLimit,
      freemiumTokensUsed: 0,
      freemiumTokensLimit: billingFreemiumTokensLimit,
    );

UiQuotaPackagePanel uiQuotaPackagePanelFromSummary(
  ResBillingSummary summary, {
  bool planTierLoading = false,
  VoidCallback? onBalanceTap,
  VoidCallback? onPackageTap,
}) {
  final fx = summary.hasFxMicroPerUsd() ? summary.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  return UiQuotaPackagePanel(
    planTier: summary.planTier,
    planTierLoading: planTierLoading,
    alien5hUsed: summary.alienAllow5hUsed,
    alien5hLimit: summary.alienAllow5hLimit,
    alienWeeklyUsed: summary.alienAllowWeeklyUsed,
    alienWeeklyLimit: summary.alienAllowWeeklyLimit,
    api5hUsed: 0,
    api5hLimit: 0,
    apiWeeklyUsed: 0,
    apiWeeklyLimit: 0,
    fxMicroPerUsd: fx,
    meterState: summary.freemiumActive
        ? billingMeterStateFreemium(BillingAccount(
            freemiumMsgsUsed: summary.freemiumMsgsUsed,
            freemiumMsgsLimit: summary.freemiumMsgsLimit,
            freemiumTokensUsed: summary.freemiumTokensUsed,
            freemiumTokensLimit: summary.freemiumTokensLimit,
          ))
        : summary.meterState,
    balanceLabel: billingWalletBalanceLabel(
      BillingAccount(
        balanceUsd: summary.balanceUsd,
        balanceIdr: summary.balanceIdr,
        billingCurrency: billingCurrencyResolve(fromSummary: summary.hasBillingCurrency() ? summary.billingCurrency : null),
        fxMicroPerUsd: summary.hasFxMicroPerUsd() ? summary.fxMicroPerUsd : Int64(moneyDefaultFxMicroPerUsd),
      ),
      billingCurrencyResolve(fromSummary: summary.hasBillingCurrency() ? summary.billingCurrency : null),
    ),
    onBalanceTap: onBalanceTap,
    onPackageTap: onPackageTap,
    freemiumActive: summary.freemiumActive,
    freemiumMsgsUsed: summary.freemiumMsgsUsed,
    freemiumMsgsLimit: summary.freemiumMsgsLimit > 0 ? summary.freemiumMsgsLimit : billingFreemiumMsgsLimit,
    freemiumTokensUsed: summary.freemiumTokensUsed,
    freemiumTokensLimit: summary.freemiumTokensLimit > 0 ? summary.freemiumTokensLimit : billingFreemiumTokensLimit,
    trialExpiresTsMs: summary.hasTrialExpiresTsMs() ? summary.trialExpiresTsMs.toInt() : null,
    planExpiresTsMs: summary.hasPlanExpiresTsMs() ? summary.planExpiresTsMs.toInt() : null,
  );
}

UiQuotaPackagePanel uiQuotaPackagePanelFromAccount(
  BillingAccount account, {
  BillingPushQuota? quota,
  bool planTierLoading = false,
  VoidCallback? onBalanceTap,
  VoidCallback? onPackageTap,
}) {
  final fx = account.hasFxMicroPerUsd() ? account.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  final frontier5hUsed = account.frontierAllow5hUsed;
  final frontier5hLimit = account.frontierAllow5hLimit;
  final frontierWeeklyUsed = account.frontierAllowWeeklyUsed;
  final frontierWeeklyLimit = account.frontierAllowWeeklyLimit;
  return UiQuotaPackagePanel(
    planTier: account.planTier.isNotEmpty ? account.planTier : 'free',
    planTierLoading: planTierLoading,
    alien5hUsed: account.alienAllow5hUsed,
    alien5hLimit: account.alienAllow5hLimit,
    alienWeeklyUsed: account.alienAllowWeeklyUsed,
    alienWeeklyLimit: account.alienAllowWeeklyLimit,
    api5hUsed: frontier5hUsed,
    api5hLimit: frontier5hLimit,
    apiWeeklyUsed: frontierWeeklyUsed,
    apiWeeklyLimit: frontierWeeklyLimit,
    fxMicroPerUsd: fx,
    meterState: billingFreemiumActive(account) ? billingMeterStateFreemium(account) : billingMeterState(account.alienAllow5hUsed, account.alienAllow5hLimit),
    balanceLabel: billingWalletBalanceLabel(account, billingPrimaryCurrency(account)),
    onBalanceTap: onBalanceTap,
    onPackageTap: onPackageTap,
    freemiumActive: billingFreemiumActive(account),
    freemiumMsgsUsed: account.freemiumMsgsUsed,
    freemiumMsgsLimit: account.freemiumMsgsLimit > 0 ? account.freemiumMsgsLimit : billingFreemiumMsgsLimit,
    freemiumTokensUsed: account.freemiumTokensUsed,
    freemiumTokensLimit: account.freemiumTokensLimit > 0 ? account.freemiumTokensLimit : billingFreemiumTokensLimit,
    trialExpiresTsMs: quota?.hasTrialExpiresTsMs() == true ? quota!.trialExpiresTsMs.toInt() : (account.hasTrialExpiresTsMs() ? account.trialExpiresTsMs.toInt() : null),
    planExpiresTsMs: quota?.hasPlanExpiresTsMs() == true ? quota!.planExpiresTsMs.toInt() : (account.hasPlanExpiresTsMs() ? account.planExpiresTsMs.toInt() : null),
  );
}
