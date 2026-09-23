import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_business_info.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_header.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_items.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_note.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_payments.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_qr.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_status.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_totals.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_watermark.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptPdfGenerator {
  static Future<Uint8List> generate(
    Tx tx,
    ReceiptConfig config, {
    Map<String, String> productNames = const {},
    String? alienId,
    String? watermark,
  }) async {
    final pdf = pw.Document();
    final logoData = await ReceiptBusinessInfo.loadLogo(config.projectLogo.isNotEmpty ? config.projectLogo : null);
    final qrWidget = await ReceiptQr.build(tx, config, alienId: alienId);

    const rollPaperFormat = PdfPageFormat(227, 800, marginTop: 10, marginLeft: 10, marginRight: 10, marginBottom: 10);
    final pageTheme = pw.PageTheme(pageFormat: rollPaperFormat, theme: pw.ThemeData.base());

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          final body = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (config.receiptHeader.isNotEmpty) ...[
                pw.Center(child: pw.Text(config.receiptHeader, style: const pw.TextStyle(fontSize: 10))),
                pw.SizedBox(height: 8),
              ],
              ReceiptBusinessInfo.build(config, logoData: logoData),
              ReceiptHeader.build(tx),
              ReceiptItems.build(tx, productNames),
              if (tx.desc.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                ReceiptNote.build(tx),
              ],
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              ReceiptTotals.build(tx),
              pw.SizedBox(height: 12),
              ReceiptPayments.build(tx),
              pw.SizedBox(height: 8),
              ReceiptStatus.build(tx),
              if (qrWidget != null) ...[pw.SizedBox(height: 12), qrWidget],
              if (config.receiptFooter.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Center(child: pw.Text(config.receiptFooter, style: const pw.TextStyle(fontSize: 10))),
              ],
            ],
          );
          final mark = watermark?.trim();
          return pw.Container(
            color: PdfColors.white,
            width: double.infinity,
            child: mark == null || mark.isEmpty
                ? body
                : pw.Stack(
                    children: [
                      pw.Positioned.fill(child: ReceiptWatermark.build(mark)),
                      body,
                    ],
                  ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
