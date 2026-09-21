import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:flutter/material.dart';

bool billingPlanIsFree(String slug) => slug.trim().toLowerCase() == 'free';

bool billingPlanIsRecommended(String slug) => slug.trim().toLowerCase() == 'pro';

String billingPlanTierLabel(String tier) => switch (tier.trim().toLowerCase()) {
      'pro' => 'Pro',
      'plus' => 'Plus',
      'free' => 'Free',
      _ => tier.trim().isEmpty ? 'Free' : tier.trim(),
    };

Color billingPlanAccentColor(String slug) => switch (slug.trim().toLowerCase()) {
      'plus' => const Color(0xFF34D399),
      'pro' => const Color(0xFF60A5FA),
      _ => const Color(0xFF71717A),
    };

String billingPlanPriceLabel(BillingPlanDoc plan) {
  if (billingPlanIsFree(plan.slug)) return 'Free';
  if (plan.priceUsd <= 0) return 'Free';
  return '\$${plan.priceUsd.toStringAsFixed(plan.priceUsd >= 10 ? 0 : 2)}/mo';
}

String billingPlanAllowLabel(BillingPlanDoc plan) =>
    '\$${plan.alienAllow5hUsd.toStringAsFixed(2)}/5h · \$${plan.alienAllowWeeklyUsd.toStringAsFixed(0)}/wk';

List<BillingPlanDoc> billingPlanCatalogNormalize(Iterable<BillingPlanDoc> plans) => plans.toList();

List<BillingPlanDoc> billingPlanCatalogFallback() => [
      BillingPlanDoc(slug: 'free', name: 'Free', sortOrder: 10, alienAllow5hUsd: 0.05, alienAllowWeeklyUsd: 1),
      BillingPlanDoc(slug: 'plus', name: 'Plus', sortOrder: 20, priceUsd: 9.99, durationMonths: 1, alienAllow5hUsd: 0.25, alienAllowWeeklyUsd: 5, overageEnabled: true),
      BillingPlanDoc(slug: 'pro', name: 'Pro', sortOrder: 30, priceUsd: 29.99, durationMonths: 1, alienAllow5hUsd: 1, alienAllowWeeklyUsd: 20, overageEnabled: true),
    ];
