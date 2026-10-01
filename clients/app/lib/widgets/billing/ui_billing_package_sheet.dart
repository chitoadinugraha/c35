import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/billing/billing_platform.dart';
import 'package:alienai_c35/c/billing/billing_play_api.dart';
import 'package:alienai_c35/c/billing/billing_play_checkout.dart';
import 'package:alienai_c35/c/billing/billing_store_sync.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_purchase_success_dialog.dart';
import 'package:alienai_c35/widgets/referral/ui_billing_package_redeem.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _sheetBg = Color(0xFF121215);
const _cardBg = Color(0xFF18181B);
const _panelBg = Color(0xFF0F0F12);
const _text = Color(0xFFE4E4E7);
const _muted = Color(0xFFA1A1AA);
const _border = Color(0xFF27272A);
const _ok = Color(0xFF34D399);
const _danger = Color(0xFFF87171);
const _warn = Color(0xFFFBBF24);

Future<void> billingPackageSheet(BuildContext context, {required ReferralConn conn}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _sheetBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(child: _BillingPackageSheet(conn: conn)),
    ),
  );
}

class _BillingPackageSheet extends StatefulWidget {
  const _BillingPackageSheet({required this.conn});

  final ReferralConn conn;

  @override
  State<_BillingPackageSheet> createState() => _BillingPackageSheetState();
}

