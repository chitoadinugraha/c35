import 'package:alienai_c35/widgets/ai/ui_markdown_code_block.dart';
import 'package:alienai_c35/c/presentation/slide_deck_theme_prefs.dart';
import 'package:alienai_c35/widgets/ai/ui_slide_deck_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiSlideDeckCard', () {
    final testDeck = SlideDeckData.fromContent(
      title: 'Cara Memasak Indomie Sempurna',
      content: '''
# Rahasia Indomie Sempurna
Trik memasak mie instan favorit untuk hasil kenyal maksimal.
---
# 3 Kunci Kelezatan
- Rebus mie tepat 3 menit
- Racik bumbu langsung di piring
- Tiriskan air rebusan pertama
---
# Langkah Terakhir
- Aduk rata selagi mie masih panas
- Tambahkan telur setengah matang
''',
      createdAt: DateTime(2026, 10, 3, 6, 11),
      eyebrow: 'PANDUAN KULINER PRAKTIS',
    );

    testWidgets('renders collapsed small card with title, slide count, and timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSlideDeckCard(deck: testDeck),
          ),
        ),
      );

      // Verify collapsed small card content
      expect(find.text('Cara Memasak Indomie Sempurna'), findsOneWidget);
      expect(find.text('3 slides • Dark Neon • 3 Oct, 6:11 am'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.slideshow_rounded), findsOneWidget);

      // Verify that full preview toolbar is not visible yet
      expect(find.text('1/3'), findsNothing);
    });

    testWidgets('expands to compact 16:9 preview when Open is tapped and navigates slides', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSlideDeckCard(deck: testDeck),
          ),
        ),
      );

      // Tap "Open" to expand
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify compact preview header & pager
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('PANDUAN KULINER PRAKTIS'), findsOneWidget);
      expect(find.text('Rahasia Indomie Sempurna'), findsOneWidget);
      expect(find.text('Trik memasak mie instan favorit untuk hasil kenyal maksimal.'), findsOneWidget);

      // Navigate to next slide
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('3 Kunci Kelezatan'), findsOneWidget);
      expect(find.text('Rebus mie tepat 3 menit'), findsOneWidget);

      // Drag left to slide 3
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Langkah Terakhir'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minimize'));
      await tester.pumpAndSettle();

      // Returns to collapsed small card
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('3 slides • Dark Neon • 3 Oct, 6:11 am'), findsOneWidget);
    });

    testWidgets('opens deck menu and theme dialog updates deck theme', (tester) async {
      final deck = SlideDeckData.fromContent(
        title: 'Pitch Deck',
        content: '# Intro\n- Detail 1\n---\n# Slide 2\n- Detail 2',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSlideDeckCard(deck: deck, initiallyExpanded: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Fullscreen Presentation'), findsOneWidget);
      expect(find.text('Export to PowerPoint (.pptx)'), findsOneWidget);
      expect(find.text('Export to PDF (.pdf)'), findsOneWidget);
      expect(find.text('Copy Slides Markdown'), findsOneWidget);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('slide-theme-emerald')));
      await tester.pumpAndSettle();

      expect(deck.theme, 'emerald');
    });

    test('per-chat theme override applies on deck rebuild', () {
      const chatId = 4242;
      SlideDeckThemePrefs.instance.set(chatId, 'arctic');
      final deck = SlideDeckData.fromJson({
        'title': 'Deck',
        'slides': ['# One'],
        'theme': 'dark',
      });
      final themeOverride = SlideDeckThemePrefs.instance.themeFor(chatId);
      if (themeOverride != null) deck.theme = themeOverride;
      expect(deck.theme, 'arctic');
    });

    testWidgets('UiMarkdownCodeBlock automatically renders UiSlideDeckCard for slide language', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiMarkdownCodeBlock(
              code: '''
# Indomie Enak
Cara masak cepat dan nikmat.
---
# Bahan
- 1 bungkus mie instan
- Telur
''',
              language: 'slide',
            ),
          ),
        ),
      );

      // Language 'slide' renders as UiSlideDeckCard collapsed by default
      expect(find.text('Indomie Enak'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.textContaining('2 slides'), findsOneWidget);
    });

    test('SlidePatch correctly parses replace, insert, and delete blocks', () {
      final replace = SlidePatch.tryParse('<!-- slide-patch:2 -->\n# New Slide 2\n- point');
      expect(replace, isNotNull);
      expect(replace!.action, SlidePatchAction.replace);
      expect(replace.slideIndex, 2);
      expect(replace.content, '# New Slide 2\n- point');

      final insert = SlidePatch.tryParse('<!-- slide-patch:add after=1 -->\n# Inserted Slide');
      expect(insert, isNotNull);
      expect(insert!.action, SlidePatchAction.insert);
      expect(insert.slideIndex, 1);
      expect(insert.content, '# Inserted Slide');

      final delete = SlidePatch.tryParse('<!-- slide-patch:delete 3 -->');
      expect(delete, isNotNull);
      expect(delete!.action, SlidePatchAction.delete);
      expect(delete.slideIndex, 3);

      // Verify applying patches to SlideDeckData
      final deck = SlideDeckData.fromContent(
        title: 'Test Deck',
        content: '# S1\n---\n# S2\n---\n# S3',
      );
      expect(deck.slides.length, 3);

      // Apply replace
      deck.applyPatch(replace);
      expect(deck.slides[1], '# New Slide 2\n- point');

      // Apply insert after 1
      deck.applyPatch(insert);
      expect(deck.slides.length, 4);
      expect(deck.slides[1], '# Inserted Slide');

      // Apply delete
      deck.applyPatch(delete);
      expect(deck.slides.length, 3);
    });

    test('presentationDownloadUri fixes legacy signed URL with filename after query', () {
      const hash = 'abc123';
      const name = 'My_Deck.pptx';
      const sig = 'deadbeef';
      final legacy = '/fs/$hash?exp=99&sig=$sig/$name';
      final uri = UiSlideDeckCard.presentationDownloadUri(
        apiBase: 'http://127.0.0.1:8080',
        fileHash: hash,
        fileName: name,
        downloadUrl: legacy,
      );
      expect(uri.path, '/fs/$hash/$name');
      expect(uri.queryParameters['exp'], '99');
      expect(uri.queryParameters['sig'], sig);
    });

    test('fromBlockBody merges patch onto prior deck', () {
      final base = SlideDeckData.fromContent(
        title: 'Cara Memasak Nasi',
        content: '# S1\n---\n# S2\n---\n# S3\n---\n# S4\n---\n# S5',
      );
      expect(base.slides.length, 5);

      final patched = SlideDeckData.fromBlockBody({
        'title': 'Slide 1 Updated',
        'content': '<!-- slide-patch:1 -->\n# Cara Memasak Nasi\nTakaran 1 cup beras : 1.5 cup air',
        'eyebrow': 'SLIDE 1 UPDATED',
        'theme': 'dark',
      }, base);

      expect(patched.slides.length, 5);
      expect(patched.title, 'Cara Memasak Nasi');
      expect(patched.slides.first, contains('Takaran'));
    });

    testWidgets('renders slide with embedded image in split layout', (tester) async {
      final imageDeck = SlideDeckData.fromContent(
        title: 'Indomie Recipe with Photo',
        content: '''
# Bahan Utama
- 1 bungkus mie instan
- 400ml air
![Indomie Photo](https://example.com/indomie.png)
''',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiSlideDeckCard(deck: imageDeck, initiallyExpanded: true),
          ),
        ),
      );

      expect(find.text('Bahan Utama'), findsOneWidget);
      expect(find.text('1 bungkus mie instan'), findsOneWidget);
    });
  });
}
