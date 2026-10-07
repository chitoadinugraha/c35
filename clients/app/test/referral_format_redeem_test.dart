import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('referralPackageCodeFormValidate accepts voucher codes', () {
    expect(referralPackageCodeFormValidate('V101302857105457152'), isNull);
    expect(referralPackageCodeFormValidate('V101'), isNotNull);
  });

  test('referralPackageCodeFormValidate accepts 20-char package codes', () {
    expect(referralPackageCodeFormValidate('ABCD1234EFGH5678IJKL'), isNull);
    expect(referralPackageCodeFormValidate('ABCD1234'), isNotNull);
  });
}