class _BillingPackageSheetState extends State<_BillingPackageSheet> {
  var _loading = true;
  var _subscribing = false;
  var _yearly = false;
  var _quoteLoading = false;
  String? _error;
  String? _successMessage;
  ResBillingSummary? _summary;
  ResBillingPlanQuote? _quote;
  String? _selectedSlug;
  Timer? _quoteDebounce;

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    super.dispose();
  }

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
      AppStore.instance.billingPut(billingAccountFromSummary(summary, base: AppStore.instance.billing));
      final yearly = summary.billingPeriod.trim().toLowerCase() == 'yearly';
      setState(() {
        _summary = summary;
        _loading = false;
        _yearly = yearly;
        _selectedSlug ??= _defaultSelectedSlug(summary);
      });
      _scheduleQuote();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load billing');
      });
    }
  }

  String _defaultSelectedSlug(ResBillingSummary summary) {
    final plans = billingPlanCatalogNormalize(
      (summary.plans.isNotEmpty ? summary.plans : billingPlanCatalogFallback()).where((p) => !billingPlanIsFree(p.slug)),
    );
    final tier = (summary.planTier.trim().isEmpty ? AppStore.instance.planTier : summary.planTier).trim().toLowerCase();
    final active = billingPlanIsFree(tier) ? '' : tier;
    if (active.isNotEmpty) {
      for (final p in plans) {
        if (p.slug.trim().toLowerCase() == active) return p.slug;
      }
    }
    for (final p in plans) {
      if (billingPlanIsRecommended(p.slug)) return p.slug;
    }
    return plans.isNotEmpty ? plans.first.slug : 'lite';
  }

  List<BillingPlanDoc> get _plans {
    final raw = _summary?.plans ?? <BillingPlanDoc>[];
    return billingPlanCatalogNormalize(raw.isNotEmpty ? raw : billingPlanCatalogFallback());
  }

  String get _activePlanSlug {
    final tier = (_summary?.planTier ?? AppStore.instance.planTier).trim().toLowerCase();
    return billingPlanIsFree(tier) ? 'free' : tier;
  }

  String get _activeBillingPeriod => (_summary?.billingPeriod ?? 'monthly').trim().toLowerCase();

  String get _selectionPeriod => _yearly ? 'yearly' : 'monthly';

  bool get _selectionIsNoPlan => _selectedSlug == billingPlanNoPlanSlug;

  BillingPlanDoc? get _selectedPlan {
    if (_selectionIsNoPlan) return null;
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

  String get _currency => billingPrimaryCurrency(AppStore.instance.billing ?? BillingAccount(billingCurrency: moneyDefaultCurrency));

  BillingAccount get _balanceAccount =>
      AppStore.instance.billing ??
      (_summary != null
          ? BillingAccount(
              balanceUsd: _summary!.balanceUsd,
              balanceIdr: _summary!.balanceIdr,
              billingCurrency: billingCurrencyResolve(fromSummary: _summary!.hasBillingCurrency() ? _summary!.billingCurrency : null),
              fxMicroPerUsd: _summary!.hasFxMicroPerUsd() ? _summary!.fxMicroPerUsd : Int64(moneyDefaultFxMicroPerUsd),
            )
          : BillingAccount(billingCurrency: _currency));

  /// Play Billing only supports fixed subscription SKUs (full monthly/yearly list price).
  bool _usePlayForCharge(String kind, double chargeIdr) {
    final k = kind.trim().toLowerCase();
    if (!billingUsePlayPlans() || _selectionIsNoPlan || chargeIdr <= 0) return false;
    if (k != 'subscribe') return false;
    if (_currency != 'IDR') return false;
    final list = _quote?.listPriceIdr ?? 0;
    if (list <= 0 || chargeIdr.round() != list.round()) return false;
    return !billingCreditCoversCharge(_balanceAccount, currency: _currency, chargeIdr: chargeIdr);
  }

  String _payButtonSuffix(double chargeIdr, String kind) {
    if (chargeIdr <= 0 || _currency != 'IDR') return '';
    final k = kind.trim().toLowerCase();
    if (k == 'upgrade') return ' from credit';
    if (_usePlayForCharge(kind, chargeIdr)) return ' with Google Play';
    return ' from credit';
  }

  bool get _selectedIsCurrent {
    if (_selectedSlug == null) return false;
    if (_selectionIsNoPlan) {
      final pending = (_summary?.pendingPlanSlug ?? '').trim().toLowerCase();
      return pending == 'free' && billingPlanIsPaidTier(_activePlanSlug);
    }
    final plan = _selectedPlan;
    if (plan == null) return false;
    return plan.slug.trim().toLowerCase() == _activePlanSlug && _selectionPeriod == _activeBillingPeriod;
  }

  void _scheduleQuote() {
    _quoteDebounce?.cancel();
    if (_selectedSlug == null) {
      setState(() {
        _quote = null;
        _quoteLoading = false;
      });
      return;
    }
    setState(() => _quoteLoading = true);
    _quoteDebounce = Timer(const Duration(milliseconds: 280), () => unawaited(_loadQuote()));
  }

  Future<void> _loadQuote() async {
    final slug = _selectedSlug;
    if (slug == null) return;
    try {
      final quote = await billingPlanQuote(
        widget.conn,
        planSlug: slug,
        billingPeriod: _selectionPeriod,
        currency: _currency,
      );
      if (!mounted || slug != _selectedSlug || _selectionPeriod != (_yearly ? 'yearly' : 'monthly')) return;
      setState(() {
        _quote = quote;
        _quoteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _quoteLoading = false);
    }
  }

  String get _primaryButtonLabel {
    if (_selectedSlug == null) return 'Choose a plan';
    if (_selectedIsCurrent) return 'Current plan';
    final kind = (_quote?.kind ?? '').trim().toLowerCase();
    if (kind == 'same') return 'Current plan';
    if (kind == 'upgrade') {
      final charge = _quote?.chargeIdr ?? 0;
      if (charge > 0 && _currency == 'IDR') {
        return 'Pay ${billingFmtRp(charge)}${_payButtonSuffix(charge, kind)} (prorated)';
      }
      return 'Upgrade now';
    }
    if (kind == 'downgrade' || kind == 'cancel') return 'Schedule at period end';
    final charge = _quote?.chargeIdr ?? 0;
    if (charge > 0 && _currency == 'IDR') {
      return 'Pay ${billingFmtRp(charge)}${_payButtonSuffix(charge, kind)}';
    }
    return 'Confirm plan change';
  }

  Future<void> _redeemPackage() async {
    final redeemed = await billingPackageRedeemDialog(context, conn: widget.conn);
    if (mounted && redeemed) await _load(showLoading: false);
  }

  Future<void> _applyPlanChange() async {
    final slug = _selectedSlug;
    if (slug == null || _selectedIsCurrent || _subscribing) return;
    setState(() {
      _subscribing = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final kind = (_quote?.kind ?? '').trim().toLowerCase();
      final charge = _quote?.chargeIdr ?? 0;
      if (_usePlayForCharge(kind, charge)) {
        final catalog = await billingPlayProductList(widget.conn);
        final plans = billingPlayPlanProducts(catalog.products);
        final product = billingPlayProductMatch(
          plans,
          planSlug: slug,
          billingPeriod: _selectionPeriod,
        );
        if (product == null) throw 'This plan is not available on Google Play yet';
        final verified = await billingPlayPurchaseAndVerify(
          widget.conn,
          product: product,
        );
        if (!mounted) return;
        await billingPurchaseSuccessDialogShow(
          context,
          entitlements: verified.entitlements,
          highlightEntitlementId: verified.entitlementId,
          title: 'Plan updated',
          subtitle: _selectedPlan?.name ?? slug,
        );
        await _load();
        _scheduleQuote();
        return;
      }
      if (billingUsePlayPlans() &&
          kind == 'upgrade' &&
          charge > 0 &&
          !billingCreditCoversCharge(_balanceAccount, currency: _currency, chargeIdr: charge)) {
        throw 'Not enough credit for this upgrade. Prorated plan changes on Android use account credit only.';
      }
      await billingPlanChangeAndSync(
        widget.conn,
        planSlug: slug,
        billingPeriod: _selectionPeriod,
        currency: _currency,
      );
      if (!mounted) return;
      final label = _selectionIsNoPlan ? 'No plan scheduled' : (_selectedPlan?.name ?? slug);
      setState(() => _successMessage = 'Updated: $label');
      await _load();
      _scheduleQuote();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiReferralError(e, fallback: 'Plan change failed'));
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  void _selectSlug(String slug) => setState(() {
        _selectedSlug = slug;
        _scheduleQuote();
      });

  @override
  Widget build(BuildContext context) {
    final billing = AppStore.instance.billing;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final balanceAccount = billing ??
        (_summary != null
            ? BillingAccount(
                balanceUsd: _summary!.balanceUsd,
                balanceIdr: _summary!.balanceIdr,
                billingCurrency: billingCurrencyResolve(fromSummary: _summary!.hasBillingCurrency() ? _summary!.billingCurrency : null),
                fxMicroPerUsd: _summary!.hasFxMicroPerUsd() ? _summary!.fxMicroPerUsd : Int64(moneyDefaultFxMicroPerUsd),
              )
            : null);
    final balanceLabel = balanceAccount != null ? billingCreditBalanceLabel(balanceAccount, _currency) : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plans', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(
                        _currency == 'IDR' ? 'Monthly usage quotas · prices in IDR' : 'Monthly usage quotas · $_currency',
                        style: const TextStyle(color: _muted, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _redeemPackage,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: _muted,
                    backgroundColor: _cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _border)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.redeem_outlined, size: 15),
                  label: const Text('Redeem'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody(balanceLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String balanceLabel) {
    if (_loading) return const Center(child: UILoading());
    if (_error != null && _summary == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: _danger)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillingPeriodToggle(
          yearly: _yearly,
          onChanged: (y) => setState(() {
            _yearly = y;
            _scheduleQuote();
          }),
        ),
        const SizedBox(height: 10),
        if (_successMessage != null) _BillingBanner(message: _successMessage!, color: _ok, icon: Icons.check_circle_outline),
        if (_error != null && _summary != null) ...[
          if (_successMessage != null) const SizedBox(height: 6),
          _BillingBanner(message: _error!, color: _danger, icon: Icons.error_outline),
        ],
        if ((_summary?.pendingPlanSlug ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _BillingBanner(message: _pendingPlanHint(_summary!), color: _warn, icon: Icons.schedule_outlined),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            children: [
              ..._plans.map(
                (plan) => _BillingPlanCard(
                  plan: plan,
                  litePlan: _litePlan,
                  currency: _currency,
                  yearly: _yearly,
                  selected: plan.slug == _selectedSlug,
                  expanded: plan.slug == _selectedSlug,
                  isCurrent: plan.slug.trim().toLowerCase() == _activePlanSlug && _activeBillingPeriod == _selectionPeriod,
                  recommended: billingPlanIsRecommended(plan.slug),
                  onTap: () => _selectSlug(plan.slug),
                ),
              ),
              if (billingPlanIsPaidTier(_activePlanSlug) || (_summary?.pendingPlanSlug ?? '').isNotEmpty)
                _BillingNoPlanCard(
                  selected: _selectionIsNoPlan,
                  expanded: _selectionIsNoPlan,
                  onTap: () => _selectSlug(billingPlanNoPlanSlug),
                ),
            ],
          ),
        ),
        _BillingCheckoutBar(
          quote: _quote,
          quoteLoading: _quoteLoading,
          selectedSlug: _selectedSlug,
          currency: _currency,
          balanceLabel: balanceLabel,
          buttonLabel: _primaryButtonLabel,
          subscribing: _subscribing,
          buttonEnabled: !_subscribing && _selectedSlug != null && !_selectedIsCurrent && (_quote?.kind != 'same'),
          onConfirm: _applyPlanChange,
        ),
      ],
    );
  }

  String _pendingPlanHint(ResBillingSummary summary) {
    final pending = summary.pendingPlanSlug.trim().toLowerCase();
    if (pending.isEmpty) return '';
    if (pending == 'free') return 'After this period: daily free limits (Alien AI only).';
    final period = summary.pendingBillingPeriod.trim().isEmpty ? '' : ' (${summary.pendingBillingPeriod})';
    return 'Scheduled change: ${billingPlanTierLabel(pending)}$period at period end.';
  }
}

class _BillingPeriodToggle extends StatelessWidget {
  const _BillingPeriodToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              const ButtonSegment(value: false, label: Text('Monthly')),
              ButtonSegment(
                value: true,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Yearly'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: _ok.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('−20%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _ok)),
                    ),
                  ],
                ),
              ),
            ],
            selected: {yearly},
            onSelectionChanged: (s) => onChanged(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _text : _muted),
            ),
          ),
          if (yearly)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 2),
              child: Text('+20% Alien AI pool on yearly billing', style: TextStyle(color: _ok, fontSize: 10, height: 1.25)),
            ),
        ],
      );
}

