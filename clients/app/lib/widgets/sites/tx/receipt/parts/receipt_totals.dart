import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptTotals {
  static pw.Widget build(Tx tx) {
    final totals = ReceiptTxTotals.fromTx(tx);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sub Total', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(receiptMoney(totals.subtotal), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        if (tx.taxes.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...tx.taxes.map(
            (tax) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(tax.taxType.isNotEmpty ? tax.taxType : 'Pajak', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(receiptMoney(tax.amount.toInt()), style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
        if (tx.discounts.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...tx.discounts.map(
            (d) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(d.note.isEmpty ? 'Diskon' : d.note, style: const pw.TextStyle(fontSize: 10)),
                pw.Text('-${receiptMoney(d.amount.toInt())}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(receiptMoney(totals.total), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
