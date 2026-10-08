import 'package:alienai_c35/c/snowflake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snowflakeWorkerFromInstall stays in client range', () {
    final w = snowflakeWorkerFromInstall('c35-test-install');
    expect(w, greaterThanOrEqualTo(512));
    expect(w, lessThanOrEqualTo(1023));
  });
}
