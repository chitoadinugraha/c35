import 'package:alienai_c35/c/site/pos_shortcut_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('composite shortcut icon is non-empty PNG', () async {
    final png = await posShortcutCompositeIconPng(sitePic: '');
    expect(png.length, greaterThan(100));
    expect(png[0], 0x89);
  });

  test('ICO encoder returns bytes', () async {
    final png = await posShortcutCompositeIconPng(sitePic: '');
    final ico = posShortcutCompositeIconIco(png);
    expect(ico.isNotEmpty, isTrue);
  });
}
