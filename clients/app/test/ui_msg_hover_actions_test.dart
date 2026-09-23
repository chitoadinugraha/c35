import 'package:alienai_c35/widgets/ai/ui_msg_hover_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiMsgHoverActions', () {
    testWidgets('user actions render copy and more menu with edit', (tester) async {
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
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copied, isTrue);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Edit prompt'), findsOneWidget);

      await tester.tap(find.text('Edit prompt'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);
    });

    testWidgets('assistant actions keep copy visible and move extras to more menu', (tester) async {
      var forked = false;
      var retried = false;
      String? reportReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UiMsgHoverActions(
              isUser: false,
              onCopy: () {},
              onRetry: () => retried = true,
              onFork: () => forked = true,
              onGood: () {},
              onReportBad: (reason) => reportReason = reason,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      expect(find.byIcon(Icons.alt_route_rounded), findsNothing);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Fork chat from here'), findsOneWidget);
      expect(find.text('Regenerate response'), findsOneWidget);
      expect(find.text('Report Bad AI'), findsOneWidget);

      await tester.tap(find.text('Fork chat from here'));
      await tester.pumpAndSettle();
      expect(forked, isTrue);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regenerate response'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Bad AI'));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect information'), findsOneWidget);

      await tester.tap(find.text('Incorrect information'));
      await tester.pumpAndSettle();
      expect(reportReason, 'Incorrect information');
      expect(find.text('Thanks for the report'), findsOneWidget);
    });
  });
}
