import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_generator.dart';
import 'package:printing/printing.dart';

Future<void> shareReceiptPdf({
  required Tx tx,
  required ReceiptConfig config,
  Map<String, String> productNames = const {},
  String? alienId,
}) async {
  final bytes = await ReceiptPdfGenerator.generate(
    tx,
    config,
    productNames: productNames,
    alienId: alienId,
  );
  final id = txReceiptId(tx);
  final name = id.isNotEmpty ? 'nota_$id.pdf' : 'nota.pdf';
  await Printing.sharePdf(bytes: bytes, filename: name);
}
