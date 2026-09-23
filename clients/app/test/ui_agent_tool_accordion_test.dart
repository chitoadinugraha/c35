import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_agent_tool_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiAgentToolAccordion shows summary header and toggles expansion', (tester) async {
    final chips = [
      const MsgTraceToolChip(label: 'Search web', durationMs: 420, ok: true),
      const MsgTraceToolChip(label: 'Run build command', durationMs: 1250, ok: false),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UiAgentToolAccordion(chips: chips, live: false),
          ),
        ),
      ),
    );

    // Header summary
    expect(find.text('Agent executed 2 steps'), findsOneWidget);
    expect(find.text('Search web'), findsNothing);

    // Tap to expand
    await tester.tap(find.text('Agent executed 2 steps'));
    await tester.pumpAndSettle();

    // Now steps should be visible
    expect(find.text('Search web'), findsOneWidget);
    expect(find.text('Run build command'), findsOneWidget);
    expect(find.text('420ms'), findsOneWidget);
    expect(find.text('1250ms'), findsOneWidget);

    // Tap to collapse
    await tester.tap(find.text('Agent executed 2 steps'));
    await tester.pumpAndSettle();

    expect(find.text('Search web'), findsNothing);
  });

  testWidgets('UiAgentToolAccordion live mode shows progress badge', (tester) async {
    final chips = [
      const MsgTraceToolChip(label: 'Search codebase', durationMs: 150, ok: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAgentToolAccordion(chips: chips, live: true),
        ),
      ),
    );

    expect(find.text('Agent executing step 1...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
