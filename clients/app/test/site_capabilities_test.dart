import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_table_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse order_fulfillment defaults to commerce when key absent', () {
    final caps = siteCapabilitiesParse('{"commerce":true}');
    expect(caps['order_fulfillment'], isTrue);
  });

  test('parse order_fulfillment respects explicit false', () {
    final caps = siteCapabilitiesParse('{"commerce":true,"order_fulfillment":false}');
    expect(caps['order_fulfillment'], isFalse);
  });

  test('encode includes order_fulfillment', () {
    final raw = siteCapabilitiesEncode({'commerce': true, 'order_fulfillment': false});
    expect(raw, contains('"order_fulfillment":false'));
  });

  test('siteCreateFeaturesToCaps sets order_fulfillment only with commerce', () {
    final caps = siteCreateFeaturesToCaps(
      SiteCreateFeatures(product: true, pos: false, orderFulfillment: true),
    );
    expect(caps['order_fulfillment'], isTrue);
    final off = siteCreateFeaturesToCaps(SiteCreateFeatures(product: false, orderFulfillment: true));
    expect(off['order_fulfillment'], isFalse);
  });
}
