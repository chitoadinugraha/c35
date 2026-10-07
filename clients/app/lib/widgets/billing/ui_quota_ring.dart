import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const quotaRingWeeklyColor = Color(0xFF60A5FA);
const quotaRing5hHealthyColor = Color(0xFF34D399);
const quotaRingRemainRed = Color(0xFFF87171);
const quotaRingRemainYellow = Color(0xFFFBBF24);
const quotaRingMeterEmptyColor = Color(0xFF3F3F46);

Color quotaRingColor(String meterState) => switch (meterState) {
      'red' => quotaRingRemainRed,
      'orange' => quotaRingRemainYellow,
      _ => quotaRing5hHealthyColor,
    };

double quotaAllowanceRemainRatio(double used, double limit) => limit > 0 ? ((limit - used) / limit).clamp(0.0, 1.0) : 0.0;

Color quotaAllowanceMeterColor(double used, double limit, Color healthy) {
  if (limit <= 0) return quotaRingMeterEmptyColor;
  final remain = (limit - used) / limit;
  if (remain < 0.10) return quotaRingRemainRed;
  if (remain < 0.20) return quotaRingRemainYellow;
  return healthy;
}

class UiFreemiumQuotaPanel extends StatelessWidget {
  const UiFreemiumQuotaPanel({
    super.key,
    required this.msgsUsed,
    required this.msgsLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.meterState,
    this.onSubscribeTap,
    this.embeddedInPackage = false,
  });

