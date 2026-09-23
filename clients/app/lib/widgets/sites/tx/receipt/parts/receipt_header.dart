import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptHeader {
  static pw.Widget buildRow(String label, String value) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      );

  static pw.Widget build(Tx tx) {
    final timeStr = tx.hasCreatedTsMs()
        ? receiptFmtTs(tx.createdTsMs)
        : (tx.hasTimeTsMs() ? receiptFmtTs(tx.timeTsMs) : '');
    final id = txReceiptId(tx);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildRow('ID', id.isNotEmpty ? id : 'Nota Baru'),
        pw.SizedBox(height: 4),
        if (tx.subjectName.isNotEmpty) ...[
          buildRow('Customer', tx.subjectName),
          pw.SizedBox(height: 4),
        ],
        if (tx.cashierName.isNotEmpty) ...[
          buildRow('Cashier', tx.cashierName),
          pw.SizedBox(height: 4),
        ],
        buildRow('Waktu', timeStr),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
      ],
    );
  }
}
