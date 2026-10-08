import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_commerce_cache.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('site commerce cache roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    const uid = 99000;
    const siteIid = 101456339882426368;
    final products = [
      SiteProduct(productId: Int64(1), name: 'Kopi', price: Int64(15000), canSell: true),
    ];
    await siteProductCacheSave(uid, siteIid, products);
    final restored = await siteProductCacheRestore(uid, siteIid);
    expect(restored.length, 1);
    expect(restored.first.name, 'Kopi');

    await siteCapabilitiesCacheSave(uid, siteIid, '{"commerce":true}');
    expect(await siteCapabilitiesCacheRestore(uid, siteIid), '{"commerce":true}');
  });
}
