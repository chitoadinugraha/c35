import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

const billingApiAllow5hDefault = 0.01;
const billingApiAllowWeeklyDefault = 0.2;
const quotaRingWeeklyColor = Color(0xFF60A5FA);

Color quotaRingColor(String meterState) => switch (meterState) {
      'red' => const Color(0xFFF87171),
      'orange' => const Color(0xFFFBBF24),
      _ => const Color(0xFF34D399),
    };

double quotaRingRatio(num used, num limit) {
  if (limit <= 0) return 1;
  return ((limit - used) / limit).clamp(0.0, 1.0);
}

int quotaRingRemainingPct(num used, num limit) => (quotaRingRatio(used, limit) * 100).round();

class _QuotaRingLayout {
  const _QuotaRingLayout({
    required this.outerStroke,
    required this.innerStroke,
    required this.innerSize,
    required this.hubSize,
    required this.centerGap,
  });

  final double outerStroke;
  final double innerStroke;
  final double innerSize;
  final double hubSize;
  final double centerGap;

  static _QuotaRingLayout dual(double size) {
    final outerStroke = (size * 0.09).clamp(3.0, 3.8);
    final innerStroke = (outerStroke * 0.78).clamp(2.4, 3.2);
    const ringGap = 3.5;
    const centerGap = 2.5;
    final innerSize = size - 2 * outerStroke - 2 * ringGap;
    final hubSize = (innerSize - 2 * innerStroke - 2 * centerGap).clamp(size * 0.26, size * 0.46);
    return _QuotaRingLayout(outerStroke: outerStroke, innerStroke: innerStroke, innerSize: innerSize, hubSize: hubSize, centerGap: centerGap);
  }
}

Widget _quotaRingArc(double size, double stroke, double ratio, Color color) => SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: ratio,
        strokeWidth: stroke,
        strokeCap: StrokeCap.round,
        backgroundColor: color.withValues(alpha: 0.14),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );

Widget _quotaRingHub({required double hubSize, required double centerGap, required Widget icon}) => SizedBox(
      width: hubSize + centerGap * 2,
      height: hubSize + centerGap * 2,
      child: Center(child: icon),
    );

class UiQuotaDualRing extends StatelessWidget {
  const UiQuotaDualRing({
    super.key,
    required this.title,
    required this.titleColor,
    required this.centerIcon,
    required this.allow5hUsed,
    required this.allow5hLimit,
    required this.allowWeeklyUsed,
    required this.allowWeeklyLimit,
    required this.meterState,
    this.size = 48,
    this.showLabels = true,
    this.onTap,
  });

