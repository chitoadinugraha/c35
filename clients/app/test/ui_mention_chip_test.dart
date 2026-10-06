import 'package:alienai_c35/widgets/ai/ui_mention_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mention chip shows label and clears once', (tester) async {
    var clears = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: UiMentionChip(label: 'Desk', onClear: () => clears++)),
    ));
    expect(find.text('Desk'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear mention'));
    await tester.pump();
    expect(clears, 1);
  });

  testWidgets('empty mention label builds no chip', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: UiMentionChip(label: '  ', onClear: () {})),
    ));
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('  '), findsNothing);
  });
}
