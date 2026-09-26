import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/material.dart';

bool billingPlanIsFree(String slug) {
  final s = slug.trim().toLowerCase();
  return s.isEmpty || s == 'free';
}

bool billingPlanIsRecommended(String slug) => slug.trim().toLowerCase() == 'pro';

String billingPlanTierLabel(String tier) => switch (tier.trim().toLowerCase()) {
      'ultra' => 'Ultra',
      'pro' => 'Pro',
      'plus' => 'Plus',
      'lite' => 'Lite',
      'free' => 'Trial',
      _ => tier.trim().isEmpty ? 'Trial' : tier.trim(),
    };

Color billingPlanAccentColor(String slug) => switch (slug.trim().toLowerCase()) {
      'ultra' => const Color(0xFFFBBF24),
      'pro' => const Color(0xFF60A5FA),
      'plus' => const Color(0xFF34D399),
      'lite' => const Color(0xFFA1A1AA),
      _ => const Color(0xFF71717A),
    };

String billingFmtRp(num amount, {bool compact = false}) {
  final n = amount.round();
  if (compact && n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}jt';
  if (compact && n >= 1000) return 'Rp ${(n / 1000).round()}k';
  return 'Rp ${moneyFmtIdrGrouped(n)}';
}

double billingPlanPriceAmount(BillingPlanDoc plan, {required String currency, required bool yearly}) {
  final cur = currency.toUpperCase();
  if (cur == 'IDR') {
    final idr = yearly ? plan.priceIdrYearly : plan.priceIdrMonthly;
    if (idr > 0) return idr;
  }
  return plan.priceUsd > 0 ? plan.priceUsd : 0;
}

String billingPlanPriceLabel(BillingPlanDoc plan, {String currency = 'IDR', bool yearly = false}) {
  if (billingPlanIsFree(plan.slug)) return 'Trial';
  final amount = billingPlanPriceAmount(plan, currency: currency, yearly: yearly);
  if (amount <= 0) return '—';
  if (currency.toUpperCase() == 'IDR') return '${billingFmtRp(amount)}/mo';
  return '\$${amount.toStringAsFixed(amount >= 10 ? 0 : 2)}/mo';
}

String? billingPlanPriceSubLabel(BillingPlanDoc plan, {String currency = 'IDR', required bool yearly}) {
  if (billingPlanIsFree(plan.slug) || !yearly || currency.toUpperCase() != 'IDR') return null;
  if (plan.priceIdrYearly <= 0) return null;
  final yearlyTotal = (plan.priceIdrYearly * 12).round();
  return 'Rp ${moneyFmtIdrGrouped(yearlyTotal)} billed yearly';
}

int billingPlanQuotaMultiplier(BillingPlanDoc plan) {
  if (plan.poolMultiplier >= 1) return plan.poolMultiplier.round();
  return switch (plan.slug.trim().toLowerCase()) {
    'plus' => 4,
    'pro' => 10,
    'ultra' => 40,
    _ => 1,
  };
}

String billingPlanQuotaBadge(BillingPlanDoc plan) {
  final mult = billingPlanQuotaMultiplier(plan);
  return mult <= 1 ? '1× quota' : '$mult× quota';
}

int billingPlanQueuePriority(BillingPlanDoc plan) {
  if (plan.queuePriorityMultiplier > 0) return plan.queuePriorityMultiplier;
  return switch (plan.slug.trim().toLowerCase()) {
    'pro' => 5,
    'ultra' => 30,
    _ => 0,
  };
}

String? billingPlanFollowupQueueLabel(BillingPlanDoc plan) {
  final slug = plan.slug.trim().toLowerCase();
  if (slug == 'lite') return 'Not included';
  if (slug == 'plus' || slug == 'pro' || slug == 'ultra') return 'Up to 5 while AI works';
  return null;
}

String? billingPlanPriorityBadge(BillingPlanDoc plan) {
  final mult = billingPlanQueuePriority(plan);
  if (mult <= 1) return plan.priorityQueue ? 'Priority queue' : null;
  return '$mult× priority';
}

