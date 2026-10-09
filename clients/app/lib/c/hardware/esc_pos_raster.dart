import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Printable width in dots for 58mm / 80mm paper (chars x 12 dots).
int escPosMaxWidthDots(int paperWidthChars) => paperWidthChars * 12;

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
