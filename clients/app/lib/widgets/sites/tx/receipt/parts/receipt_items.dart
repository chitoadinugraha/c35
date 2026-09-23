import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptItems {
  static pw.Widget build(Tx tx, Map<String, String> productNames) {
    final items = tx.items.where((item) => item.qty > 0).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [...items.map((item) => _receiptItemRow(item, productNames))],
    );
  }

  static pw.Widget _receiptItemRow(TxItem item, Map<String, String> productNames) {
    const qtyWidth = 20.0;
    final name = _itemName(item, productNames);
    final total = receiptItemLineTotal(item);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: qtyWidth,
              child: pw.Text('${item.qty}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.end),
            ),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
                  if (item.note.isNotEmpty) pw.Text(item.note, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Text(receiptMoney(total), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static String _itemName(TxItem item, Map<String, String> productNames) {
    if (item.productId <= Int64.ZERO) return 'Item';
    return productNames[item.productId.toString()] ?? item.productId.toString();
  }
}
