import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptNote {
  static pw.Widget build(Tx tx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(tx.desc, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
        ],
      );
}
