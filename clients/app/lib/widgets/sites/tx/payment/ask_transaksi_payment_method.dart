import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/sites/tx/payment/ask_transaksi_payment_cash.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<TxPayment?> askTransaksiPaymentMethod({
  required BuildContext context,
  required int totalDue,
}) =>
    showModalBottomSheet<TxPayment>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: _border),
      ),
      builder: (ctx) => _SheetPaymentMethod(totalDue: totalDue),
    );

class _SheetPaymentMethod extends StatefulWidget {
  const _SheetPaymentMethod({required this.totalDue});

  final int totalDue;

  @override
  State<_SheetPaymentMethod> createState() => _SheetPaymentMethodState();
}

class _SheetPaymentMethodState extends State<_SheetPaymentMethod> {
  late final TextEditingController _amountCtrl;
  late int _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.totalDue > 0 ? widget.totalDue : 0;
    _amountCtrl = TextEditingController(text: _amount > 0 ? moneyFmtIdrGrouped(_amount) : '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int get _payAmount {
    final parsed = moneyParseIdrInt(_amountCtrl.text) ?? _amount;
    if (parsed <= 0) return 0;
    if (widget.totalDue > 0 && parsed > widget.totalDue) return widget.totalDue;
    return parsed;
  }

  Future<void> _pick(TxPaymentMethod method) async {
    final amount = _payAmount;
    if (amount <= 0) return;

    if (method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH) {
      final payment = await askTransaksiPaymentCash(context: context, totalDue: amount);
      if (!mounted) return;
      Navigator.of(context).pop(payment);
      return;
    }

    final p = TxPayment(
      method: method,
      amount: Int64(amount),
      tsMs: Int64(DateTime.now().millisecondsSinceEpoch),
    );
    if (!mounted) return;
    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Pilih Metode Pembayaran', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: moneyIdrInputFormatters,
                style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Nominal bayar',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                ),
                onChanged: (v) => setState(() => _amount = moneyParseIdrInt(v) ?? 0),
              ),
              if (widget.totalDue > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Belum dibayar: ${moneyFmtIdr(widget.totalDue)}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),
              _methodTile(
                icon: Icons.payments_outlined,
                title: 'Tunai (Cash)',
                subtitle: 'Hitung kembalian dan pecahan uang',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
                highlight: true,
              ),
              _methodTile(
                icon: Icons.qr_code_2_outlined,
                title: 'QRIS',
                subtitle: 'GoPay, OVO, Dana, BCA, Mandiri, ShopeePay',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_QRIS,
              ),
              _methodTile(
                icon: Icons.account_balance_outlined,
                title: 'Transfer Bank',
                subtitle: 'BCA, BRI, Mandiri, BNI',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_TRANSFER,
              ),
              _methodTile(
                icon: Icons.credit_card_outlined,
                title: 'Kartu Debit / Kredit (EDC)',
                subtitle: 'Visa, Mastercard, GPN',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_CARD,
              ),
              _methodTile(
                icon: Icons.assignment_late_outlined,
                title: 'Hutang',
                subtitle: 'Dicatat sebagai piutang pelanggan',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_DEBT,
              ),
            ],
          ),
        ),
      );

  Widget _methodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required TxPaymentMethod method,
    bool highlight = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: highlight ? _accent.withValues(alpha: 0.08) : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: highlight ? _accent.withValues(alpha: 0.3) : _border),
        ),
        child: ListTile(
          dense: true,
          enabled: _payAmount > 0,
          leading: Icon(icon, color: highlight ? _accent : _muted, size: 24),
          title: Text(title, style: TextStyle(color: _text, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: _muted, size: 18),
          onTap: () => _pick(method),
        ),
      );
}
