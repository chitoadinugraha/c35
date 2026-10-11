import 'package:alienai_c35/guest_site/guest_site_commerce_boot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guestOrderNoteWithPayment appends Pembayaran line', () {
    final note = guestOrderNoteWithPayment(
      note: 'Tanpa gula',
      paymentId: 'cash',
      paymentMethods: [
        {'id': 'cash', 'title': 'Bayar di tempat'},
      ],
    );
    expect(note, contains('Tanpa gula'));
    expect(note, contains('Pembayaran: Bayar di tempat'));
  });

  test('guestCommerceTaxTotal sums configured percents', () {
    expect(
      guestCommerceTaxTotal(100000, [
        {'percent': 10},
        {'percent': 2.5},
      ]),
      12500,
    );
  });
}