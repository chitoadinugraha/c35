import 'package:alienai_c35/widgets/ai/ui_context_meter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiContextMeter', () {
    testWidgets('renders circle progress ring', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiContextMeter(
                tokensIn: 20000,
                tokensOut: 4500,
                contextLimit: 128000,
                costUsd: 0.0034,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows hover summary on enter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiContextMeter(
                tokensIn: 20000,
                tokensOut: 4500,
                contextLimit: 128000,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(UiContextMeter)));
      await tester.pump();
      await tester.pump();

      expect(find.text('19% context used'), findsOneWidget);
      expect(find.text('24.5K / 128.0K tokens'), findsOneWidget);
    });

    testWidgets('hides when no tokens used', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiContextMeter(
                tokensIn: 0,
                tokensOut: 0,
                contextLimit: 128000,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UiContextMeter), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows detail dialog on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiContextMeter(
                tokensIn: 20000,
                tokensOut: 4500,
                contextLimit: 128000,
                costUsd: 0.0034,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UiContextMeter));
      await tester.pumpAndSettle();

      expect(find.text('Context Usage'), findsOneWidget);
      expect(find.text('Input'), findsOneWidget);
      expect(find.text('Output'), findsOneWidget);
    });
  });
}
