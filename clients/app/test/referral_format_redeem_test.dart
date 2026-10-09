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

  test('voucher links round-trip the code', () {
    const code = 'V101302857105457152';
    expect(voucherPublicUrl(code), 'https://alienai.id/voucher/$code');
    expect(voucherCodeFromUri(Uri.parse(voucherPublicUrl(code))), code);
    expect(voucherCodeFromUri(Uri.parse(voucherAppWebUrl(code))), code);
    expect(voucherCodeFromUri(Uri.parse(voucherAppSchemeUrl(code))), code);
    expect(voucherCodeFromScan(voucherPublicUrl('v101302857105457152')), code);
    expect(voucherCodeFromScan(code), code);
    expect(voucherCodeFromScan('not-a-code'), isNull);
  });
}
