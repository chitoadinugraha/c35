import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptWatermark {
  static const _rows = 24;
  static const _cols = 6;
  static const _cellW = 72.0;
  static const _cellH = 48.0;
  static const _fontSize = 20.0;
  static const _opacity = 0.17;
  static const _angle = -0.52;

  static pw.Widget build(String mark) => pw.ClipRect(
        child: pw.Transform.rotate(
          angle: _angle,
          child: pw.Transform.translate(
            offset: const PdfPoint(-56, -72),
            child: pw.Opacity(
              opacity: _opacity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: List.generate(_rows, (row) {
                  final offset = row.isOdd ? _cellW * 0.5 : 0.0;
                  return pw.SizedBox(
                    height: _cellH,
                    child: pw.Row(
                      children: [
                        pw.SizedBox(width: offset),
                        ...List.generate(
                          _cols,
                          (_) => pw.SizedBox(
                            width: _cellW,
                            child: pw.Center(
                              child: pw.Text(
                                mark,
                                style: pw.TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
}
