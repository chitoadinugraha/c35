import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/ai/ui_site_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiSitePreviewCard', () {
    final testData = SitePreviewData(
      siteIid: 12345,
      alienId: 'kopi-kenangan',
      name: 'Kopi Kenangan',
      url: 'alienai.id/kopi-kenangan',
      theme: 'emerald',
      doc: {
        'pages': [
          {
            'path': '/',
            'title': 'Kopi Kenangan',
            'blocks': [
              {
                'id': 'hero1',
                'type': 'hero',
                'props': {
                  'title': 'Kopi Kenangan Mantan',
                  'subtitle': 'Kopi susu gula aren terbaik',
                  'cta_label': 'Pesan Sekarang',
                },
              },
              {
                'id': 'contact1',
                'type': 'contact_form',
                'props': {
                  'title': 'Hubungi Kami',
                  'submit_label': 'Kirim Pesan',
                },
              },
            ],
          },
        ],
        'theme': {
          'accent': '#10B981',
          'layout': 'clean',
        },
      },
    );

    final numericSiteData = SitePreviewData(
      siteIid: 99001234,
      alienId: '',
      name: 'New Site',
      url: 'alienai.id/99001234',
      doc: const {},
    );

    testWidgets('renders collapsed card by default with title and handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: testData),
          ),
        ),
      );

      expect(find.text('Kopi Kenangan'), findsOneWidget);
      expect(find.text('alienai.id/kopi-kenangan'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsNothing);
    });

    testWidgets('numeric site shows host path only without hash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: numericSiteData),
          ),
        ),
      );

      expect(find.text('#99001234'), findsNothing);
      expect(find.text('alienai.id/99001234'), findsOneWidget);
      expect(find.text('@99001234'), findsNothing);
    });

    testWidgets('tapping numeric public URL opens handle claim dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: numericSiteData),
          ),
        ),
      );

      await tester.tap(find.text('alienai.id/99001234'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pick your handle'), findsOneWidget);
      expect(find.text('Alien AI'), findsOneWidget);
    });

    testWidgets('expands inside ListView without layout errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                UiSitePreviewCard(data: testData),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
    });

    testWidgets('expands to browser simulator with rendered blocks when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: testData),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('https://alienai.id/kopi-kenangan'), findsNothing);
      expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsOneWidget);
      expect(find.text('Visit Site'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minimize'));
      await tester.pumpAndSettle();

      expect(find.text('Pesan Sekarang'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('respects initiallyExpanded flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: testData, initiallyExpanded: true),
          ),
        ),
      );

      expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
      expect(find.text('Visit site'), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('numeric site has no claim banner', (tester) async {
      final numeric = SitePreviewData(
        siteIid: 9900012345,
        alienId: '9900012345',
        name: 'Kopi Senja',
        url: 'alienai.id/9900012345',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: numeric, initiallyExpanded: true),
          ),
        ),
      );
      expect(find.textContaining('Claim a custom handle'), findsNothing);
    });

    test('siteHandleFormatError rejects pure digits', () {
      expect(siteHandleFormatError('12345'), isNotNull);
      expect(siteHandleFormatError('kopi-senja'), isNull);
    });

    test('fromJson reads preview token fields', () {
      final data = SitePreviewData.fromJson({
        'site_iid': 42,
        'alien_id': '42',
        'name': 'Draft',
        'preview_token': 'tok',
        'preview_expires_ts_ms': 999,
      });
      expect(data.previewToken, 'tok');
      expect(data.previewExpiresTsMs, 999);
      expect(data.handleLabel, '42');
      expect(data.slug, '42');
    });
  });
}
