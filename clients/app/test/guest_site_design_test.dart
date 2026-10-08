import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_effect_stack.dart';
import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _designBoot() => {
      'site_iid': 1,
      'name': 'Demo',
      'alien_id': 'demo',
      'avatar_url': '',
      'mode': 'draft',
      'theme': {'accent': '#000000'},
      'meta': {},
      'design': {
        'accent': '#E11D48',
        'base': 'monochrome',
        'dark': true,
        'background': {
          'type': 'color',
          'color': '#111111',
          'url': '',
          'blur': 0,
          'overlay': 0,
          'overlayTone': 'dark',
        },
        'backdrop': {'id': 'glow', 'params': <String, dynamic>{}, 'color': ''},
        'profile': {'showAvatar': false},
        'product': {'titleFontSize': 22},
        'blocks': [
          {'block': 'link', 'cardStyleId': 'none', 'params': <String, dynamic>{}},
        ],
      },
      'featured_contacts': [
        {'id': 'p1', 'name': 'Partner One', 'pic': '', 'featured': 'partners'},
      ],
      'effects': <Map<String, dynamic>>[],
      'pages': [
        {
          'path': '/',
          'blocks': [
            {
              'id': 'profile',
              'type': 'hub_profile',
              'props': {'title': 'Demo', 'subtitle': 'Bio line'},
            },
            {
              'id': 'links',
              'type': 'links',
              'props': {
                'links': [
                  {'label': 'Site', 'url': 'https://example.com'},
                ],
              },
            },
            {'id': 'grid', 'type': 'product_grid', 'props': {'title': 'Shop'}},
            {'id': 'partners', 'type': 'partners_display', 'props': <String, dynamic>{}},
            {'id': 'clients', 'type': 'clients_display', 'props': <String, dynamic>{}},
          ],
        },
      ],
      'capabilities': <String, dynamic>{},
      'product_preload': {
        'grid': [
          {'name': 'Rose', 'price': 1000, 'pic': ''},
        ],
      },
      'links': <Map<String, dynamic>>[],
    };

void main() {
  test('boot design store reads accent, profile, contacts, and effects', () {
    final boot = GuestSiteBoot.fromJson(_designBoot());
    expect(boot.design, isNotNull);
    expect(boot.design!.accent, '#E11D48');
    expect(boot.design!.themeDark, isTrue);
    expect(boot.design!.profileDesign.showAvatar, isFalse);
    expect(boot.design!.productDesign.titleFontSize, 22);
    expect(boot.design!.backdrop.id, 'glow');
    expect(boot.featuredContacts, hasLength(1));
    expect(boot.featuredContacts.first['name'], 'Partner One');
    expect(boot.featuredContacts.first['featured'], 'partners');
    expect(boot.effects, isEmpty);
    expect(boot.accentColor, const Color(0xFFE11D48));
  });

  test('boot without design keeps theme accent', () {
    final boot = GuestSiteBoot.fromJson({
      'site_iid': 2,
      'name': 'Plain',
      'theme': {'accent': '#2563EB'},
      'pages': <Map<String, dynamic>>[],
    });
    expect(boot.design, isNull);
    expect(boot.featuredContacts, isEmpty);
    expect(boot.effects, isEmpty);
    expect(boot.accentColor, const Color(0xFF2563EB));
  });

  testWidgets('guest page paints design chrome, profile, links, products, and strips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GuestSiteView.bootJson(bootJson: _designBoot()),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('guest-profile-avatar')), findsNothing);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.byKey(const Key('guest-link-card')), findsNothing);
    expect(find.text('Site'), findsOneWidget);

    final title = tester.widget<Text>(find.byKey(const Key('guest-product-title')));
    expect(title.style?.fontSize, 22);

    expect(find.byKey(const Key('guest-partners-header')), findsOneWidget);
    expect(find.byKey(const Key('guest-partners-item')), findsOneWidget);
    expect(find.text('Partner One'), findsOneWidget);
    expect(find.byKey(const Key('guest-clients-header')), findsOneWidget);
    expect(find.byKey(const Key('guest-clients-item')), findsNothing);

    final backdrop = tester.widget<GuestSiteBackdrop>(find.byKey(const Key('guest-backdrop')));
    expect(backdrop.backdropId, 'glow');
    expect(find.byType(GuestSiteEffectStack), findsOneWidget);
  });
}
