import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiMsgThought starts expanded while thinking and auto-collapses when thinking finishes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UiMsgThought(
            text: 'I am reasoning about the answer...',
            thinking: true,
          ),
        ),
      ),
    );

    // Header displays "Thinking"
    expect(find.text('Thinking'), findsOneWidget);
    // MarkdownBody with thought text is visible because it is expanded
    expect(find.byType(MarkdownBody), findsOneWidget);

    // Now transition: thinking finishes (first non-thinking token arrives)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UiMsgThought(
            text: 'I am reasoning about the answer...',
            thinking: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header switches to "Thought"
    expect(find.text('Thought'), findsOneWidget);
    // MarkdownBody is collapsed (not in widget tree)
    expect(find.byType(MarkdownBody), findsNothing);
    // Preview snippet is shown
    expect(find.text('I am reasoning about the answer...'), findsOneWidget);

    // Tapping on it re-expands it manually
    await tester.tap(find.text('Thought'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownBody), findsOneWidget);
  });
}
