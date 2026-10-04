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

    testWidgets('renders collapsed card by default with title and handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: testData),
          ),
        ),
      );

      expect(find.text('Kopi Kenangan'), findsOneWidget);
      expect(find.text('@kopi-kenangan'), findsOneWidget);
      expect(find.text('Live Preview'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsNothing);
    });

    testWidgets('expands to browser simulator with rendered blocks when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSitePreviewCard(data: testData),
          ),
        ),
      );

      // Tap Open
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify simulator URL bar
      expect(find.text('https://alienai.id/kopi-kenangan'), findsOneWidget);

      // Verify rendered blocks
      expect(find.text('Kopi Kenangan Mantan'), findsOneWidget);
      expect(find.text('Kopi susu gula aren terbaik'), findsOneWidget);
      expect(find.text('Pesan Sekarang'), findsOneWidget);
      expect(find.text('Hubungi Kami'), findsOneWidget);
      expect(find.text('Visit Site'), findsOneWidget);
      expect(find.text('Share URL'), findsOneWidget);

      // Collapse again
      await tester.tap(find.byIcon(Icons.close_rounded));
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
      expect(find.text('Visit Site'), findsOneWidget);
    });
  });
}
