import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receiptShowQrLinkFromCapabilities defaults to true', () {
    expect(receiptShowQrLinkFromCapabilities(''), isTrue);
    expect(receiptShowQrLinkFromCapabilities('{"commerce":true}'), isTrue);
  });

  test('capabilitiesJsonSetReceiptShowQrLink preserves other keys', () {
    const raw = '{"commerce":true,"receipt":{"header":"Hi","show_qr_link":true}}';
    final off = capabilitiesJsonSetReceiptShowQrLink(raw, false);
    expect(receiptShowQrLinkFromCapabilities(off), isFalse);
    expect(off.contains('"header":"Hi"'), isTrue);
    expect(off.contains('"commerce":true'), isTrue);

    final on = capabilitiesJsonSetReceiptShowQrLink(off, true);
    expect(receiptShowQrLinkFromCapabilities(on), isTrue);
  });
}
