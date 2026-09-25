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

class BillingPlanQuotaLine {
  const BillingPlanQuotaLine({required this.label, required this.value});

  final String label;
  final String value;
}

List<BillingPlanQuotaLine> billingPlanQuotaLines(BillingPlanDoc plan) {
  final alien = plan.alienPoolIdrMonthly;
  final frontier = plan.frontierPoolIdrMonthly;
  if (alien <= 0 && frontier <= 0) return const [];
  final lines = <BillingPlanQuotaLine>[
    if (alien > 0) BillingPlanQuotaLine(label: 'Alien AI Quota', value: '${billingFmtRp(alien)}/mo'),
    if (frontier > 0) BillingPlanQuotaLine(label: 'API Quota', value: '${billingFmtRp(frontier)}/mo'),
  ];
  final channels = billingPlanChannelsBadge(plan);
  if (channels != null) lines.add(BillingPlanQuotaLine(label: 'Channels', value: channels));
  final priority = billingPlanPriorityBadge(plan);
  if (priority != null) lines.add(BillingPlanQuotaLine(label: 'Priority', value: priority));
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
      _plan(slug: 'lite', name: 'Lite', sortOrder: 10, priceIdrMonthly: 59000, priceIdrYearly: 49000, alienPool: 100000, frontierPool: 20000, poolMultiplier: 1, channels: 2),
      _plan(slug: 'plus', name: 'Plus', sortOrder: 20, priceIdrMonthly: 105000, priceIdrYearly: 99000, alienPool: 175000, frontierPool: 35000, poolMultiplier: 4, channels: 2, overage: true),
      _plan(slug: 'pro', name: 'Pro', sortOrder: 30, priceIdrMonthly: 340000, priceIdrYearly: 309000, alienPool: 565000, frontierPool: 115000, poolMultiplier: 10, channels: 3, overage: true, queuePriority: 5),
      _plan(slug: 'ultra', name: 'Ultra', sortOrder: 40, priceIdrMonthly: 1200000, priceIdrYearly: 1000000, alienPool: 2000000, frontierPool: 400000, poolMultiplier: 40, channels: 5, overage: true, queuePriority: 30, priorityQueue: true),
    ];
