import 'dart:convert';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

const _quickCashNominals = [10000, 20000, 50000, 100000, 200000];

Future<TxPayment?> askTransaksiPaymentCash({
  required BuildContext context,
  TxPayment? initial,
  int totalDue = 0,
}) =>
    showDialog<TxPayment>(
      context: context,
      builder: (ctx) => _DialogCash(initial: initial, totalDue: totalDue),
    );

class _DialogCash extends StatefulWidget {
  const _DialogCash({this.initial, this.totalDue = 0});

  final TxPayment? initial;
  final int totalDue;

  @override
  State<_DialogCash> createState() => _DialogCashState();
}

class _DialogCashState extends State<_DialogCash> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _paidCtrl;
  late int _total;
  var _paid = 0;

  int get _change => _paid - _total;

  @override
  void initState() {
    super.initState();
    _total = widget.totalDue > 0 ? widget.totalDue : (widget.initial?.amount.toInt() ?? 0);
    _paid = widget.initial != null && widget.initial!.amount > Int64.ZERO
        ? widget.initial!.amount.toInt()
        : _total;
    _noteCtrl = TextEditingController(text: widget.initial?.note ?? '');
    _paidCtrl = TextEditingController(text: _paid > 0 ? _paid.toString() : '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _setPaid(int amount) {
    setState(() {
      _paid = amount;
      _paidCtrl.text = amount.toString();
    });
  }

  TxPayment _build() {
    final effectivePayment = _paid > _total && _total > 0 ? _total : _paid;
    final change = _change > 0 ? _change : 0;
    final paymentJson = jsonEncode({
      'tendered': _paid,
      'change': change,
    });
    return TxPayment(
      method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
      amount: Int64(effectivePayment),
      note: _noteCtrl.text.trim(),
      paymentJson: paymentJson,
      tsMs: Int64(DateTime.now().millisecondsSinceEpoch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSufficient = _change >= 0;
    return AlertDialog(
      backgroundColor: const Color(0xFF121215),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      title: const Text('Bayar Tunai (Cash)', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Tagihan', style: TextStyle(color: _muted, fontSize: 13)),
                    Text(moneyFmtIdr(_total), style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _paidCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Uang Diterima (Tendered)',
                  labelStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  setState(() => _paid = parsed);
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    backgroundColor: const Color(0xFF18181B),
                    side: const BorderSide(color: _border),
                    label: const Text('Uang Pas', style: TextStyle(color: _accent, fontSize: 12)),
                    onPressed: () => _setPaid(_total),
                  ),
                  for (final nom in _quickCashNominals)
                    if (nom >= _total || _quickCashNominals.indexOf(nom) < 3)
                      ActionChip(
                        backgroundColor: const Color(0xFF18181B),
                        side: const BorderSide(color: _border),
                        label: Text(moneyFmtIdr(nom), style: const TextStyle(color: _text, fontSize: 12)),
                        onPressed: () => _setPaid(nom),
                      ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSufficient ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFF7F1D1D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSufficient ? const Color(0xFF059669) : Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _change < 0 ? 'Kurang Bayar' : 'Kembalian',
                      style: TextStyle(color: isSufficient ? _accent : Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      moneyFmtIdr(_change.abs()),
                      style: TextStyle(
                        color: isSufficient ? _accent : Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Catatan Pembayaran (Opsional)',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1B)),
          onPressed: _paid <= 0 ? null : () => Navigator.of(context).pop(_build()),
          child: const Text('Selesai Bayar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
