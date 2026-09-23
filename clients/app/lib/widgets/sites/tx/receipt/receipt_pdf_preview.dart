import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReceiptPdfPreview extends StatefulWidget {
  const ReceiptPdfPreview({
    super.key,
    required this.tx,
    required this.config,
    this.productNames = const {},
    this.alienId,
    this.print = false,
    this.watermark,
  });

  final Tx tx;
  final ReceiptConfig config;
  final Map<String, String> productNames;
  final String? alienId;
  final bool print;
  final String? watermark;

  @override
  State<ReceiptPdfPreview> createState() => _ReceiptPdfPreviewState();
}

class _ReceiptPdfPreviewState extends State<ReceiptPdfPreview> {
  String get _title {
    final id = txReceiptId(widget.tx);
    return id.isNotEmpty ? 'Receipt #$id' : 'New Receipt';
  }

  String get _filename => 'receipt_${_title.toLowerCase().replaceAll(' ', '_')}.pdf';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: PdfPreview(
          build: (format) => ReceiptPdfGenerator.generate(
            widget.tx,
            widget.config,
            productNames: widget.productNames,
            alienId: widget.alienId,
            watermark: widget.watermark,
          ),
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          canChangePageFormat: false,
          canChangeOrientation: false,
          maxPageWidth: 300,
          initialPageFormat: const PdfPageFormat(227, 800, marginTop: 10, marginLeft: 10, marginRight: 10, marginBottom: 10),
          pdfFileName: _filename,
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
        ),
      );
}
