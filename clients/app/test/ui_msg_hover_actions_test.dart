import 'package:alienai_c35/widgets/ai/ui_msg_hover_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiMsgHoverActions', () {
    testWidgets('user actions render copy and edit', (tester) async {
      var copied = false;
      var edited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiMsgHoverActions(
              isUser: true,
              onCopy: () => copied = true,
              onEdit: () => edited = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copied, isTrue);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(edited, isTrue);
    });

    testWidgets('assistant actions render copy, retry, fork, and feedback', (tester) async {
      var forked = false;
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiMsgHoverActions(
              isUser: false,
              onCopy: () {},
              onRetry: () => retried = true,
              onFork: () => forked = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.alt_route_rounded), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.alt_route_rounded));
      await tester.pump();
      expect(forked, isTrue);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(retried, isTrue);
    });
  });
}
