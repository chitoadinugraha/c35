import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/billing/ui_quota_ring.dart';
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
  String? _error;
  String? _success;
  ResBillingSummary? _summary;
  var _selectedSlug = 'free';

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
        _selectedSlug = summary.planTier.isNotEmpty ? summary.planTier : 'free';
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

  BillingPlanDoc? get _selectedPlan {
    for (final p in _plans) {
      if (p.slug == _selectedSlug) return p;
    }
    return null;
  }

  Future<void> _subscribe() async {
    final plan = _selectedPlan;
    if (plan == null || billingPlanIsFree(plan.slug) || _subscribing) return;
    setState(() {
      _subscribing = true;
      _error = null;
      _success = null;
    });
    try {
      await billingPlanSubscribe(widget.conn, planSlug: plan.slug);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          const Text('Plans', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: UILoading())
          else if (_error != null && _summary == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(_error!, style: const TextStyle(color: Color(0xFFF87171))),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ]),
            )
          else ...[
            if (billing != null)
              uiQuotaPackagePanelFromAccount(billing)
            else if (_summary != null)
              uiQuotaPackagePanelFromSummary(_summary!),
            const SizedBox(height: 12),
            if (_success != null) Text(_success!, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
            if (_error != null && _summary != null) Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ..._plans.map((plan) {
              final selected = plan.slug == _selectedSlug;
              final accent = billingPlanAccentColor(plan.slug);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedSlug = plan.slug),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? accent : _border, width: selected ? 1.5 : 1),
                      color: const Color(0xFF18181B),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(billingPlanAllowLabel(plan), style: const TextStyle(color: _muted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(billingPlanPriceLabel(plan), style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _subscribing || billingPlanIsFree(_selectedSlug) ? null : _subscribe,
              child: _subscribing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(billingPlanIsFree(_selectedSlug) ? 'Current free plan' : 'Subscribe with balance'),
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
    );
  }
}
