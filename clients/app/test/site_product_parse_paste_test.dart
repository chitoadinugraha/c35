import 'package:alienai_c35/c/site/site_product_parse_paste.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses tab-separated header nama and harga', () {
    const text = 'nama\tharga\nKopi Latte\t25000\nTeh\t15000';
    final rows = siteProductParsePasteText(text);
    expect(rows.length, 2);
    expect(rows[0].name, 'Kopi Latte');
    expect(rows[0].price, 25000);
    expect(rows[1].name, 'Teh');
    expect(rows[1].price, 15000);
  });

  test('parses two columns without header', () {
    const text = 'Es Jeruk\t12000\nNasi Goreng\t35000';
    final rows = siteProductParsePasteText(text);
    expect(rows.length, 2);
    expect(rows[0].name, 'Es Jeruk');
    expect(rows[0].price, 12000);
    expect(rows[1].price, 35000);
  });

  test('parses trailing shorthand price', () {
    const text = 'Kopi Susu 25rb\nMatcha 45k';
    final rows = siteProductParsePasteText(text);
    expect(rows.length, 2);
    expect(rows[0].name, 'Kopi Susu');
    expect(rows[0].price, 25000);
    expect(rows[1].name, 'Matcha');
    expect(rows[1].price, 45000);
  });
}
