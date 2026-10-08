import 'package:alienai_c35/widgets/io/in_site_product_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('siteCategoryTitleCase capitalizes each word', () {
    expect(siteCategoryTitleCase('  es teh  '), 'Es Teh');
    expect(siteCategoryTitleCase('MINUMAN'), 'Minuman');
    expect(siteCategoryTitleCase(''), '');
  });

  test('siteProductCategoryLabels drops blanks', () {
    expect(siteProductCategoryLabels([' Drink ', '', '  ', 'Food']), ['Drink', 'Food']);
  });
}
