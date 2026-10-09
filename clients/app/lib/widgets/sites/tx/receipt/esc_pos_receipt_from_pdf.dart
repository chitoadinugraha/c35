import 'dart:typed_data';

import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';
import 'package:alienai_c35/c/hardware/esc_pos_raster.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

/// Builds raw ESC/POS bytes by rasterizing the same PDF used for preview / system print.
Future<Uint8List> escPosBytesFromReceiptPdf({
  required Uint8List pdfBytes,
  required int paperWidthMm,
  bool kickDrawer = false,
  double dpi = 203,
}) async {
  final builder = EscPosBuilder();
  builder.reset();
  if (kickDrawer) {
    builder.kickCashDrawer();
  }

  final maxWidth = escPosMaxWidthDotsFromMm(paperWidthMm);
  var printed = false;

  await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: dpi)) {
    final png = await page.toPng();
    final decoded = img.decodeImage(png);
    if (decoded == null) continue;
    final trimmed = escPosTrimReceiptBitmap(decoded);
    final rasters = escPosRastersFromImage(
      trimmed,
      maxWidthDots: maxWidth,
      scaleToWidth: true,
    );
    for (final raster in rasters) {
      builder.rasterBitImage(raster, align: EscPosAlign.center);
      printed = true;
    }
  }

  if (!printed) {
    throw StateError('Receipt PDF could not be rasterized for thermal print');
  }

  builder.feed(4);
  builder.cutPaper();
  return builder.bytes();
}

Future<Uint8List?> tryEscPosBytesFromReceiptPdf({
  required Uint8List pdfBytes,
  required int paperWidthMm,
  bool kickDrawer = false,
}) async {
  try {
    return await escPosBytesFromReceiptPdf(
      pdfBytes: pdfBytes,
      paperWidthMm: paperWidthMm,
      kickDrawer: kickDrawer,
    );
  } catch (e, st) {
    debugPrint('escPosBytesFromReceiptPdf failed: $e\n$st');
    return null;
  }
}
