import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_admin_adjust.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

Future<ResBillingAdminAdjust?> referralWalletAdjustDialog(
  BuildContext context, {
  required ReferralConn conn,
  required int subjectUid,
  required String subjectName,
  required String kind,
  required bool credit,
  String currency = 'IDR',
}) =>
    showDialog<ResBillingAdminAdjust>(
      context: context,
      builder: (ctx) => _ReferralWalletAdjustDialog(
        conn: conn,
        subjectUid: subjectUid,
        subjectName: subjectName,
        kind: kind,
        credit: credit,
        currency: currency,
      ),
    );

class _ReferralWalletAdjustDialog extends StatefulWidget {
  const _ReferralWalletAdjustDialog({
    required this.conn,
    required this.subjectUid,
    required this.subjectName,
    required this.kind,
    required this.credit,
    required this.currency,
  });

  final ReferralConn conn;
  final int subjectUid;
  final String subjectName;
  final String kind;
  final bool credit;
  final String currency;

  @override
  State<_ReferralWalletAdjustDialog> createState() => _ReferralWalletAdjustDialogState();
}

class _ReferralWalletAdjustDialogState extends State<_ReferralWalletAdjustDialog> {
  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF22C55E);
  static const _errorColor = Color(0xFFF87171);

  late final _amountCtrl = TextEditingController();
  late final _noteCtrl = TextEditingController();
  var _reason = billingAdminAdjustReasons.first.id;
  var _busy = false;
  var _errorMsg = '';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _kindLabel => widget.kind == billingAdminAdjustKindCommission ? 'commission' : 'balance';

  Future<void> _submit() async {
    if (_busy) return;
    final amount = referralWithdrawAmountParse(_amountCtrl.text);
    final amountErr = referralWithdrawAmountValidate(amount);
    if (amountErr != null) {
      setState(() => _errorMsg = amountErr);
      return;
    }
    if (_reason == 'other' && _noteCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Note required for Other');
      return;
    }
    setState(() {
      _busy = true;
      _errorMsg = '';
    });
    try {
      final idr = referralCurrencyIsIdr(widget.currency) ? amount! : 0.0;
      final usd = referralCurrencyIsIdr(widget.currency) ? 0.0 : amount!;
      final res = await billingAdminAdjustPut(
        widget.conn,
        subjectUid: widget.subjectUid,
        kind: widget.kind,
        direction: widget.credit ? billingAdminAdjustDirCredit : billingAdminAdjustDirDebit,
        reason: _reason,
        note: _noteCtrl.text.trim(),
        currency: widget.currency,
        amountIdr: idr,
        amountUsd: usd,
      );
      if (!mounted) return;
      Navigator.pop(context, res);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorMsg = uiReferralError(e, fallback: 'Could not save adjustment.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          '${widget.credit ? 'Add' : 'Remove'} $_kindLabel',
          style: const TextStyle(color: _text),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.subjectName, style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: _text),
                decoration: UiInputDecoration.of(
                  context,
                  labelText: referralCurrencyIsIdr(widget.currency) ? 'Amount (IDR)' : 'Amount (USD)',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _reason,
                dropdownColor: _bg,
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: UiInputDecoration.of(context, labelText: 'Reason'),
                items: billingAdminAdjustReasons
                    .map((r) => DropdownMenuItem(value: r.id, child: Text(r.label)))
                    .toList(),
                onChanged: _busy ? null : (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: _text),
                decoration: UiInputDecoration.of(context, labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_errorMsg, style: const TextStyle(color: _errorColor, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: widget.credit ? _accent : _errorColor),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.credit ? 'Add' : 'Remove'),
          ),
        ],
      );
}
