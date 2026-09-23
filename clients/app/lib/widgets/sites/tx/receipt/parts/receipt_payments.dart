import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptPayments {
  static pw.Widget build(Tx tx) {
    final totals = ReceiptTxTotals.fromTx(tx);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...tx.payments.map((payment) {
          final timeStr = payment.hasTsMs() ? receiptFmtTs(payment.tsMs) : '';
          final label = txPaymentMethodLabel(payment.method);
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  timeStr.isEmpty ? label : '$timeStr - $label',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Text(receiptMoney(payment.amount.toInt()), style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        }),
        if (totals.due > 0) ...[
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Belum Bayar', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(receiptMoney(totals.due), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ],
    );
  }
}