class _BillingBanner extends StatelessWidget {
  const _BillingBanner({required this.message, required this.color, required this.icon});

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 11, height: 1.35, fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

class _BillingCheckoutBar extends StatelessWidget {
  const _BillingCheckoutBar({
    required this.quote,
    required this.quoteLoading,
    required this.selectedSlug,
    required this.currency,
    required this.balanceLabel,
    required this.buttonLabel,
    required this.subscribing,
    required this.buttonEnabled,
    required this.onConfirm,
  });

  final ResBillingPlanQuote? quote;
  final bool quoteLoading;
  final String? selectedSlug;
  final String currency;
  final String balanceLabel;
  final String buttonLabel;
  final bool subscribing;
  final bool buttonEnabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _border)),
          color: _sheetBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (quote != null && selectedSlug != null)
              _BillingPlanQuotePanel(quote: quote!, currency: currency, loading: quoteLoading)
            else if (quoteLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            if (balanceLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 14, color: _muted),
                  const SizedBox(width: 6),
                  Text('Credit $balanceLabel', style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: buttonEnabled ? onConfirm : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: subscribing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      );
}

class _BillingPlanCard extends StatelessWidget {
  const _BillingPlanCard({
    required this.plan,
    required this.litePlan,
    required this.currency,
    required this.yearly,
    required this.selected,
    required this.expanded,
    required this.isCurrent,
    required this.recommended,
    required this.onTap,
  });

