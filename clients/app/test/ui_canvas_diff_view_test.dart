import 'package:alienai_c35/c/canvas/canvas_diff.dart';
import 'package:alienai_c35/widgets/ai/ui_canvas_diff_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiCanvasDiffView renders labels, stats, and diff rows', (tester) async {
    final diff = [
      const CanvasDiffLine(type: CanvasDiffType.unchanged, text: 'unchanged line', oldLine: 1, newLine: 1),
      const CanvasDiffLine(type: CanvasDiffType.removed, text: 'old removed line', oldLine: 2),
      const CanvasDiffLine(type: CanvasDiffType.added, text: 'new inserted line', newLine: 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiCanvasDiffView(
            oldTitle: 'v1',
            newTitle: 'v2',
            diffLines: diff,
          ),
        ),
      ),
    );

    expect(find.text('Comparing v1 ➔ v2'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
    expect(find.text('unchanged line'), findsOneWidget);
    expect(find.text('old removed line'), findsOneWidget);
    expect(find.text('new inserted line'), findsOneWidget);
  });

  testWidgets('UiCanvasDiffView renders empty notice when diff is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UiCanvasDiffView(
            oldTitle: 'v1',
            newTitle: 'Draft',
            diffLines: [],
          ),
        ),
      ),
    );

    expect(find.text('No differences detected'), findsOneWidget);
  });
}
