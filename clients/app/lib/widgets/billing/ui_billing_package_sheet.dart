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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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

  bool get _selectedIsCurrent {
    final plan = _selectedPlan;
    if (plan == null) return false;
    return plan.slug.trim().toLowerCase() == _currentTier;
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
            const Text('Plans', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Monthly included usage quotas in IDR', style: TextStyle(color: _muted, fontSize: 12)),
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (context.mounted) await billingPackageRedeemDialog(context, conn: widget.conn);
                },
                icon: const Icon(Icons.redeem_outlined),
                label: const Text('Redeem package code'),
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
    required this.currency,
    required this.yearly,
    required this.selected,
    required this.isCurrent,
    required this.recommended,
    required this.onTap,
  });

  final BillingPlanDoc plan;
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
    final quotaLines = billingPlanQuotaLines(plan);
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
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: Text(line.label, style: const TextStyle(color: _muted, fontSize: 12, height: 1.25)),
                                  ),
                                  Expanded(
                                    flex: 12,
                                    child: Text(
                                      line.value,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: line.label == 'Priority' ? accent : _text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
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
