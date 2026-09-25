import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:alienai_c35/widgets/ai/ui_canvas_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiCanvasPanel', () {
    testWidgets('renders placeholder when no artifact is open', (tester) async {
      final store = CanvasStore();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(store: store),
          ),
        ),
      );

      expect(find.text('No canvas content open'), findsOneWidget);
    });

    testWidgets('renders artifact title, language badge, and editor', (tester) async {
      final store = CanvasStore();
      store.openCode(title: 'calculator.py', code: 'def add(a, b):\n    return a + b', language: 'python');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(store: store),
          ),
        ),
      );

      expect(find.text('calculator.py'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('def add(a, b):\n    return a + b'), findsOneWidget);
    });

    testWidgets('switching to preview tab displays markdown view', (tester) async {
      final store = CanvasStore();
      store.openCode(title: 'doc.md', code: '# Overview\nHello world', language: 'markdown');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(store: store),
          ),
        ),
      );

      // Markdown opened directly into preview tab
      expect(store.activeTab, CanvasTab.preview);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);

      // Switch to Code tab
      await tester.tap(find.text('Code'));
      await tester.pumpAndSettle();

      expect(store.activeTab, CanvasTab.editor);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Iterate with AI triggers callback', (tester) async {
      final store = CanvasStore();
      store.openCode(title: 'service.dart', code: 'class Service {}', language: 'dart');

      CanvasArtifact? iteratedArtifact;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(
              store: store,
              onPromptIterate: (art) => iteratedArtifact = art,
            ),
          ),
        ),
      );

      expect(find.text('Iterate with AI'), findsOneWidget);
      await tester.tap(find.text('Iterate with AI'));
      await tester.pump();

      expect(iteratedArtifact?.title, 'service.dart');
    });

    testWidgets('editing text in editor updates store content', (tester) async {
      final store = CanvasStore();
      store.openCode(title: 'note.txt', code: 'initial', language: 'text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(store: store),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'updated notes');
      await tester.pump();

      expect(store.artifact?.content, 'updated notes');
      expect(find.text('Save snapshot'), findsOneWidget);
    });

    testWidgets('renders slide deck with card viewer and slide navigation', (tester) async {
      final store = CanvasStore();
      const slideContent = '''
# Slide 1: Welcome
Alien AI Presentation
---
# Slide 2: Problem
Market pain points
---
# Slide 3: Solution
Unified AI Agent
''';
      store.openCode(title: 'pitch.deck', code: slideContent, language: 'slide');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(store: store),
          ),
        ),
      );

      // Slide toolbar should indicate slide 1 of 3
      expect(find.text('Slide 1 of 3'), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
      expect(find.text('Export Deck'), findsOneWidget);

      // Tap Next slide
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();

      expect(find.text('Slide 2 of 3'), findsOneWidget);
      expect(find.textContaining('Problem'), findsOneWidget);

      // Tap Next slide again
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();

      expect(find.text('Slide 3 of 3'), findsOneWidget);
      expect(find.textContaining('Solution'), findsOneWidget);
    });

    testWidgets('triggers export prompt callback when export option chosen', (tester) async {
      final store = CanvasStore();
      store.openCode(
        title: 'strategy.deck',
        code: '# Slide 1\nTitle\n---\n# Slide 2\nGoals',
        language: 'slide',
      );

      String? exportedPrompt;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiCanvasPanel(
              store: store,
              onPromptExport: (art, prompt) => exportedPrompt = prompt,
            ),
          ),
        ),
      );

      // Open Export Deck menu
      await tester.tap(find.text('Export Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Build directly on PC (PowerPoint)'), findsOneWidget);
      expect(find.text('Download as PPTX / PDF'), findsOneWidget);
      expect(find.text('Export to Google Slides'), findsOneWidget);

      // Select Build directly on PC
      await tester.tap(find.text('Build directly on PC (PowerPoint)'));
      await tester.pumpAndSettle();

      expect(exportedPrompt, contains('PowerPoint'));
    });
  });
}

