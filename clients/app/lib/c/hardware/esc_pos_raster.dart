import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Printable width in dots for 58mm / 80mm paper (chars x 12 dots).
int escPosMaxWidthDots(int paperWidthChars) => paperWidthChars * 12;

/// Thermal printable width from roll size (203 dpi, ~8 dots/mm).
int escPosMaxWidthDotsFromMm(int paperWidthMm) {
  switch (paperWidthMm) {
    case 58:
      return 384;
    case 80:
      return 576;
    default:
      return ((paperWidthMm / 25.4) * 203).round().clamp(200, 640);
  }
}

int thermalPaperWidthMmFromChars(int paperWidthChars) => paperWidthChars <= 32 ? 58 : 80;

/// Max raster strip height for `GS v 0` (long receipts are split).
const int escPosRasterStripHeightDots = 480;

/// White pixel threshold when trimming PDF raster margins / page box outline.
const int _trimWhiteLum = 248;

class EscPosRaster {
  const EscPosRaster({required this.data, required this.widthBytes, required this.height});

  final Uint8List data;
  final int widthBytes;
  final int height;
}

/// Raster bit image for `GS v 0` (1 bit = print dot).
EscPosRaster? escPosRasterFromImageBytes(
  Uint8List bytes, {
  required int maxWidthDots,
  int maxHeightDots = 160,
}) {
  if (bytes.isEmpty || maxWidthDots < 8) return null;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final flat = img.Image(width: decoded.width, height: decoded.height);
  img.fill(flat, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flat, decoded);

  var w = flat.width;
  var h = flat.height;
  if (w > maxWidthDots) {
    h = (h * maxWidthDots / w).round().clamp(1, maxHeightDots);
    w = maxWidthDots;
  }
  if (h > maxHeightDots) {
    w = (w * maxHeightDots / h).round().clamp(1, maxWidthDots);
    h = maxHeightDots;
  }
  final resized = img.copyResize(flat, width: w, height: h, interpolation: img.Interpolation.linear);
  return _packRaster(resized);
}

/// Scales [image] to [maxWidthDots] (aspect preserved) and returns one or more ESC/POS rasters.
/// Drops empty margins and faint page-box edges from PDF raster output.
img.Image escPosTrimReceiptBitmap(img.Image image, {int padding = 2}) {
  final w = image.width;
  final h = image.height;
  if (w <= 0 || h <= 0) return image;

  var minX = w;
  var minY = h;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (img.getLuminance(image.getPixel(x, y)) < _trimWhiteLum) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < minX || maxY < minY) return image;

  minX = math.max(0, minX - padding);
  minY = math.max(0, minY - padding);
  maxX = math.min(w - 1, maxX + padding);
  maxY = math.min(h - 1, maxY + padding);

  return img.copyCrop(
    image,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

List<EscPosRaster> escPosRastersFromImage(
  img.Image image, {
  required int maxWidthDots,
  int stripHeight = escPosRasterStripHeightDots,
  bool scaleToWidth = false,
}) {
  if (image.width <= 0 || image.height <= 0 || maxWidthDots < 8) return [];

  var w = image.width;
  var h = image.height;
  if (w != maxWidthDots && (w > maxWidthDots || scaleToWidth)) {
    h = (h * maxWidthDots / w).round().clamp(1, 1 << 20);
    w = maxWidthDots;
  }
  final scaled = w == image.width && h == image.height
      ? image
      : img.copyResize(
          image,
          width: w,
          height: h,
          interpolation: img.Interpolation.average,
        );

  final strips = <EscPosRaster>[];
  final step = math.max(8, stripHeight);
  for (var y = 0; y < scaled.height; y += step) {
    final stripH = math.min(step, scaled.height - y);
    final crop = img.copyCrop(scaled, x: 0, y: y, width: scaled.width, height: stripH);
    strips.add(_packRaster(crop));
  }
  return strips;
}

@visibleForTesting
EscPosRaster packRasterImage(img.Image image) => _packRaster(image);

EscPosRaster _packRaster(img.Image image) {
  final w = image.width;
  final h = image.height;
  final widthBytes = (w + 7) ~/ 8;
  final out = Uint8List(widthBytes * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      final lum = img.getLuminance(p);
      if (lum < 140) {
        final idx = y * widthBytes + (x ~/ 8);
        out[idx] |= 0x80 >> (x % 8);
      }
    }
  }
  return EscPosRaster(data: out, widthBytes: widthBytes, height: h);
}
