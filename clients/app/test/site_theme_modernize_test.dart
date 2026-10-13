import 'package:alienai_c35/c/site/design/site_theme_modernize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modernize bumps legacy card radius and version', () {
    final out = modernizeThemeForRender({
      'dark': false,
      'card': {
        'id': 'solid',
        'params': {'radius': 8, 'shadow': 1},
      },
    });
    expect(out['renderStyleVersion'], 2);
    expect((out['card'] as Map)['params']['radius'], 16.0);
  });

  test('modernize skips when version current', () {
    final out = modernizeThemeForRender({
      'renderStyleVersion': 2,
      'card': {'params': {'radius': 8}},
    });
    expect((out['card'] as Map)['params']['radius'], 8);
  });

  test('site create default theme has elevated card', () {
    final map = siteCreateDefaultThemeMap();
    expect(map['renderStyleVersion'], 2);
    expect((map['card'] as Map)['id'], 'elevated');
  });
}
