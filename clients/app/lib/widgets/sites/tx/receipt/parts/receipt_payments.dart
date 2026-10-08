import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptPayments {
  static pw.Widget build(Tx tx) {
    final totals = ReceiptTxTotals.fromTx(tx);
    var totalChange = 0;
    var hasTenderedData = false;
    final rows = <pw.Widget>[];

    for (final payment in tx.payments) {
      final methodLabel = txPaymentMethodLabel(payment.method);
      int? tendered;
      int? change;
      if (payment.paymentJson.isNotEmpty) {
        try {
          final parsed = jsonDecode(payment.paymentJson);
          if (parsed is Map) {
            if (parsed['tendered'] is num) tendered = (parsed['tendered'] as num).toInt();
            if (parsed['change'] is num) change = (parsed['change'] as num).toInt();
          }
        } catch (_) {}
      }
      if (tendered != null && tendered > 0) {
        hasTenderedData = true;
        if (change != null) totalChange += change;
        rows.add(_payRow('Bayar ($methodLabel)', receiptMoney(tendered)));
      } else {
        rows.add(_payRow('Bayar ($methodLabel)', receiptMoney(payment.amount.toInt())));
      }
    }

    if (hasTenderedData && totalChange > 0) {
      rows.add(_payRow('Kembalian', receiptMoney(totalChange)));
    } else if (totals.paid > totals.total) {
      rows.add(_payRow('Kembalian', receiptMoney(totals.paid - totals.total)));
    }

    if (totals.due > 0) rows.add(_payRow('Sisa Tagihan', receiptMoney(totals.due), bold: true));

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows);
  }

  static pw.Widget _payRow(String label, String amount, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: bold ? 11 : 10, fontWeight: bold ? pw.FontWeight.bold : null)),
            pw.Text(amount, style: pw.TextStyle(fontSize: bold ? 11 : 10, fontWeight: bold ? pw.FontWeight.bold : null)),
          ],
        ),
      );
}
