import 'package:alienai_c35/c/site/site_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('siteDomainIsApex detects apex vs www', () {
    expect(siteDomainIsApex('example.com'), isTrue);
    expect(siteDomainIsApex('www.example.com'), isFalse);
    expect(siteDomainIsApex('shop.example.co.id'), isFalse);
  });
}