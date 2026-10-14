import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('siteProductApplyExtras round-trips stock flags', () {
    const extras = SiteProductExtras(
      active: false,
      stockUnit: 'kg',
      stockWarningEnabled: true,
      stockWarningQty: 5,
      stockCriticalEnabled: true,
      stockCriticalQty: 2,
      stockShowToCustomer: true,
      stockShowMaxQty: 99,
    );
    final base = SiteProduct(siteIid: Int64(1), name: 'Tea');
    final out = siteProductApplyExtras(base, extras);
    expect(out.isArchived, true);
    final read = siteProductExtrasRead(out);
    expect(read.stockUnit, 'kg');
    expect(read.stockWarningQty, 5);
    expect(read.stockShowToCustomer, true);
    expect(read.stockShowMaxQty, 99);
  });
}