  final String title;
  final Color titleColor;
  final Widget centerIcon;
  final double allow5hUsed;
  final double allow5hLimit;
  final double allowWeeklyUsed;
  final double allowWeeklyLimit;
  final String meterState;
  final double size;
  final bool showLabels;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outerColor = quotaRingColor(meterState);
    const innerColor = quotaRingWeeklyColor;
    final pct5h = quotaRingRemainingPct(allow5hUsed, allow5hLimit);
    final pctWeekly = quotaRingRemainingPct(allowWeeklyUsed, allowWeeklyLimit);
    final layout = _QuotaRingLayout.dual(size);
    TextStyle pctStyle(Color color) => TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600, height: 1.25);
    final ring = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _quotaRingArc(size, layout.outerStroke, quotaRingRatio(allow5hUsed, allow5hLimit), outerColor),
          _quotaRingArc(layout.innerSize, layout.innerStroke, quotaRingRatio(allowWeeklyUsed, allowWeeklyLimit), innerColor),
          _quotaRingHub(hubSize: layout.hubSize, centerGap: layout.centerGap, icon: centerIcon),
        ],
      ),
    );
    Widget child = showLabels
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ring,
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(color: titleColor, fontSize: 10, fontWeight: FontWeight.w700, height: 1.2), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('5h: $pct5h%', style: pctStyle(outerColor), overflow: TextOverflow.ellipsis),
                    Text('Wk: $pctWeekly%', style: pctStyle(innerColor), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          )
        : ring;
    if (onTap != null) {
      child = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(2), child: child)),
      );
    }
    return uiTooltip(
      message: '$title\n5 Hours · $pct5h% left\nWeekly · $pctWeekly% left',
      preferBelow: false,
      child: child,
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
    this.balanceLabel = '',
    this.onBalanceTap,
    this.onPackageTap,
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
  final String balanceLabel;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onPackageTap;

  @override
  Widget build(BuildContext context) => Column(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: UiQuotaDualRing(
                        size: 38,
                        title: 'Alien AI',
                        titleColor: const Color(0xFFF4F4F5),
                        centerIcon: const UiAlienIcon(size: 14),
                        allow5hUsed: alien5hUsed,
                        allow5hLimit: alien5hLimit,
                        allowWeeklyUsed: alienWeeklyUsed,
                        allowWeeklyLimit: alienWeeklyLimit,
                        meterState: meterState,
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF27272A)),
                  Expanded(
                    child: Center(
                      child: UiQuotaDualRing(
                        size: 38,
                        title: 'API',
                        titleColor: const Color(0xFFF4F4F5),
                        centerIcon: const Icon(Icons.api, size: 14, color: Color(0xFFF4F4F5)),
                        allow5hUsed: api5hUsed,
                        allow5hLimit: api5hLimit,
                        allowWeeklyUsed: apiWeeklyUsed,
                        allowWeeklyLimit: apiWeeklyLimit,
                        meterState: meterState,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

UiQuotaPackagePanel uiQuotaPackagePanelFromSummary(
  ResBillingSummary summary, {
  bool planTierLoading = false,
  VoidCallback? onBalanceTap,
  VoidCallback? onPackageTap,
}) =>
    UiQuotaPackagePanel(
      planTier: summary.planTier,
      planTierLoading: planTierLoading,
      alien5hUsed: summary.alienAllow5hUsed,
      alien5hLimit: summary.alienAllow5hLimit > 0 ? summary.alienAllow5hLimit : 0.05,
      alienWeeklyUsed: summary.alienAllowWeeklyUsed,
      alienWeeklyLimit: summary.alienAllowWeeklyLimit > 0 ? summary.alienAllowWeeklyLimit : 1,
      api5hUsed: 0,
      api5hLimit: billingApiAllow5hDefault,
      apiWeeklyUsed: 0,
      apiWeeklyLimit: billingApiAllowWeeklyDefault,
      meterState: summary.meterState,
      balanceLabel: billingBalanceLabel(BillingAccount(balanceUsd: summary.balanceUsd, balanceIdr: summary.balanceIdr, billingCurrency: summary.balanceIdr > 0 ? 'IDR' : 'USD')),
      onBalanceTap: onBalanceTap,
      onPackageTap: onPackageTap,
    );

UiQuotaPackagePanel uiQuotaPackagePanelFromAccount(
  BillingAccount account, {
  bool planTierLoading = false,
  VoidCallback? onBalanceTap,
  VoidCallback? onPackageTap,
}) =>
    UiQuotaPackagePanel(
      planTier: account.planTier.isNotEmpty ? account.planTier : 'free',
      planTierLoading: planTierLoading,
      alien5hUsed: account.alienAllow5hUsed,
      alien5hLimit: account.alienAllow5hLimit > 0 ? account.alienAllow5hLimit : 0.05,
      alienWeeklyUsed: account.alienAllowWeeklyUsed,
      alienWeeklyLimit: account.alienAllowWeeklyLimit > 0 ? account.alienAllowWeeklyLimit : 1,
      api5hUsed: 0,
      api5hLimit: billingApiAllow5hDefault,
      apiWeeklyUsed: 0,
      apiWeeklyLimit: billingApiAllowWeeklyDefault,
      meterState: billingMeterState(account.alienAllow5hUsed, account.alienAllow5hLimit),
      balanceLabel: billingWalletBalanceLabel(account, billingPrimaryCurrency(account)),
      onBalanceTap: onBalanceTap,
      onPackageTap: onPackageTap,
    );
