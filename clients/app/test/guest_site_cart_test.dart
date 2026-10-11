import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('GuestSiteCartLine lineTotal', () {
    final line = GuestSiteCartLine(productId: 1, name: 'Kopi', price: 15000, qty: 2);
    expect(line.lineTotal, 30000);
  });

  test('GuestSiteCartController persists cart keyed by site_iid', () async {
    SharedPreferences.setMockInitialValues({});
    final cartA = GuestSiteCartController(siteIid: 42);
    cartA.addProduct(productId: 7, name: 'Tea', price: 5000);
    await Future<void>.delayed(Duration.zero);

    final cartB = GuestSiteCartController(siteIid: 42);
    await cartB.load();
    expect(cartB.count, 1);
    expect(cartB.lines.first.productId, 7);

    final cartOther = GuestSiteCartController(siteIid: 99);
    await cartOther.load();
    expect(cartOther.count, 0);
  });
}