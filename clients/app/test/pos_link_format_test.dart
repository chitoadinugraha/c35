import 'package:alienai_c35/c/site/pos_link_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('posSiteIidFromUri app scheme', () {
    expect(posSiteIidFromUri(Uri.parse('id.alienai://pos/42001')), '42001');
    expect(posSiteIidFromUri(Uri.parse('id.alienai://voucher/ABCD')), isNull);
  });

  test('posSiteIidFromUri https app path', () {
    expect(posSiteIidFromUri(Uri.parse('https://alienai.id/app/pos/99')), '99');
  });

  test('posShortcutLabel and file stem', () {
    expect(posShortcutLabel('Kopi'), 'Kopi - POS');
    expect(posShortcutFileStem('Cafe/Demo'), 'Cafe_Demo - POS');
  });
}
