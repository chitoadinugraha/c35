import 'package:alienai_c35/c/site/site_product_parse_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses products array from raw JSON', () {
    const text = '{"products":[{"name":"Kopi Latte","description":"Hot","price":25000},{"name":"Teh","price":15000}]}';
    final rows = siteProductParsePhotoFromLlmText(text);
    expect(rows.length, 2);
    expect(rows[0].name, 'Kopi Latte');
    expect(rows[0].description, 'Hot');
    expect(rows[0].price, 25000);
    expect(rows[1].name, 'Teh');
    expect(rows[1].price, 15000);
  });

  test('extracts JSON from markdown fence', () {
    const text = '''
Here you go:
```json
{"products":[{"name":"Es Jeruk","price":12000}]}
```
''';
    final rows = siteProductParsePhotoFromLlmText(text);
    expect(rows.length, 1);
    expect(rows[0].name, 'Es Jeruk');
    expect(rows[0].price, 12000);
  });

  test('skips rows without a name', () {
    const text = '{"products":[{"name":"","price":1},{"name":"Valid","price":0}]}';
    final rows = siteProductParsePhotoFromLlmText(text);
    expect(rows.length, 1);
    expect(rows[0].name, 'Valid');
  });
}
