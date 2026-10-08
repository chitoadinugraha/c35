import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class SectionTxCartPay extends StatelessWidget {
  const SectionTxCartPay({
    super.key,
    required this.grossSubtotal,
    required this.itemsDiscountTotal,
    required this.cartDiscountTotal,
    required this.finalTotal,
    required this.paid,
    required this.payments,
    required this.onCartDiscount,
    required this.onRemovePayment,
    required this.onCheckout,
    this.onPrintUnpaid,
    this.cartDiscountEnabled = true,
    this.lineCount = 0,
  });

  final Int64 grossSubtotal;
  final Int64 itemsDiscountTotal;
  final Int64 cartDiscountTotal;
  final Int64 finalTotal;
  final Int64 paid;
  final List<TxPayment> payments;
  final VoidCallback? onCartDiscount;
  final ValueChanged<int> onRemovePayment;
  final VoidCallback? onCheckout;
  final VoidCallback? onPrintUnpaid;
  final bool cartDiscountEnabled;
  final int lineCount;

  @override
  Widget build(BuildContext context) {
    final remaining = finalTotal - paid;
    final canPay = finalTotal > Int64.ZERO && onCheckout != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal (${moneyFmtIdrGrouped(lineCount)}) produk',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            Text(moneyFmtIdr(grossSubtotal.toInt()), style: const TextStyle(color: _text, fontSize: 12)),
          ],
        ),
        if (itemsDiscountTotal > Int64.ZERO) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diskon Produk', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              Text(
                '- ${moneyFmtIdr(itemsDiscountTotal.toInt())}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        if (cartDiscountEnabled) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 13,
                    color: cartDiscountTotal > Int64.ZERO ? Colors.redAccent : _accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Diskon',
                    style: TextStyle(
                      color: cartDiscountTotal > Int64.ZERO ? Colors.redAccent : _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onCartDiscount != null) ...[
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: onCartDiscount,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.add, size: 16, color: cartDiscountTotal > Int64.ZERO ? Colors.redAccent : _accent),
                      ),
                    ),
                  ],
                ],
              ),
              if (cartDiscountTotal > Int64.ZERO)
                Text(
                  '- ${moneyFmtIdr(cartDiscountTotal.toInt())}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                )
              else
                const Text('Rp 0', style: TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: _border),
        ),
        if (payments.isNotEmpty) ...[
          const Text('Pembayaran', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (var i = 0; i < payments.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141417),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(_paymentIcon(payments[i].method), color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      txPaymentMethodLabel(payments[i].method),
                      style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    moneyFmtIdr(payments[i].amount.toInt()),
                    style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onPressed: () => onRemovePayment(i),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              remaining <= Int64.ZERO ? 'Lunas' : 'Belum Bayar',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            Text(
              remaining <= Int64.ZERO ? 'Rp 0' : moneyFmtIdr(remaining.toInt()),
              style: TextStyle(
                color: remaining <= Int64.ZERO ? _accent : Colors.orangeAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(color: _muted, fontSize: 13)),
            Text(
              moneyFmtIdr(finalTotal.toInt()),
              style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF052E1B),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canPay ? onCheckout : null,
                  icon: const Icon(Icons.payments_outlined, size: 20),
                  label: Text(
                    remaining <= Int64.ZERO ? 'Selesai' : 'Bayar ${moneyFmtIdr(remaining.toInt())}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (onPrintUnpaid != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 48,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF27272A),
                    foregroundColor: _accent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  tooltip: 'Cetak (Belum Dibayar)',
                  onPressed: onPrintUnpaid,
                  icon: const Icon(Icons.print_outlined, size: 22),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

IconData _paymentIcon(TxPaymentMethod method) => switch (method) {
      TxPaymentMethod.TX_PAYMENT_METHOD_CASH => Icons.payments_outlined,
      TxPaymentMethod.TX_PAYMENT_METHOD_QRIS => Icons.qr_code_2_outlined,
      TxPaymentMethod.TX_PAYMENT_METHOD_TRANSFER => Icons.account_balance_outlined,
      TxPaymentMethod.TX_PAYMENT_METHOD_CARD => Icons.credit_card_outlined,
      TxPaymentMethod.TX_PAYMENT_METHOD_DEBT => Icons.assignment_late_outlined,
      _ => Icons.payment_outlined,
    };
