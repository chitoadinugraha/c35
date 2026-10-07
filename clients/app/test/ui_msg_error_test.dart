import 'package:alienai_c35/widgets/ai/ui_msg_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.text('Root only'), findsOneWidget);
    expect(find.text('empty response from gemini-3.5-flash-lite'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('UiMsgError hides message id in UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UiMsgError(
          message: 'Cannot connect to Alien AI',
          reqId: 'req-abc-123',
        ),
      ),
    ));
    expect(find.textContaining('Message ID'), findsNothing);
  });

  testWidgets('UiMsgError root copy includes message id', (tester) async {
    const msgId = 9900123456789;
    const err = 'HTTP 404 from upstream';
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        expect(call.arguments['text'], '[Message ID: $msgId]\n$err');
        return null;
      }
      return null;
    });
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UiMsgError(
          message: 'Cannot connect to Alien AI',
          msgId: msgId,
          detail: err,
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('UiMsgError hides detail when null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: UiMsgError(message: 'Connection failed'),
      ),
    ));
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('UiMsgError shows out of quota and upgrade plan button', (tester) async {
    var upgradeTapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UiMsgError(
          message: "You're out of quota. Upgrade your plan or top up your balance to continue.",
          onUpgrade: () => upgradeTapped = true,
          onRetry: () {},
        ),
      ),
    ));
    expect(find.text("You're out of quota. Upgrade your plan or top up your balance to continue."), findsOneWidget);
    expect(find.text('Upgrade plan'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsNWidgets(2));

    await tester.tap(find.text('Upgrade plan'));
    expect(upgradeTapped, isTrue);
  });
}