  final BillingPlanDoc plan;
  final BillingPlanDoc? litePlan;
  final String currency;
  final bool yearly;
  final bool selected;
  final bool expanded;
  final bool isCurrent;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = billingPlanAccentColor(plan.slug);
    final price = billingPlanPriceLabel(plan, currency: currency, yearly: yearly);
    final priceSub = billingPlanPriceSubLabel(plan, currency: currency, yearly: yearly);
    final quotaLines = billingPlanQuotaLines(plan, litePlan: litePlan, yearly: yearly);
    final chips = billingPlanSummaryChips(plan, yearly: yearly);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? accent : _border, width: selected ? 2 : 1),
              color: selected ? Color.alphaBlend(accent.withValues(alpha: 0.08), _cardBg) : _cardBg,
              boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected)
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      gradient: LinearGradient(colors: [accent.withValues(alpha: 0.2), accent]),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(plan.name, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
                                    if (recommended) _BillingPlanBadge(label: 'Popular', color: accent),
                                    if (isCurrent) const _BillingPlanBadge(label: 'Current', color: _text, filled: true),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(price, style: const TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4)),
                                if (priceSub != null) Text(priceSub, style: const TextStyle(color: _muted, fontSize: 11, height: 1.3)),
                              ],
                            ),
                          ),
                          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? accent : _muted, size: 24),
                        ],
                      ),
                      if (!expanded && chips.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _BillingPlanChipRow(chips: chips, accent: accent),
                      ],
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 220),
                        crossFadeState: expanded && quotaLines.isNotEmpty ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        sizeCurve: Curves.easeOutCubic,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _BillingPlanDetailPanel(lines: quotaLines, accent: accent),
                        ),
                      ),
                      if (!expanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Tap to compare features', style: TextStyle(color: _muted.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingPlanBadge extends StatelessWidget {
  const _BillingPlanBadge({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: filled ? _border : color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: TextStyle(color: filled ? _text : color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class _BillingPlanChipRow extends StatelessWidget {
  const _BillingPlanChipRow({required this.chips, required this.accent});

  final List<String> chips;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips
            .map(
              (c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _panelBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(c, style: const TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
              ),
            )
            .toList(),
      );
}

class _BillingPlanDetailPanel extends StatelessWidget {
  const _BillingPlanDetailPanel({required this.lines, required this.accent});

  final List<BillingPlanQuotaLine> lines;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines.length; i++) ...[
              if (lines[i].kind == BillingPlanLineKind.sectionHeader)
                Padding(
                  padding: EdgeInsets.only(top: lines[i].label == 'Limits' ? 8 : 0, bottom: 8),
                  child: _BillingSectionHeader(title: lines[i].label),
                )
              else
                Padding(
                  padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 8),
                  child: _BillingPlanQuotaRow(line: lines[i], accent: accent),
                ),
            ],
          ],
        ),
      );
}

