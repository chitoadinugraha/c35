import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billingCurrencyForDeviceLocale defaults non-ID to USD', () {
    // Platform locale in tests is usually en_US.
    expect(billingCurrencyForDeviceLocale(), 'USD');
  });
}
