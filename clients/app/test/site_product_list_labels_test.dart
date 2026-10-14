import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
import 'package:alienai_c35/c/site/site_product_list_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('productListStockLabel includes unit suffix', () {
    final p = SiteProduct(stockQty: 12);
    const extras = SiteProductExtras(stockUnit: 'pcs');
    expect(productListStockLabel(p, extras), 'Stock: 12 pcs');
  });

  test('productListDurationLabel formats period', () {
    const extras = SiteProductExtras(durationValue: 2, durationUnit: 'day');
    expect(productListDurationLabel(extras), 'Per: 2 Day');
  });
}
