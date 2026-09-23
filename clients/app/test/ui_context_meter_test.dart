import 'package:alienai_c35/widgets/ai/ui_context_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiContextMeter', () {
    testWidgets('renders token count, percentage, and tooltip', (tester) async {
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

      // 24500 tokens -> ~24.5k (19%)
      expect(find.text('24.5k (19%)'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides when totalTokens is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiContextMeter(
                tokensIn: 0,
                tokensOut: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UiContextMeter), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
