import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/billing/billing_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('billingCurrencyForDeviceLocale defaults non-ID to USD', () {
    expect(billingCurrencyForDeviceLocale(), 'USD');
  });

  test('billingAndroidStoreCheckoutFromDefine play vs direct', () {
    expect(billingAndroidStoreCheckoutFromDefine('play', true), isTrue);
    expect(billingAndroidStoreCheckoutFromDefine('store', true), isTrue);
    expect(billingAndroidStoreCheckoutFromDefine('direct', true), isFalse);
    expect(billingAndroidStoreCheckoutFromDefine('apk', true), isFalse);
    expect(billingAndroidStoreCheckoutFromDefine('', true), isTrue);
    expect(billingAndroidStoreCheckoutFromDefine('', false), isFalse);
  });
}
