import 'package:alienai_c35/widgets/ai/ui_msg_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiMsgError shows retry button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UiMsgError(
          message: "Can't reach Alien AI right now.",
          onRetry: () => tapped = true,
        ),
      ),
    ));
    expect(find.text("Can't reach Alien AI right now."), findsOneWidget);
    expect(find.byType(DecoratedBox), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('UiMsgError shows root detail in code block', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UiMsgError(
          message: "Alien AI didn't return an answer. Please try again.",
          detail: 'empty response from gemini-3.5-flash-lite',
        ),
      ),
    ));
    expect(find.text("Alien AI didn't return an answer. Please try again."), findsOneWidget);
    expect(find.text('empty response from gemini-3.5-flash-lite'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('UiMsgError hides detail when null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UiMsgError(message: 'Something went wrong. Please try again.'),
      ),
    ));
    expect(find.byType(SelectableText), findsNothing);
  });
}
