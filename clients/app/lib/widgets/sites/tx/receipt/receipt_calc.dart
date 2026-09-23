import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';

String receiptMoney(int amount) => moneyFmtIdrGrouped(amount);

String receiptFmtTs(Int64 ms) {
  if (ms <= Int64.ZERO) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).toLocal();
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  final sec = dt.second.toString().padLeft(2, '0');
  return '$d/$m/${dt.year} $h:$min:$sec';
}

String txReceiptId(Tx tx) => tx.txId > Int64.ZERO ? tx.txId.toString() : '';

int receiptItemLineTotal(TxItem item) {
  if (item.totalNet > Int64.ZERO) return item.totalNet.toInt();
  return item.qty * item.price.toInt();
}

class ReceiptTxTotals {
  final int subtotal;
  final int tax;
  final int discount;
  final int total;
  final int paid;
  final int due;

  ReceiptTxTotals._({
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paid,
    required this.due,
  });

  factory ReceiptTxTotals.fromTx(Tx tx) {
    final subtotal = tx.items.fold<int>(0, (sum, item) => sum + receiptItemLineTotal(item));
    final tax = tx.taxes.fold<int>(0, (sum, t) => sum + t.amount.toInt());
    final discount = tx.discounts.fold<int>(0, (sum, d) => sum + d.amount.toInt());
    final total = tx.total > Int64.ZERO ? tx.total.toInt() : subtotal + tax - discount;
    final paid = tx.payments.fold<int>(0, (sum, p) => sum + p.amount.toInt());
    return ReceiptTxTotals._(
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paid: paid,
      due: total - paid,
    );
  }
}
