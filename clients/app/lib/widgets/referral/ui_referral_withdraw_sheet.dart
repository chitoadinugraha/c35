import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/bank/bank_list.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_topup.dart';
import 'package:alienai_c35/widgets/ui/ui_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> referralCommissionWithdrawSheet(
  BuildContext context, {
  required ReferralConn conn,
  String registeredName = '',
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black54,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.92),
            child: SingleChildScrollView(child: _ReferralWithdrawSheet(conn: conn, registeredName: registeredName)),
          ),
        ),
      ),
    );

class _ReferralWithdrawSheet extends StatefulWidget {
  const _ReferralWithdrawSheet({required this.conn, required this.registeredName});

  final ReferralConn conn;
  final String registeredName;

  @override
  State<_ReferralWithdrawSheet> createState() => _ReferralWithdrawSheetState();
}

class _ReferralWithdrawSheetState extends State<_ReferralWithdrawSheet> {
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF34D399);

  late final _amountCtrl = TextEditingController();
  late final _acctCtrl = TextEditingController();
  late final _nameCtrl = TextEditingController(text: widget.registeredName);
  var _payoutMethod = referralWithdrawPayoutBank;
  var _bankId = 'bca';
  var _busy = false;
  var _availIdr = 0.0;
  String? _error;
  var _submitted = false;

  bool get _bankPayout => _payoutMethod == referralWithdrawPayoutBank;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAvailable());
    BankList.load().then((banks) {
      if (!mounted || banks.isEmpty) return;
      setState(() => _bankId = banks.first.id);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _acctCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailable() async {
    try {
      final summary = await billingSummaryGet(widget.conn);
      if (!mounted) return;
      setState(() => _availIdr = summary.commissionAvailableIdr);
    } catch (_) {}
  }

  int? _amountParsed() => billingTopupParseIdr(_amountCtrl.text);

  String? _validate() => _payoutMethod == referralWithdrawPayoutWallet
      ? referralWithdrawAmountValidate(_amountParsed()?.toDouble())
          ?? ((_amountParsed() ?? 0) > _availIdr ? 'Insufficient commission balance' : null)
      : referralWithdrawBankValidate(
          bankId: _bankId,
          accountNumber: _acctCtrl.text,
          accountName: _nameCtrl.text,
          registeredName: widget.registeredName,
          amount: _amountParsed(),
          availableIdr: _availIdr,
        );

  Future<void> _submit() async {
    if (_busy) return;
    final err = _validate();
    if (err != null) {
      setState(() {
        _error = err;
        _submitted = false;
      });
      return;
    }
    final amount = _amountParsed()!.toDouble();
    setState(() {
      _busy = true;
      _error = null;
      _submitted = false;
    });
    try {
      final res = await commissionWithdraw(
        widget.conn,
        amountIdr: amount,
        payoutMethod: _payoutMethod,
        bankId: _bankPayout ? _bankId : '',
        accountNumber: _bankPayout ? _acctCtrl.text.trim() : '',
        accountName: _bankPayout ? _nameCtrl.text.trim() : '',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitted = true;
        _availIdr = res.commissionAvailableIdr;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Withdraw failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountParsed() ?? 0;
    final canSubmit = amount > 0 && amount <= _availIdr && !_busy && !_submitted && (_bankPayout ? _bankId.isNotEmpty && _acctCtrl.text.trim().isNotEmpty && _nameCtrl.text.trim().isNotEmpty : true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF3F3F46))), color: Color(0xFF27272A)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0x1F10B981), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withValues(alpha: 0.25))),
                child: const Icon(Icons.account_balance_outlined, size: 20, color: _accent),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Withdraw commission', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700))),
              IconButton(onPressed: _busy ? null : () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20, color: _muted), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: referralWithdrawPayoutBank, label: Text('Bank transfer'), icon: Icon(Icons.account_balance_outlined, size: 14)),
                  ButtonSegment(value: referralWithdrawPayoutWallet, label: Text('Wallet credit'), icon: Icon(Icons.account_balance_wallet_outlined, size: 14)),
                ],
                selected: {_payoutMethod},
                onSelectionChanged: _busy ? null : (s) => setState(() => _payoutMethod = s.first),
              ),
              if (_bankPayout) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0x1FF59E0B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66F59E0B))),
                  child: const Text('Account holder name must match your registered name exactly.', style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFFDE68A))),
                ),
                if (widget.registeredName.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Registered name: ${widget.registeredName.trim()}', style: const TextStyle(color: _muted, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('bank-$_bankId'),
                  initialValue: _bankId,
                  decoration: UiInputDecoration.of(context, floatingLabel: false, isDense: true),
                  items: bankListFallback.map((b) => DropdownMenuItem(value: b.id, child: Text(b.shortName))).toList(),
                  onChanged: _busy ? null : (v) => setState(() => _bankId = v ?? _bankId),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _acctCtrl,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, hintText: 'Account number'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  enabled: !_busy,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, hintText: 'Atas nama'),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Text('Credit commission to your wallet balance.', style: TextStyle(color: _muted, fontSize: 12, height: 1.4)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: _text),
                decoration: UiInputDecoration.of(context, hintText: 'Amount (IDR)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text('Available: ${moneyFmtIdr(_availIdr)}', style: const TextStyle(color: _muted, fontSize: 12)),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: UIError(message: _error!, compact: true)),
              if (_submitted) ...[
                const SizedBox(height: 16),
                Text('Available ${moneyFmtIdr(_availIdr)}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Withdrawal request submitted for review.', style: TextStyle(color: _text, fontSize: 13)),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF3F3F46)))),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                  onPressed: canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                      : const Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
