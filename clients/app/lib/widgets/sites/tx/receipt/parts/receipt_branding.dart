import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alienai_c35/widgets/sites/ui_powered_by_alien.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptBranding {
  static Uint8List? _alienIconCache;

  @visibleForTesting
  static void clearAlienIconCacheForTest() => _alienIconCache = null;

  static Future<Uint8List?> loadAlienIcon() async {
    if (_alienIconCache != null) return _alienIconCache;
    try {
      final svg = await rootBundle.loadString(UiPoweredByAlien.alienReceiptIconAsset);
      final png = await _rasterSvg(svg, 32);
      _alienIconCache = png;
      return png;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _rasterSvg(String svg, int size) async {
    final loader = SvgStringLoader(svg);
    final pictureInfo = await vg.loadPicture(loader, null);
    final w = pictureInfo.size.width;
    final h = pictureInfo.size.height;
    if (w <= 0 || h <= 0) {
      pictureInfo.picture.dispose();
      return null;
    }
    final scale = size / math.max(w, h);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    pictureInfo.picture.dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  static pw.Widget _brandIcon(Uint8List alienIcon) => pw.Image(pw.MemoryImage(alienIcon), width: 11, height: 11);

  static pw.Widget poweredFooter({Uint8List? alienIcon}) => pw.Column(
        children: [
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Powered by ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              if (alienIcon != null && alienIcon.isNotEmpty) ...[
                _brandIcon(alienIcon),
                pw.SizedBox(width: 3),
              ],
              pw.Text(
                UiPoweredByAlien.brandLabel,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      );
}