  final int msgsUsed;
  final int msgsLimit;
  final int tokensUsed;
  final int tokensLimit;
  final String meterState;
  final VoidCallback? onSubscribeTap;
  final bool embeddedInPackage;

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
    final body = Padding(
      padding: EdgeInsets.fromLTRB(embeddedInPackage ? 2 : 0, embeddedInPackage ? 2 : 6, 0, embeddedInPackage ? 4 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embeddedInPackage) ...[
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
          ],
          bar('$msgsUsed/$msgsLimit msgs', msgRatio),
          const SizedBox(height: 6),
          bar('${billingFreemiumTokensShort(tokensUsed)}/${billingFreemiumTokensShort(tokensLimit)} tokens', tokRatio),
        ],
      ),
    );
    if (embeddedInPackage) return body;
    return uiTooltip(
      message: 'Free daily limit\nSubscribe for full access',
      preferBelow: false,
      child: body,
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

  Widget _quotaAllowanceMeter({required double used, required double limit, required bool weekly}) {
    final healthy = weekly ? quotaRingWeeklyColor : quotaRing5hHealthyColor;
    final color = quotaAllowanceMeterColor(used, limit, healthy);
    final remainRatio = quotaAllowanceRemainRatio(used, limit);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: remainRatio,
          minHeight: 5,
          backgroundColor: const Color(0xFF27272A),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }

  void _openUsageDialog(BuildContext context) => quotaUsageDialogShow(
        context,
        planTier: planTier,
        planTierLoading: planTierLoading,
        onPackageTap: onPackageTap,
        alien5hUsed: alien5hUsed,
        alien5hLimit: alien5hLimit,
        alienWeeklyUsed: alienWeeklyUsed,
        alienWeeklyLimit: alienWeeklyLimit,
        frontier5hUsed: api5hUsed,
        frontier5hLimit: api5hLimit,
        frontierWeeklyUsed: apiWeeklyUsed,
        frontierWeeklyLimit: apiWeeklyLimit,
        fxMicroPerUsd: fxMicroPerUsd,
      );

  Widget _packageHeaderRow({bool includeBottomPadding = true}) => Padding(
        padding: EdgeInsets.fromLTRB(2, 8, 2, includeBottomPadding ? 4 : 0),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 15, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            Text('settings.package'.tr(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              planTierLoading ? '…' : billingPlanTierLabel(planTier),
              style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (onPackageTap != null) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 16, color: Color(0xFF71717A))],
          ],
        ),
      );

  Widget _freemiumPackageBlock(BuildContext context) => uiTooltip(
        message: 'billing.freemiumPackageTooltip'.tr(),
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPackageTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _packageHeaderRow(includeBottomPadding: false),
                UiFreemiumQuotaPanel(
                  embeddedInPackage: true,
                  msgsUsed: freemiumMsgsUsed,
                  msgsLimit: freemiumMsgsLimit,
                  tokensUsed: freemiumTokensUsed,
                  tokensLimit: freemiumTokensLimit,
                  meterState: meterState,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _quotaServiceRow({
    required String title,
    required Widget icon,
    required double allow5hUsed,
    required double allow5hLimit,
    required double allowWeeklyUsed,
    required double allowWeeklyLimit,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(child: _quotaAllowanceMeter(used: allowWeeklyUsed, limit: allowWeeklyLimit, weekly: true)),
            const SizedBox(width: 8),
            Expanded(child: _quotaAllowanceMeter(used: allow5hUsed, limit: allow5hLimit, weekly: false)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final trialTs = trialExpiresTsMs;
    final showTrial = !planTierLoading && !_isPaidPlan && trialTs != null && trialTs > 0;
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
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (freemiumActive && !planTierLoading)
                _freemiumPackageBlock(context)
              else ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPackageTap,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: _packageHeaderRow(),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openUsageDialog(context),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _quotaServiceRow(
                            title: 'Alien AI',
                            icon: const UiAlienIcon(size: 14),
                            allow5hUsed: alien5hUsed,
                            allow5hLimit: alien5hLimit,
                            allowWeeklyUsed: alienWeeklyUsed,
                            allowWeeklyLimit: alienWeeklyLimit,
                          ),
                          _quotaServiceRow(
                            title: 'Frontier',
                            icon: const Icon(Icons.hub_outlined, size: 14, color: Color(0xFFF4F4F5)),
                            allow5hUsed: api5hUsed,
                            allow5hLimit: api5hLimit,
                            allowWeeklyUsed: apiWeeklyUsed,
                            allowWeeklyLimit: apiWeeklyLimit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (showTrial) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(2, freemiumActive ? 4 : 6, 2, 0),
                  child: Text(
                    'Trial · $trialDaysLeft day${trialDaysLeft == 1 ? '' : 's'} left',
                    style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF27272A)),
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
      freemiumActive: false,
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
    api5hUsed: summary.frontierAllow5hUsed,
    api5hLimit: summary.frontierAllow5hLimit,
    apiWeeklyUsed: summary.frontierAllowWeeklyUsed,
    apiWeeklyLimit: summary.frontierAllowWeeklyLimit,
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
    freemiumActive: billingFreemiumActive(BillingAccount(
      planTier: summary.planTier,
      freemiumActive: summary.freemiumActive,
      trialExpiresTsMs: summary.hasTrialExpiresTsMs() ? summary.trialExpiresTsMs : Int64.ZERO,
    )),
    freemiumMsgsUsed: summary.freemiumMsgsUsed,
    freemiumMsgsLimit: summary.freemiumMsgsLimit > 0 ? summary.freemiumMsgsLimit : billingFreemiumMsgsLimit,
    freemiumTokensUsed: summary.freemiumTokensUsed,
    freemiumTokensLimit: summary.freemiumTokensLimit > 0 ? summary.freemiumTokensLimit : billingFreemiumTokensLimit,
    trialExpiresTsMs: summary.hasTrialExpiresTsMs() ? summary.trialExpiresTsMs.toInt() : null,
    planExpiresTsMs: summary.hasPlanExpiresTsMs() ? summary.planExpiresTsMs.toInt() : null,
  );
}

Future<void> quotaUsageDialogShow(
  BuildContext context, {
  required String planTier,
  bool planTierLoading = false,
  VoidCallback? onPackageTap,
  required double alien5hUsed,
  required double alien5hLimit,
  required double alienWeeklyUsed,
  required double alienWeeklyLimit,
  required double frontier5hUsed,
  required double frontier5hLimit,
  required double frontierWeeklyUsed,
  required double frontierWeeklyLimit,
  required int fxMicroPerUsd,
}) =>
    uiDialogShow(
      context: context,
      builder: (ctx) => UiDialog(
        maxWidth: 380,
        padding: uiDialogInsetCompact,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiDialogHeader(title: 'billing.quotaUsageDialogTitle'.tr()),
              const SizedBox(height: 4),
              Text(
                'billing.quotaPackageSection'.tr(),
                style: const TextStyle(color: Color(0xFF52525B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.2),
              ),
              const SizedBox(height: 8),
              if (onPackageTap != null)
                UiQuotaDialogPanel(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        onPackageTap();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('billing.quotaCurrentPackage'.tr(), style: const TextStyle(color: uiDialogMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text(
                                    planTierLoading ? '…' : billingPlanTierLabel(planTier),
                                    style: const TextStyle(color: uiDialogTitleColor, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Text('billing.quotaUpgradeTap'.tr(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF38BDF8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                UiQuotaDialogPanel(
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('billing.quotaCurrentPackage'.tr(), style: const TextStyle(color: uiDialogMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(
                              planTierLoading ? '…' : billingPlanTierLabel(planTier),
                              style: const TextStyle(color: uiDialogTitleColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'billing.quotaAllowanceSection'.tr(),
                style: const TextStyle(color: Color(0xFF52525B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text('billing.quotaIncludedIdr'.tr(), style: const TextStyle(color: uiDialogMuted, fontSize: 11, height: 1.35)),
              const SizedBox(height: 10),
              UiQuotaDialogPanel(
                child: UiQuotaUsageServiceBlock(
                  title: 'Alien AI',
                  description: 'billing.quotaAlienAiDesc'.tr(),
                  icon: const UiAlienIcon(size: 16),
                  allow5hUsed: alien5hUsed,
                  allow5hLimit: alien5hLimit,
                  allowWeeklyUsed: alienWeeklyUsed,
                  allowWeeklyLimit: alienWeeklyLimit,
                  fxMicroPerUsd: fxMicroPerUsd,
                ),
              ),
              const SizedBox(height: 10),
              UiQuotaDialogPanel(
                child: UiQuotaUsageServiceBlock(
                  title: 'Frontier',
                  description: 'billing.quotaFrontierDesc'.tr(),
                  icon: const Icon(Icons.hub_outlined, size: 16, color: Color(0xFFF4F4F5)),
                  allow5hUsed: frontier5hUsed,
                  allow5hLimit: frontier5hLimit,
                  allowWeeklyUsed: frontierWeeklyUsed,
                  allowWeeklyLimit: frontierWeeklyLimit,
                  fxMicroPerUsd: fxMicroPerUsd,
                ),
              ),
            ],
          ),
        ),
      ),
    );

class UiQuotaDialogPanel extends StatelessWidget {
  const UiQuotaDialogPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3F3F46)),
        ),
        child: Padding(padding: const EdgeInsets.fromLTRB(12, 11, 12, 11), child: child),
      );
}

class UiQuotaUsageServiceBlock extends StatelessWidget {
  const UiQuotaUsageServiceBlock({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.allow5hUsed,
    required this.allow5hLimit,
    required this.allowWeeklyUsed,
    required this.allowWeeklyLimit,
    required this.fxMicroPerUsd,
  });

  final String title;
  final String description;
  final Widget icon;
  final double allow5hUsed;
  final double allow5hLimit;
  final double allowWeeklyUsed;
  final double allowWeeklyLimit;
  final int fxMicroPerUsd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: uiDialogTitleColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: uiDialogMuted, fontSize: 11, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UiQuotaAllowanceBar(
            label: 'billing.quotaPeriodWeekly'.tr(),
            used: allowWeeklyUsed,
            limit: allowWeeklyLimit,
            weekly: true,
            fxMicroPerUsd: fxMicroPerUsd,
          ),
          const SizedBox(height: 10),
          UiQuotaAllowanceBar(
            label: 'billing.quotaPeriod5h'.tr(),
            used: allow5hUsed,
            limit: allow5hLimit,
            weekly: false,
            fxMicroPerUsd: fxMicroPerUsd,
          ),
        ],
      );
}

class UiQuotaAllowanceBar extends StatelessWidget {
  const UiQuotaAllowanceBar({super.key, required this.label, required this.used, required this.limit, required this.weekly, required this.fxMicroPerUsd});

  final String label;
  final double used;
  final double limit;
  final bool weekly;
  final int fxMicroPerUsd;

  @override
  Widget build(BuildContext context) {
    final healthy = weekly ? quotaRingWeeklyColor : quotaRing5hHealthyColor;
    final color = quotaAllowanceMeterColor(used, limit, healthy);
    final remainRatio = quotaAllowanceRemainRatio(used, limit);
    final remaining = (limit - used).clamp(0.0, limit);
    final remainingLabel = limit > 0 ? moneyAllowanceLabel(remaining, currency: 'IDR', fxMicroPerUsd: fxMicroPerUsd) : '—';
    final limitLabel = limit > 0 ? moneyAllowanceLabel(limit, currency: 'IDR', fxMicroPerUsd: fxMicroPerUsd) : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('billing.quotaRemaining'.tr(namedArgs: {'amount': remainingLabel}), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text('billing.quotaCap'.tr(namedArgs: {'amount': limitLabel}), style: const TextStyle(color: Color(0xFF52525B), fontSize: 10, height: 1.2)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: remainRatio,
            minHeight: 6,
            backgroundColor: const Color(0xFF27272A),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

UiQuotaPackagePanel uiQuotaPackagePanelFromAccount(
  BillingAccount account, {
  BillingPushQuota? quota,
  bool planTierLoading = false,
  VoidCallback? onBalanceTap,
  VoidCallback? onPackageTap,
}) {
  final fx = account.hasFxMicroPerUsd() ? account.fxMicroPerUsd.toInt() : moneyDefaultFxMicroPerUsd;
  final resolved = billingAccountPackageReconcile(account);
  final frontier5hUsed = resolved.frontierAllow5hUsed;
  final frontier5hLimit = resolved.frontierAllow5hLimit;
  final frontierWeeklyUsed = resolved.frontierAllowWeeklyUsed;
  final frontierWeeklyLimit = resolved.frontierAllowWeeklyLimit;
  return UiQuotaPackagePanel(
    planTier: billingPlanTierDisplay(resolved),
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
    freemiumActive: planTierLoading ? false : billingFreemiumActive(account),
    freemiumMsgsUsed: account.freemiumMsgsUsed,
    freemiumMsgsLimit: account.freemiumMsgsLimit > 0 ? account.freemiumMsgsLimit : billingFreemiumMsgsLimit,
    freemiumTokensUsed: account.freemiumTokensUsed,
    freemiumTokensLimit: account.freemiumTokensLimit > 0 ? account.freemiumTokensLimit : billingFreemiumTokensLimit,
    trialExpiresTsMs: quota?.hasTrialExpiresTsMs() == true ? quota!.trialExpiresTsMs.toInt() : (account.hasTrialExpiresTsMs() ? account.trialExpiresTsMs.toInt() : null),
    planExpiresTsMs: quota?.hasPlanExpiresTsMs() == true ? quota!.planExpiresTsMs.toInt() : (account.hasPlanExpiresTsMs() ? account.planExpiresTsMs.toInt() : null),
  );
}
