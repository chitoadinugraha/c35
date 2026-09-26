import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/referral/ui_billing_package_redeem.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

Future<void> billingPackageSheet(BuildContext context, {required ReferralConn conn}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121215),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _BillingPackageSheet(conn: conn),
  );
}

class _BillingPackageSheet extends StatefulWidget {
  const _BillingPackageSheet({required this.conn});

  final ReferralConn conn;

  @override
  State<_BillingPackageSheet> createState() => _BillingPackageSheetState();
}

class _BillingPackageSheetState extends State<_BillingPackageSheet> {
  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);

  var _loading = true;
  var _subscribing = false;
  var _yearly = false;
  String? _error;
  String? _success;
  ResBillingSummary? _summary;
  String? _selectedSlug;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final summary = await billingSummaryGet(widget.conn);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load billing');
      });
    }
  }

  List<BillingPlanDoc> get _plans {
    final raw = _summary?.plans ?? <BillingPlanDoc>[];
    return billingPlanCatalogNormalize(raw.isNotEmpty ? raw : billingPlanCatalogFallback());
  }

  String get _currentTier {
    final tier = _summary?.planTier ?? AppStore.instance.planTier;
    return billingPlanIsFree(tier) ? 'lite' : tier.trim().toLowerCase();
  }

  String get _currency => AppStore.instance.wallet.billingCurrency;

  BillingPlanDoc? get _selectedPlan {
    final slug = _selectedSlug;
    if (slug == null) return null;
    for (final p in _plans) {
      if (p.slug == slug) return p;
    }
    return null;
  }

  BillingPlanDoc? get _litePlan {
    for (final p in _plans) {
      if (p.slug.trim().toLowerCase() == 'lite') return p;
    }
    return null;
  }

  bool get _selectedIsCurrent {
    final plan = _selectedPlan;
    if (plan == null) return false;
    return plan.slug.trim().toLowerCase() == _currentTier;
  }

  Future<void> _redeemPackage() async {
    final redeemed = await billingPackageRedeemDialog(context, conn: widget.conn);
    if (mounted && redeemed) await _load(showLoading: false);
  }

  Future<void> _subscribe() async {
    final plan = _selectedPlan;
    if (plan == null || _selectedIsCurrent || _subscribing) return;
    setState(() {
      _subscribing = true;
      _error = null;
      _success = null;
    });
    try {
      await billingPlanSubscribe(
        widget.conn,
        planSlug: plan.slug,
        billingPeriod: _yearly ? 'yearly' : 'monthly',
        currency: _currency,
      );
      if (!mounted) return;
      setState(() => _success = 'Subscribed to ${plan.name}');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiReferralError(e, fallback: 'Subscribe failed'));
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = AppStore.instance.billing;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final balanceLabel = billing != null
        ? billingWalletBalanceLabel(billing, _currency)
        : _summary != null
            ? billingBalanceLabel(BillingAccount(balanceUsd: _summary!.balanceUsd, balanceIdr: _summary!.balanceIdr, billingCurrency: _currency))
            : '';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plans', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Monthly included usage quotas in IDR', style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _redeemPackage,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: _muted,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.redeem_outlined, size: 15),
                  label: const Text('Redeem code'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(child: Center(child: UILoading()))
            else if (_error != null && _summary == null)
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, style: const TextStyle(color: Color(0xFFF87171))),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ),
              )
            else ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Monthly')),
                  ButtonSegment(value: true, label: Text('Yearly')),
                ],
                selected: {_yearly},
                onSelectionChanged: (s) => setState(() => _yearly = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _text : _muted),
                ),
              ),
              const SizedBox(height: 8),
              if (_success != null) Text(_success!, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
              if (_error != null && _summary != null) Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  children: _plans
                      .map((plan) => _BillingPlanCard(
                            plan: plan,
                            litePlan: _litePlan,
                            currency: _currency,
                            yearly: _yearly,
                            selected: plan.slug == _selectedSlug,
                            isCurrent: plan.slug.trim().toLowerCase() == _currentTier,
                            recommended: billingPlanIsRecommended(plan.slug),
                            onTap: () => setState(() => _selectedSlug = plan.slug),
                          ))
                      .toList(),
                ),
              ),
              if (balanceLabel.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14, color: _muted),
                    const SizedBox(width: 6),
                    Text('Balance $balanceLabel', style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: _subscribing || _selectedPlan == null || _selectedIsCurrent ? null : _subscribe,
                child: _subscribing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_selectedPlan == null
                        ? 'Choose a plan'
                        : _selectedIsCurrent
                            ? 'Current plan'
                            : 'Subscribe with balance'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BillingPlanCard extends StatelessWidget {
  const _BillingPlanCard({
    required this.plan,
    required this.litePlan,
    required this.currency,
    required this.yearly,
    required this.selected,
    required this.isCurrent,
    required this.recommended,
    required this.onTap,
  });

  final BillingPlanDoc plan;
  final BillingPlanDoc? litePlan;
  final String currency;
  final bool yearly;
  final bool selected;
  final bool isCurrent;
  final bool recommended;
  final VoidCallback onTap;

  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final accent = billingPlanAccentColor(plan.slug);
    final price = billingPlanPriceLabel(plan, currency: currency, yearly: yearly);
    final priceSub = billingPlanPriceSubLabel(plan, currency: currency, yearly: yearly);
    final quotaLines = billingPlanQuotaLines(plan, litePlan: litePlan);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? accent : _border, width: selected ? 1.5 : 1),
              color: selected ? accent.withValues(alpha: 0.06) : const Color(0xFF18181B),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan.name, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16)),
                            if (recommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                                child: Text('Popular', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ],
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(99)),
                                child: const Text('Current', style: TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(price, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 17)),
                        if (priceSub != null) Text(priceSub, style: const TextStyle(color: _muted, fontSize: 11)),
                        if (quotaLines.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...quotaLines.map(
                            (line) => line.kind == BillingPlanLineKind.sectionHeader
                                ? Padding(
                                    padding: EdgeInsets.only(top: line.label == 'Limits' ? 6 : 0, bottom: 4),
                                    child: Text(
                                      line.label,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        height: 1.2,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _BillingPlanQuotaLabel(line: line, accent: accent)),
                                        _BillingPlanQuotaValue(line: line, accent: accent),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? accent : _muted, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingPlanQuotaLabel extends StatelessWidget {
  const _BillingPlanQuotaLabel({required this.line, required this.accent});

  final BillingPlanQuotaLine line;
  final Color accent;

  static const _muted = Color(0xFFA1A1AA);

  @override
  Widget build(BuildContext context) {
    final cmp = line.label == 'Channels' || line.label == 'Computer use' || line.label == 'Image generation' ? null : line.comparison;
    if (cmp == null) return Text(line.label, style: const TextStyle(color: _muted, fontSize: 12, height: 1.25));
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: _muted, fontSize: 12, height: 1.25),
        children: [
          TextSpan(text: line.label),
          TextSpan(
            text: ' $cmp',
            style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _BillingPlanQuotaValue extends StatelessWidget {
  const _BillingPlanQuotaValue({required this.line, required this.accent});

  final BillingPlanQuotaLine line;
  final Color accent;

  static const _text = Color(0xFFE4E4E7);

  @override
  Widget build(BuildContext context) {
    final valueText = line.showsIncluded && line.value.isNotEmpty ? '${line.value} · Included' : line.value;
    if (valueText.isEmpty) return const SizedBox.shrink();
    return Text(
        valueText,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: line.valueAccent ? accent : _text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      );
  }
}
