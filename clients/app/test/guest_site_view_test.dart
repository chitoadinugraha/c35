import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GuestSiteBoot.fromSiteDoc builds boot from preview doc', () {
    final boot = GuestSiteBoot.fromSiteDoc(
      siteIid: 7,
      name: 'Kopi',
      alienId: 'kopi',
      doc: {
        'pages': [
          {
            'path': '/',
            'blocks': [
              {'id': 'h1', 'type': 'hero', 'props': {'title': 'Hi'}},
            ],
          },
        ],
        'theme': {'accent': '#10B981'},
      },
    );
    expect(boot.homeBlocks.length, 1);
    expect(boot.accentColor, const Color(0xFF10B981));
  });

  test('GuestSiteBoot parses pages and hero props from boot JSON', () {
    final boot = GuestSiteBoot.fromJson({
      'site_iid': 42,
      'name': 'Warung',
      'alien_id': 'warung-bu-siti',
      'avatar_url': '/fs/pic123?v=thumb',
      'mode': 'draft',
      'theme': {'accent': '#2563eb'},
      'meta': {'seo_title': 'Shop'},
      'pages': [
        {
          'path': '/',
          'title': 'Home',
          'blocks': [
            {
              'id': 'h1',
              'type': 'hero',
              'props': {'title': 'Selamat Datang', 'subtitle': 'Fresh daily'},
            },
          ],
        },
      ],
      'capabilities': {'commerce': true},
      'product_preload': {},
    });

    expect(boot.siteIid, 42);
    expect(boot.homeBlocks.length, 1);
    expect(boot.homeBlocks.first['type'], 'hero');
    expect(boot.accentColor, const Color(0xFF2563EB));
  });

  testWidgets('GuestSiteView.bootJson renders hero title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSiteView.bootJson(
            bootJson: {
              'site_iid': 1,
              'name': 'Demo',
              'alien_id': 'demo',
              'avatar_url': '',
              'mode': 'draft',
              'theme': {},
              'meta': {},
              'pages': [
                {
                  'blocks': [
                    {
                      'id': 'h1',
                      'type': 'hero',
                      'props': {'title': 'Hello Guest Site'},
                    },
                  ],
                },
              ],
              'capabilities': {},
              'product_preload': {},
            },
          ),
        ),
      ),
    );

    expect(find.text('Hello Guest Site'), findsOneWidget);
  });

  test('GuestSiteBoot parses site_id from server boot JSON', () {
    final boot = GuestSiteBoot.fromJson({
      'site_id': 99,
      'name': 'Site ID Test',
      'alien_id': 'site-id-test',
      'avatar_url': '',
      'mode': 'draft',
      'theme': {},
      'meta': {},
      'pages': [],
      'capabilities': {},
      'product_preload': {},
    });

    expect(boot.siteIid, 99);
  });

  test('GuestSiteBoot parses links and product_preload_meta', () {
    final boot = GuestSiteBoot.fromJson({
      'site_iid': 7,
      'name': 'Hub',
      'alien_id': 'hub',
      'links': [
        {'label': 'IG', 'url': 'https://instagram.com/x'},
      ],
      'product_preload_meta': {
        'g1': {'next_cursor': '0:99'},
      },
      'posts_preload': [
        {'post_id': 1, 'title': 'Hello'},
      ],
      'theme': {},
      'meta': {},
      'pages': [],
      'capabilities': {},
      'product_preload': {},
    });
    expect(boot.links, hasLength(1));
    expect(boot.links.first['label'], 'IG');
    expect(boot.nextProductCursorForBlock('g1'), '0:99');
    expect(boot.postsPreload, hasLength(1));
  });

  testWidgets('GuestSiteView.bootJson renders gallery and image blocks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSiteView.bootJson(
            bootJson: {
              'site_id': 1,
              'name': 'Demo Gallery',
              'alien_id': 'demo-gallery',
              'avatar_url': '',
              'mode': 'draft',
              'theme': {},
              'meta': {},
              'pages': [
                {
                  'blocks': [
                    {
                      'id': 'g1',
                      'type': 'gallery',
                      'props': {'title': 'Galeri Foto', 'pics': ['pic1', 'pic2']},
                    },
                  ],
                },
              ],
              'capabilities': {},
              'product_preload': {},
            },
          ),
        ),
      ),
    );

    expect(find.text('Galeri Foto'), findsOneWidget);
  });

  testWidgets('GuestSiteView renders social_feed from posts_preload', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSiteView.bootJson(
            bootJson: {
              'site_id': 1,
              'name': 'Hub',
              'alien_id': 'hub',
              'avatar_url': '',
              'mode': 'draft',
              'theme': {'accent': '#2563eb'},
              'meta': {},
              'posts_preload': [
                {'post_id': 1, 'title': 'Promo Ramadan', 'caption': 'Diskon 20%'},
              ],
              'pages': [
                {
                  'blocks': [
                    {
                      'id': 's1',
                      'type': 'social_feed',
                      'props': {'title': 'Update', 'limit': 10},
                    },
                  ],
                },
              ],
              'capabilities': {},
              'product_preload': {},
            },
          ),
        ),
      ),
    );

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Promo Ramadan'), findsOneWidget);
  });
}
