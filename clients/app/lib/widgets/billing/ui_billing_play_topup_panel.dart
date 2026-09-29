import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_play_api.dart';
import 'package:alienai_c35/c/billing/billing_play_checkout.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_topup.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_purchase_success_dialog.dart';
import 'package:flutter/material.dart';

class UiBillingPlayTopupPanel extends StatefulWidget {
  const UiBillingPlayTopupPanel({super.key, required this.conn, this.onSubmitted});

  final ReferralConn conn;
  final VoidCallback? onSubmitted;

  @override
  State<UiBillingPlayTopupPanel> createState() => _UiBillingPlayTopupPanelState();
}

class _UiBillingPlayTopupPanelState extends State<UiBillingPlayTopupPanel> {
  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF34D399);
  static const _border = Color(0xFF27272A);

  var _loading = true;
  var _busy = false;
  String? _error;
  List<BillingPlayProductDoc> _credits = const [];

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
      final res = await billingPlayProductList(widget.conn);
      if (!mounted) return;
      setState(() {
        _credits = res.products.where((p) => p.kind == 'credit').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load Play top-up options');
      });
    }
  }

  Future<void> _buy(BillingPlayProductDoc product) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ids = _credits.map((p) => p.productId).toSet();
      final verified = await billingPlayPurchaseAndVerify(widget.conn, product: product, queryIds: ids);
      if (!mounted) return;
      widget.onSubmitted?.call();
      await billingPurchaseSuccessDialogShow(
        context,
        entitlements: verified.entitlements,
        highlightEntitlementId: verified.entitlementId,
        title: 'Top-up complete',
        subtitle: 'Wallet credit via Google Play',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiReferralError(e, fallback: 'Play purchase failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2, color: _accent)));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Top up via Google Play', style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Prices include Play billing fee. Credit applies after Google confirms payment.', style: TextStyle(color: _muted, fontSize: 12, height: 1.35)),
        const SizedBox(height: 14),
        if (_credits.isEmpty)
          Text(_error ?? 'No Play credit packs configured.', style: const TextStyle(color: _muted, fontSize: 12))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _credits
                .map(
                  (p) => ActionChip(
                    label: Text(billingTopupIdrLabel(p.playPriceIdr > 0 ? p.playPriceIdr : p.creditIdr)),
                    backgroundColor: const Color(0xFF1A1A1E),
                    labelStyle: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12),
                    side: const BorderSide(color: _border),
                    onPressed: _busy ? null : () => unawaited(_buy(p)),
                  ),
                )
                .toList(),
          ),
        if (_error != null && _credits.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
        ],
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))),
          const SizedBox(height: 6),
          const Text('Waiting for Google Play…', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
        ],
      ],
    );
  }
}
