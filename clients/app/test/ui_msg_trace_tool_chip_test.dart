import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('screenshot chip shows expand chevron and toggles preview', (tester) async {
    const chip = MsgTraceToolChip(
      label: 'Device screenshot',
      durationMs: 900,
      screenshot: TraceScreenshot(hash: 'abc123', width: 1280, height: 720, som: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UiMsgTraceToolChip(chip: chip)),
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byType(UiTraceScreenshotPreview), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();

    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    expect(find.byType(UiTraceScreenshotPreview), findsOneWidget);
    expect(find.textContaining('1280'), findsOneWidget);
    expect(find.textContaining('SoM'), findsOneWidget);
  });

  testWidgets('tool chip sizes to content width', (tester) async {
    const chip = MsgTraceToolChip(label: 'shell.run', durationMs: 825);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [UiMsgTraceToolChip(chip: chip)],
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byType(UiMsgTraceToolChip));
    expect(box.size.width, lessThan(240));
    expect(box.size.width, greaterThan(70));
  });

  testWidgets('chip without screenshot has no expand chevron', (tester) async {
    const chip = MsgTraceToolChip(label: 'Searched web', durationMs: 200);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UiMsgTraceToolChip(chip: chip)),
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.expand_less_rounded), findsNothing);
  });
}