import 'package:alienai_c35/widgets/ai/ui_msg_bad_ai_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showMsgBadAiReportReasonMenu returns selected reason', (tester) async {
    String? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showMsgBadAiReportReasonMenu(
                  context: context,
                  global: const Offset(120, 120),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Harmful or unsafe'), findsOneWidget);
    await tester.tap(find.text('Harmful or unsafe'));
    await tester.pumpAndSettle();

    expect(picked, 'Harmful or unsafe');
  });
}
