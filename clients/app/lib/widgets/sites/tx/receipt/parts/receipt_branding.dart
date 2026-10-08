import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptBranding {
  static Future<Uint8List?> loadAlienIcon() async {
    try {
      final data = await rootBundle.load('assets/icons/alien.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget poweredFooter({Uint8List? alienIcon}) => pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Powered with ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              if (alienIcon != null && alienIcon.isNotEmpty) ...[
                pw.Image(pw.MemoryImage(alienIcon), width: 11, height: 11),
                pw.SizedBox(width: 3),
              ],
              pw.Text('Alien AI', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            ],
          ),
        ],
      );
}
