import 'package:alienai_c35/c/site/site_link_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whatsapp normalizes local number and builds wa.me url', () {
    expect(siteLinkWhatsAppNumberNormalize('08123456789'), '628123456789');
    expect(siteLinkWhatsAppMeUrl('08123456789'), 'https://wa.me/628123456789');
    expect(siteLinkValueDisplay(icon: 'whatsapp', stored: 'https://wa.me/628123456789'), '628123456789');
  });

  test('platform normalize falls back to website', () {
    expect(siteLinkPlatformNormalize(''), 'website');
    expect(siteLinkPlatformNormalize('whatsapp'), 'whatsapp');
  });
}
