import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GuestSiteCartLine lineTotal', () {
    final line = GuestSiteCartLine(productId: 1, name: 'Kopi', price: 15000, qty: 2);
    expect(line.lineTotal, 30000);
  });
}