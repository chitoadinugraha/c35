import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/io/in_referral_code.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_commission_breakdown.dart';
import 'package:alienai_c35/widgets/ui/ui_error.dart';
import 'package:flutter/material.dart';

Future<bool> billingPackageRedeemDialog(BuildContext context, {required ReferralConn conn}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => _BillingPackageRedeemDialog(conn: conn),
  );
  return res == true;
}

class _BillingPackageRedeemDialog extends StatefulWidget {
  const _BillingPackageRedeemDialog({required this.conn});

  final ReferralConn conn;

  @override
  State<_BillingPackageRedeemDialog> createState() => _BillingPackageRedeemDialogState();
}

class _BillingPackageRedeemDialogState extends State<_BillingPackageRedeemDialog> {
  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF22C55E);
  static const _border = Color(0xFF3F3F46);

  final _codeKey = GlobalKey<InFormattedReferralCodeFieldState>();
  Timer? _debounce;
  var _loading = false;
  var _redeeming = false;
  String? _error;
  ResBillingPackagePreview? _preview;
  String _codeNorm = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onCodeChanged(String norm) {
    _codeNorm = norm;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final err = referralPackageCodeFormValidate(_codeNorm);
    if (err != null) {
      setState(() {
        _preview = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await billingPackagePreview(widget.conn, code: _codeNorm);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to preview package');
      });
    }
  }

  Future<void> _redeem() async {
    final norm = _codeKey.currentState?.codeNorm ?? _codeNorm;
    final err = referralPackageCodeFormValidate(norm);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _redeeming = true;
      _error = null;
    });
    try {
      final res = await billingPackageRedeem(widget.conn, code: norm);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.packageName.trim().isNotEmpty
                ? 'Redeemed ${res.packageName} — Rp ${uiFmtGroupedInt(res.amountIdr.round())}'
                : 'Package redeemed — Rp ${uiFmtGroupedInt(res.amountIdr.round())}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _redeeming = false;
        _error = uiReferralError(e, fallback: 'Failed to redeem package');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final commission = preview?.commission;
    final canRedeem = preview != null && !_loading && !_redeeming;
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Redeem package', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: _redeeming ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 20, color: _muted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InFormattedReferralCodeField(
                    key: _codeKey,
                    autofocus: true,
                    labelText: 'Package code',
                    onChanged: _onCodeChanged,
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))),
                    ),
                  if (preview != null && commission != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      preview.packageName.trim().isNotEmpty ? preview.packageName : 'Package',
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: Rp ${uiFmtGroupedInt(preview.amountIdr.round())}${preview.planTier.trim().isNotEmpty ? ' · plan ${preview.planTier}' : ''}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    UiReferralCommissionBreakdown(
                      result: commission,
                      subjectUid: widget.conn.uid,
                      buyerName: 'You',
                      buyerPic: '',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    UIError(message: _error!, compact: true),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: canRedeem ? _redeem : null,
                      child: _redeeming
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                          : const Text('Redeem'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
