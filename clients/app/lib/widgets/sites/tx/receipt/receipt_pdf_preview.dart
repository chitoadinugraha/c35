import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_format.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ReceiptPdfPreview extends StatefulWidget {
  const ReceiptPdfPreview({
    super.key,
    required this.tx,
    required this.config,
    this.productNames = const {},
    this.alienId,
    this.print = false,
    this.embedded = false,
    this.allowSystemPrint = true,
    this.showPreviewActions = true,
  });

  final Tx tx;
  final ReceiptConfig config;
  final Map<String, String> productNames;
  final String? alienId;
  final bool print;
  final bool embedded;
  final bool allowSystemPrint;
  final bool showPreviewActions;

  @override
  State<ReceiptPdfPreview> createState() => _ReceiptPdfPreviewState();
}

class _ReceiptPdfPreviewState extends State<ReceiptPdfPreview> {
  String get _title {
    final id = txReceiptId(widget.tx);
    return id.isNotEmpty ? 'Receipt #$id' : 'New Receipt';
  }

  String get _filename => 'receipt_${_title.toLowerCase().replaceAll(' ', '_')}.pdf';

  double get _maxPageWidth => receiptMmToPt(widget.config.paperWidthMm == 58 ? 58 : 80);

  Widget _pdfPreview() => PdfPreview(
        build: (format) => ReceiptPdfGenerator.generate(
          widget.tx,
          widget.config,
          productNames: widget.productNames,
          alienId: widget.alienId,
        ),
        canDebug: false,
        allowPrinting: widget.allowSystemPrint && widget.showPreviewActions,
        allowSharing: widget.showPreviewActions,
        useActions: widget.showPreviewActions,
        canChangePageFormat: false,
        canChangeOrientation: false,
        dynamicLayout: false,
        maxPageWidth: _maxPageWidth,
        initialPageFormat: receiptPdfPageFormat(widget.config, tx: widget.tx),
        pdfFileName: _filename,
        padding: widget.embedded ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : null,
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Center(child: _pdfPreview());
    }
    return Scaffold(appBar: AppBar(title: Text(_title)), body: _pdfPreview());
  }
}