String billingPlanPoolsLabel(BillingPlanDoc plan) {
  final lines = billingPlanQuotaLines(plan);
  if (lines.isEmpty) return billingPlanAllowLabelLegacy(plan);
  return lines.map((l) => '${l.label}: ${l.value}').join(' · ');
}

enum BillingPlanLineKind { sectionHeader, row }

class BillingPlanQuotaLine {
  const BillingPlanQuotaLine({
    required this.label,
    this.value = '',
    this.comparison,
    this.kind = BillingPlanLineKind.row,
    this.showsIncluded = false,
    this.valueAccent = false,
  });

  final BillingPlanLineKind kind;
  final String label;
  final String value;
  final String? comparison;
  final bool showsIncluded;
  final bool valueAccent;
}

int billingPlanIotDeviceLimit(BillingPlanDoc plan) => switch (plan.slug.trim().toLowerCase()) {
      'plus' => 20,
      'pro' => 100,
      'ultra' => 1000,
      _ => 10,
    };

String billingPlanModelsValue(BillingPlanDoc plan) => switch (plan.slug.trim().toLowerCase()) {
      'lite' => 'Alien AI',
      _ => 'Gemini, ChatGPT, DeepSeek & more',
    };

String? billingPlanTierComparison(int value, int liteValue) {
  if (liteValue <= 0 || value <= liteValue) return null;
  final ratio = value / liteValue;
  final shown = ratio >= 10 ? ratio.round().toString() : (ratio * 10).round() / 10;
  return '($shown× more than Lite)';
}

String? billingPlanQuotaComparison(BillingPlanDoc plan, {BillingPlanDoc? litePlan}) {
  final slug = plan.slug.trim().toLowerCase();
  if (slug == 'lite' || billingPlanIsFree(slug)) return null;
  final mult = billingPlanQuotaMultiplier(plan);
  if (mult > 1) return '($mult× more than Lite)';
  if (litePlan == null) return null;
  final alien = plan.alienPoolIdrMonthly;
  final base = litePlan.alienPoolIdrMonthly;
  if (base <= 0 || alien <= base) return null;
  final ratio = alien / base;
  final shown = ratio >= 10 ? ratio.round().toString() : (ratio * 10).round() / 10;
  return '($shown× more than Lite)';
}

String? billingPlanQuotaAmountComparison(double value, double baseline, {String baselineName = 'Lite'}) {
  if (baseline <= 0 || value <= baseline) return null;
  final ratio = value / baseline;
  final shown = ratio >= 10 ? ratio.round().toString() : (ratio * 10).round() / 10;
  return '($shown× more than $baselineName)';
}

List<BillingPlanQuotaLine> billingPlanQuotaLines(BillingPlanDoc plan, {BillingPlanDoc? litePlan}) {
  final alien = plan.alienPoolIdrMonthly;
  final frontier = plan.frontierPoolIdrMonthly;
  final liteIot = litePlan != null ? billingPlanIotDeviceLimit(litePlan) : 10;
  final iot = billingPlanIotDeviceLimit(plan);
  final poolCmp = billingPlanQuotaComparison(plan, litePlan: litePlan);
  final baseAlien = litePlan?.alienPoolIdrMonthly ?? 0;
  final baseFrontier = litePlan?.frontierPoolIdrMonthly ?? 0;
  final lines = <BillingPlanQuotaLine>[
    const BillingPlanQuotaLine(label: 'Features', kind: BillingPlanLineKind.sectionHeader),
    const BillingPlanQuotaLine(label: 'Computer use', value: 'Included', showsIncluded: false),
    const BillingPlanQuotaLine(label: 'Image generation', value: 'Included', showsIncluded: false),
    BillingPlanQuotaLine(label: 'Multiple models', value: billingPlanModelsValue(plan), showsIncluded: true),
    BillingPlanQuotaLine(
      label: 'IoT devices',
      value: '$iot device${iot == 1 ? '' : 's'}',
      showsIncluded: true,
      comparison: billingPlanTierComparison(iot, liteIot),
    ),
    if (plan.overageEnabled)
      const BillingPlanQuotaLine(label: 'Wallet overage', value: 'Enabled', showsIncluded: false, valueAccent: true),
    const BillingPlanQuotaLine(label: 'Limits', kind: BillingPlanLineKind.sectionHeader),
    if (alien > 0)
      BillingPlanQuotaLine(
        label: 'Alien AI quota',
        value: '${billingFmtRp(alien)}/mo',
        comparison: poolCmp ?? billingPlanQuotaAmountComparison(alien, baseAlien),
        showsIncluded: true,
      ),
    if (frontier > 0)
      BillingPlanQuotaLine(
        label: 'API quota',
        value: '${billingFmtRp(frontier)}/mo',
        comparison: poolCmp ?? billingPlanQuotaAmountComparison(frontier, baseFrontier),
        showsIncluded: true,
      ),
  ];
  final channels = billingPlanChannelsBadge(plan);
  if (channels != null) lines.add(BillingPlanQuotaLine(label: 'Channels', value: channels, showsIncluded: true));
  final priority = billingPlanPriorityBadge(plan);
  if (priority != null) {
    lines.add(BillingPlanQuotaLine(label: 'Priority queue', value: priority, valueAccent: true));
  }
  final followup = billingPlanFollowupQueueLabel(plan);
  if (followup != null) {
    lines.add(BillingPlanQuotaLine(label: 'Prompt queue', value: followup));
  }
  if (alien <= 0 && frontier <= 0 && lines.length <= 2) return const [];
  return lines;
}

