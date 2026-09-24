import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
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
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: _border),
      ),
      builder: (ctx) => _SheetPaymentMethod(totalDue: totalDue),
    );

class _SheetPaymentMethod extends StatelessWidget {
  const _SheetPaymentMethod({required this.totalDue});

  final int totalDue;

  void _pick(BuildContext context, TxPaymentMethod method) async {
    if (method == TxPaymentMethod.TX_PAYMENT_METHOD_CASH) {
      Navigator.of(context).pop();
      final payment = await askTransaksiPaymentCash(context: context, totalDue: totalDue);
      if (payment != null && context.mounted) {
        Navigator.of(context).pop(payment);
      }
      return;
    }

    final p = TxPayment(
      method: method,
      amount: Int64(totalDue),
      tsMs: Int64(DateTime.now().millisecondsSinceEpoch),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Metode Pembayaran', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(moneyFmtIdr(totalDue), style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              _methodTile(
                context,
                icon: Icons.payments_outlined,
                title: 'Tunai (Cash)',
                subtitle: 'Hitung kembalian dan pecahan uang',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
                highlight: true,
              ),
              _methodTile(
                context,
                icon: Icons.qr_code_2_outlined,
                title: 'QRIS',
                subtitle: 'GoPay, OVO, Dana, BCA, Mandiri, ShopeePay',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_QRIS,
              ),
              _methodTile(
                context,
                icon: Icons.account_balance_outlined,
                title: 'Transfer Bank',
                subtitle: 'BCA, BRI, Mandiri, BNI',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_TRANSFER,
              ),
              _methodTile(
                context,
                icon: Icons.credit_card_outlined,
                title: 'Kartu Debit / Kredit (EDC)',
                subtitle: 'Visa, Mastercard, GPN',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_CARD,
              ),
              _methodTile(
                context,
                icon: Icons.assignment_late_outlined,
                title: 'Hutang / Bon (Pay Later)',
                subtitle: 'Dicatat sebagai piutang pelanggan',
                method: TxPaymentMethod.TX_PAYMENT_METHOD_DEBT,
              ),
            ],
          ),
        ),
      );

  Widget _methodTile(
    BuildContext context, {
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
          leading: Icon(icon, color: highlight ? _accent : _muted, size: 24),
          title: Text(title, style: TextStyle(color: _text, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, color: _muted, size: 18),
          onTap: () => _pick(context, method),
        ),
      );
}
