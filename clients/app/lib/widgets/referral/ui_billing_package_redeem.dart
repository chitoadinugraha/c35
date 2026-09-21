import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_commission_breakdown.dart';
import 'package:alienai_c35/widgets/ui/ui_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

Future<void> billingPackageRedeemDialog(BuildContext context, {required ReferralConn conn}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _BillingPackageRedeemDialog(conn: conn),
  );
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

  late final _codeCtrl = TextEditingController();
  Timer? _debounce;
  var _loading = false;
  var _redeeming = false;
  String? _error;
  ResBillingPackagePreview? _preview;

  @override
  void dispose() {
    _debounce?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onCodeChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final err = referralPackageCodeFormValidate(_codeCtrl.text);
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
      final preview = await billingPackagePreview(widget.conn, code: referralCodeNorm(_codeCtrl.text));
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
    final err = referralPackageCodeFormValidate(_codeCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _redeeming = true;
      _error = null;
    });
    try {
      final res = await billingPackageRedeem(widget.conn, code: referralCodeNorm(_codeCtrl.text));
      if (!mounted) return;
      Navigator.pop(context);
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
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3F3F46))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Redeem package', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _codeCtrl,
                onChanged: _onCodeChanged,
                style: const TextStyle(color: _text, fontFamily: 'monospace', letterSpacing: 1.2),
                textCapitalization: TextCapitalization.characters,
                decoration: UiInputDecoration.of(context, labelText: 'Package code', hintText: referralCodeHint),
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
              Row(
                children: [
                  TextButton(onPressed: _redeeming ? null : () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
                  const Spacer(),
                  FilledButton(
                    onPressed: _redeeming || preview == null ? null : _redeem,
                    child: _redeeming
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                        : const Text('Redeem'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
