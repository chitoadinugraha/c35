import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('orderNumpad sets qty and confirmOrder updates line', () async {
    SharedPreferences.setMockInitialValues({});
    final cart = GuestSiteCartController(siteIid: 1);
    cart.openOrder(productId: 9, name: 'Latte', price: 20000, pic: '');
    expect(cart.sheet, GuestSiteCartSheet.order);

    cart.orderNumpad('2');
    cart.orderNumpad('3');
    expect(cart.orderDraft?.qty, 23);

    cart.orderSetNote('less ice');
    cart.confirmOrder();

    expect(cart.sheet, GuestSiteCartSheet.none);
    expect(cart.qtyForProduct(9), 23);
    expect(cart.lines.single.note, 'less ice');
  });

  test('confirmOrder with qty 0 removes line', () async {
    SharedPreferences.setMockInitialValues({});
    final cart = GuestSiteCartController(siteIid: 2);
    cart.addProduct(productId: 3, name: 'Tea', price: 5000);
    cart.openOrder(productId: 3, name: 'Tea', price: 5000);
    cart.orderNumpad('C');
    cart.confirmOrder();
    expect(cart.count, 0);
  });

  test('pesan opens checkout at confirm step', () async {
    SharedPreferences.setMockInitialValues({});
    final cart = GuestSiteCartController(siteIid: 3);
    cart.addProduct(productId: 1, name: 'A', price: 1000);
    cart.pesan();
    expect(cart.sheet, GuestSiteCartSheet.checkout);
    expect(cart.checkoutStep, GuestCheckoutStep.confirm);
  });
}
