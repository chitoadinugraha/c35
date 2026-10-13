import 'package:alienai_c35/guest_site/guest_site_i18n.dart';
import 'package:alienai_c35/guest_site/guest_site_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guestProductPriceLabel', () {
    test('contact sentinel', () {
      expect(guestProductPriceLabel(guestProductPriceContact), 'Contact us');
      expect(
        guestProductPriceLabel(guestProductPriceContact, i18n: const GuestSiteI18n(indonesian: true)),
        'Hubungi kami',
      );
    });

    test('zero and negative hide price', () {
      expect(guestProductPriceLabel(0), '');
      expect(guestProductPriceLabel(-2), '');
    });

    test('positive formats IDR', () {
      expect(guestProductPriceLabel(28000), contains('28'));
    });
  });

  group('productGridDisplay', () {
    test('defaults to list', () {
      expect(productGridDisplay({}), 'list');
    });

    test('block prop list', () {
      expect(productGridDisplay({'display': 'list'}), 'list');
    });

    test('meta catalog_display list', () {
      expect(productGridDisplay({}, meta: {'catalog_display': 'list'}), 'list');
    });
  });

  group('guestProductCanAddToCart', () {
    test('only positive prices', () {
      expect(guestProductCanAddToCart(100), isTrue);
      expect(guestProductCanAddToCart(0), isFalse);
      expect(guestProductCanAddToCart(guestProductPriceContact), isFalse);
    });
  });
}
