import 'dart:typed_data';

import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_business_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('pdfSafeImageBytesForReceipt flattens transparent PNG to JPEG', () {
    final src = img.Image(width: 4, height: 4);
    img.fill(src, color: img.ColorRgba8(0, 180, 120, 128));
    final png = Uint8List.fromList(img.encodePng(src));

    final out = ReceiptBusinessInfo.pdfSafeImageBytesForReceipt(png);
    expect(out, isNotNull);
    expect(out, isNot(same(png)));
    expect(out![0], 0xFF);
    expect(out[1], 0xD8);
  });

  test('pdfSafeImageBytesForReceipt encodes opaque PNG as JPEG', () {
    final src = img.Image(width: 2, height: 2);
    img.fill(src, color: img.ColorRgb8(10, 20, 30));
    final png = Uint8List.fromList(img.encodePng(src));

    final out = ReceiptBusinessInfo.pdfSafeImageBytesForReceipt(png);
    expect(out, isNotNull);
    expect(out![0], 0xFF);
    expect(out[1], 0xD8);
  });
}
