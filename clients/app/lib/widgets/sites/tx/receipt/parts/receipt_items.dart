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
    final name = _itemName(item, productNames);
    final total = receiptItemLineTotal(item);
    final unitPrice = item.price.toInt();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('  ${item.qty} x ${receiptMoney(unitPrice)}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(receiptMoney(total), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        if (item.totalDiscount > Int64.ZERO)
          pw.Text('    (Diskon) -${receiptMoney(item.totalDiscount.toInt())}', style: const pw.TextStyle(fontSize: 9)),
        if (item.note.isNotEmpty) pw.Text('    ${item.note}', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static String _itemName(TxItem item, Map<String, String> productNames) {
    if (item.productId <= Int64.ZERO) return item.note.trim().isNotEmpty ? item.note.trim() : 'Item';
    return productNames[item.productId.toString()] ?? (item.note.isNotEmpty ? item.note : 'Item #${item.productId}');
  }
}
