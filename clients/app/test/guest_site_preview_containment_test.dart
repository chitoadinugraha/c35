import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_preview_app.dart';
import 'package:alienai_c35/guest_site/guest_site_preview_handoff.dart';
import 'package:alienai_c35/widgets/ai/ui_site_preview_card.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_phone_preview_frame.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_preview_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _commerceBootJson() => {
      'site_iid': 5,
      'name': 'Shop',
      'alien_id': 'shop',
      'avatar_url': '',
      'mode': 'draft',
      'theme': {'accent': '#2563eb'},
      'meta': {},
      'pages': [
        {
          'blocks': [
            {
              'id': 'p1',
              'type': 'product_grid',
              'props': {'title': 'Menu', 'display': 'list'},
            },
          ],
        },
      ],
      'capabilities': {'commerce': true},
      'product_preload': {
        'p1': [
          {'product_id': 42, 'name': 'Americano', 'price': 20000, 'desc': 'Hot'},
        ],
      },
      'commerce_boot': {'products': [], 'payment_methods': []},
    };

void main() {
  testWidgets('editor preview stage keeps viewport scroll/pan handoff', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSitePreviewStage(
            child: GuestSitePreviewApp.bootJson(bootJson: _commerceBootJson()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SitePreviewViewportHandoff), findsOneWidget);
    expect(find.byType(SitePreviewScrollHandoffListener), findsOneWidget);
    expect(find.byType(UiSitePhonePreviewFrame), findsOneWidget);
  });

  testWidgets('product detail route stays inside phone preview frame', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSitePreviewStage(
            child: GuestSitePreviewApp.bootJson(bootJson: _commerceBootJson()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guest-product-info-42')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest-product-detail')), findsOneWidget);

    final phoneRect = tester.getRect(find.byType(UiSitePhonePreviewFrame));
    final detailRect = tester.getRect(find.byKey(const Key('guest-product-detail')));

    expect(detailRect.left, greaterThanOrEqualTo(phoneRect.left - 1));
    expect(detailRect.top, greaterThanOrEqualTo(phoneRect.top - 1));
    expect(detailRect.right, lessThanOrEqualTo(phoneRect.right + 1));
    expect(detailRect.bottom, lessThanOrEqualTo(phoneRect.bottom + 1));
  });

  testWidgets('inline viewport routes stay under preview subtree not root app', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestSitePreviewViewport(
            boot: GuestSiteBoot.fromJson(_commerceBootJson()),
            height: 200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('guest-product-info-42')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(GuestSitePreviewViewport),
        matching: find.byKey(const Key('guest-product-detail')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('UiSitePreviewCard expanded preview uses bounded viewport', (tester) async {
    final cardData = SitePreviewData(
      siteIid: 12345,
      alienId: 'kopi-kenangan',
      name: 'Kopi Kenangan',
      url: 'alienai.id/kopi-kenangan',
      doc: {
        'pages': [
          {
            'blocks': [
              {
                'id': 'hero1',
                'type': 'hero',
                'props': {'title': 'Kopi Kenangan Mantan', 'subtitle': 'Best coffee'},
              },
            ],
          },
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSitePreviewCard(data: cardData, initiallyExpanded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GuestSitePreviewViewport), findsOneWidget);
    expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
  });
}
