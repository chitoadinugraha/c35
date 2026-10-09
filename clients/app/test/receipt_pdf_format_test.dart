import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receiptPdfPageFormat uses paper width and margin', () {
    const cfg = ReceiptConfig(paperWidthMm: 58, marginMm: 8);
    final fmt = receiptPdfPageFormat(cfg);
    expect(fmt.width, closeTo(receiptMmToPt(58), 0.5));
    expect(fmt.marginTop, closeTo(receiptMmToPt(8), 0.5));
  });
}
