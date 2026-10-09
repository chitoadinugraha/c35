import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:pdf/pdf.dart';

double receiptMmToPt(num mm) => mm * 72 / 25.4;

/// Content height estimate so the PDF page hugs the receipt (avoids tall blank page + box outline on thermal).
double receiptPdfEstimatedHeightPt(ReceiptConfig config, Tx tx, {bool includeQr = true}) {
  final items = tx.items.where((i) => i.qty > 0).length;
  var h = 210.0;
  if (config.receiptHeader.isNotEmpty) h += 22;
  h += 78;
  h += items * 32.0;
  if (tx.desc.isNotEmpty) h += 28;
  h += 28 + tx.discounts.length * 14 + tx.taxes.length * 14;
  h += 88;
  h += tx.payments.length * 16;
  h += 36;
  if (includeQr && config.showQrLink) h += 88;
  h += 52;
  return h.clamp(300, 1600);
}

PdfPageFormat receiptPdfPageFormat(ReceiptConfig config, {Tx? tx, double? heightPt}) {
  final widthMm = config.paperWidthMm == 58 ? 58 : 80;
  final marginMm = config.marginMm.clamp(0, 24);
  final widthPt = receiptMmToPt(widthMm);
  final marginPt = receiptMmToPt(marginMm);
  final bodyHeight = heightPt ?? (tx != null ? receiptPdfEstimatedHeightPt(config, tx) : 800.0);
  return PdfPageFormat(
    widthPt,
    bodyHeight + marginPt * 2,
    marginTop: marginPt,
    marginLeft: marginPt,
    marginRight: marginPt,
    marginBottom: marginPt,
  );
}
