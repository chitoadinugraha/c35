import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptBranding {
  static Future<Uint8List?> loadAlienIcon() async {
    try {
      final data = await rootBundle.load('assets/icons/app_icon_monochrome.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _brandIcon(Uint8List alienIcon) => pw.Container(
        width: 13,
        height: 13,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        alignment: pw.Alignment.center,
        child: pw.Image(pw.MemoryImage(alienIcon), width: 11, height: 11),
      );

  static pw.Widget poweredFooter({Uint8List? alienIcon}) => pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Powered with ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              if (alienIcon != null && alienIcon.isNotEmpty) ...[
                _brandIcon(alienIcon),
                pw.SizedBox(width: 3),
              ],
              pw.Text('Alien AI', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            ],
          ),
        ],
      );
}