String billingPlanAllowLabelLegacy(BillingPlanDoc plan) =>
    '\$${plan.alienAllow5hUsd.toStringAsFixed(2)}/5h · \$${plan.alienAllowWeeklyUsd.toStringAsFixed(0)}/wk';

String billingPlanAllowLabel(BillingPlanDoc plan) => billingPlanPoolsLabel(plan);

String? billingPlanChannelsBadge(BillingPlanDoc plan) =>
    plan.channelsLimit > 0 ? '${plan.channelsLimit} channel${plan.channelsLimit == 1 ? '' : 's'}' : null;

List<BillingPlanDoc> billingPlanCatalogNormalize(Iterable<BillingPlanDoc> plans) =>
    plans.where((p) => !billingPlanIsFree(p.slug)).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

BillingPlanDoc _plan({
  required String slug,
  required String name,
  required int sortOrder,
  required double priceIdrMonthly,
  required double priceIdrYearly,
  required double alienPool,
  required double frontierPool,
  required int poolMultiplier,
  required int channels,
  bool overage = false,
  int queuePriority = 0,
  bool priorityQueue = false,
}) =>
    BillingPlanDoc(
      slug: slug,
      name: name,
      sortOrder: sortOrder,
      priceIdrMonthly: priceIdrMonthly,
      priceIdrYearly: priceIdrYearly,
      alienPoolIdrMonthly: alienPool,
      frontierPoolIdrMonthly: frontierPool,
      poolMultiplier: poolMultiplier.toDouble(),
      tier: slug,
      channelsLimit: channels,
      overageEnabled: overage,
      queuePriorityMultiplier: queuePriority,
      priorityQueue: priorityQueue,
    );

List<BillingPlanDoc> billingPlanCatalogFallback() => [
      _plan(slug: 'lite', name: 'Lite', sortOrder: 10, priceIdrMonthly: 59000, priceIdrYearly: 49000, alienPool: 100000, frontierPool: 20000, poolMultiplier: 1, channels: 1),
      _plan(slug: 'plus', name: 'Plus', sortOrder: 20, priceIdrMonthly: 105000, priceIdrYearly: 99000, alienPool: 175000, frontierPool: 35000, poolMultiplier: 4, channels: 1, overage: true),
      _plan(slug: 'pro', name: 'Pro', sortOrder: 30, priceIdrMonthly: 340000, priceIdrYearly: 309000, alienPool: 565000, frontierPool: 115000, poolMultiplier: 10, channels: 1, overage: true, queuePriority: 5),
      _plan(slug: 'ultra', name: 'Ultra', sortOrder: 40, priceIdrMonthly: 1200000, priceIdrYearly: 1000000, alienPool: 2000000, frontierPool: 400000, poolMultiplier: 40, channels: 5, overage: true, queuePriority: 30, priorityQueue: true),
    ];