class _BillingSectionHeader extends StatelessWidget {
  const _BillingSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: _border, height: 1)),
        ],
      );
}

class _BillingNoPlanCard extends StatelessWidget {
  const _BillingNoPlanCard({required this.selected, required this.expanded, required this.onTap});

  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  static const _accent = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? _accent : _border, width: selected ? 2 : 1),
                color: selected ? _accent.withValues(alpha: 0.06) : _cardBg,
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
                          const Text('No plan', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            expanded
                                ? 'Your paid plan stays active until the period ends. After that, daily free limits apply (Alien AI only).'
                                : 'Cancel paid plan at period end',
                            style: const TextStyle(color: _muted, fontSize: 11, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? _accent : _muted, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _BillingPlanQuotePanel extends StatelessWidget {
  const _BillingPlanQuotePanel({required this.quote, required this.currency, required this.loading});

  final ResBillingPlanQuote quote;
  final String currency;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          color: _cardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(quote.summary, style: const TextStyle(color: _text, fontSize: 12, height: 1.35, fontWeight: FontWeight.w500)),
            if (quote.lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...quote.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(line.label, style: const TextStyle(color: _muted, fontSize: 11))),
                      Text(
                        line.isCredit ? '−${billingFmtRp(line.amountIdr)}' : billingFmtRp(line.amountIdr),
                        style: TextStyle(
                          color: line.isCredit ? _ok : _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (quote.yearlyAlienBonus)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Yearly billing: +20% Alien AI pool, 5h, and weekly allowance.',
                  style: TextStyle(color: _ok, fontSize: 10, height: 1.3),
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
      );
}

class _BillingPlanQuotaRow extends StatelessWidget {
  const _BillingPlanQuotaRow({required this.line, required this.accent});

  final BillingPlanQuotaLine line;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cmp = billingPlanQuotaLineSkipsComparison(line.label) ? null : line.comparison;
    final value = line.value.trim();
    final isIncludedOnly = value.toLowerCase() == 'included';
    final showIncludedTag = line.showsIncluded && value.isNotEmpty && !isIncludedOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.label, style: const TextStyle(color: _text, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500)),
                  if (cmp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(cmp, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600, height: 1.25)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isIncludedOnly)
              _BillingIncludedPill(accent: accent)
            else if (value.isNotEmpty)
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: line.valueAccent ? accent : _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (showIncludedTag) Padding(padding: const EdgeInsets.only(top: 4), child: _BillingIncludedPill(accent: accent)),
                  ],
                ),
              ),
          ],
        ),
        if (line.info != null && line.info!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 0),
            child: Text(line.info!, style: const TextStyle(color: _muted, fontSize: 10, height: 1.4)),
          ),
      ],
    );
  }
}

class _BillingIncludedPill extends StatelessWidget {
  const _BillingIncludedPill({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: accent),
            const SizedBox(width: 3),
            Text('Included', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
