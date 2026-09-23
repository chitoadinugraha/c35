import 'package:alienai_c35/widgets/ai/ui_markdown_code_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiMarkdownCodeBlock', () {
    testWidgets('renders language tag, code, and triggers open in canvas', (tester) async {
      String? openedTitle;
      String? openedCode;
      String? openedLang;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiMarkdownCodeBlock(
              code: 'final x = 42;',
              language: 'dart',
              onOpenInCanvas: (title, code, lang) {
                openedTitle = title;
                openedCode = code;
                openedLang = lang;
              },
            ),
          ),
        ),
      );

      expect(find.text('DART'), findsOneWidget);
      expect(find.text('final x = 42;'), findsOneWidget);
      expect(find.text('Open in Canvas'), findsOneWidget);

      await tester.tap(find.text('Open in Canvas'));
      await tester.pump();

      expect(openedTitle, 'snippet.dart');
      expect(openedCode, 'final x = 42;');
      expect(openedLang, 'dart');
    });

    testWidgets('MarkdownBody with UiMarkdownCodeBlockBuilder mounts code block', (tester) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownBody(
              data: '```python\nprint("hello")\n```',
              builders: {
                'code': UiMarkdownCodeBlockBuilder(
                  onOpenInCanvas: (_, __, ___) => triggered = true,
                ),
              },
            ),
          ),
        ),
      );

      expect(find.text('PYTHON'), findsOneWidget);
      expect(find.text('print("hello")'), findsOneWidget);
      expect(find.text('Open in Canvas'), findsOneWidget);

      await tester.tap(find.text('Open in Canvas'));
      await tester.pump();

      expect(triggered, isTrue);
    });
  });
}
