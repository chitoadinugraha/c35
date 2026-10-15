import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _bootWithBackdrop(String backdropId, {bool dark = false}) => {
      'site_iid': 1,
      'name': 'Atmosphere',
      'alien_id': 'atm',
      'avatar_url': '',
      'mode': 'draft',
      'theme': {'accent': '#2563EB'},
      'meta': {},
      'design': {
        'accent': '#2563EB',
        'base': 'monochrome',
        'dark': dark,
        'background': {
          'type': 'color',
          'color': dark ? '#111111' : '#F8F9FA',
          'url': '',
          'blur': 0,
          'overlay': 0,
          'overlayTone': 'dark',
        },
        'backdrop': {'id': backdropId, 'params': <String, dynamic>{}, 'color': ''},
        'profile': {'showAvatar': true, 'showTitle': true},
      },
      'effects': <Map<String, dynamic>>[],
      'pages': [
        {
          'path': '/',
          'blocks': [
            {
              'id': 'hub',
              'type': 'hub_profile',
              'props': {'title': 'Shop', 'subtitle': 'Bio'},
            },
          ],
        },
      ],
      'capabilities': <String, dynamic>{},
      'product_preload': <String, dynamic>{},
      'links': <Map<String, dynamic>>[],
    };

void main() {
  testWidgets('backdrop none shows accent wash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSiteView.bootJson(bootJson: _bootWithBackdrop('none')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-backdrop')), findsOneWidget);
    expect(find.byKey(const Key('guest-backdrop-accent')), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('backdrop glow omits accent wash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSiteView.bootJson(bootJson: _bootWithBackdrop('glow', dark: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-backdrop')), findsOneWidget);
    expect(find.byKey(const Key('guest-backdrop-accent')), findsNothing);
    final backdrop = tester.widget<GuestSiteBackdrop>(find.byKey(const Key('guest-backdrop')));
    expect(backdrop.backdropId, 'glow');
  });
}
