import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/widgets/ai/ui_subagent_run_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PromptUsagePrefs.instance.load();
    await PromptUsagePrefs.instance.setShowUsageStats(true);
  });

  testWidgets('UiSubagentRunCard shows label, running status, and stop button', (tester) async {
    var stopped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSubagentRunCard(
            conn: ChatConn(),
            chatId: 1,
            push: PromptRunPush(
              parentReqId: 'parent-1',
              label: 'Research Jakarta weather',
              status: 'running',
            ),
            onStop: () => stopped = true,
          ),
        ),
      ),
    );

    expect(find.text('Research Jakarta weather'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    expect(stopped, isTrue);
  });

  testWidgets('UiSubagentRunCard hides stop button when done', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSubagentRunCard(
            conn: ChatConn(),
            chatId: 1,
            push: PromptRunPush(
              reqId: 'child-2',
              parentReqId: 'parent-1',
              label: 'Compare Rust vs Go',
              status: 'done',
              tokensIn: 1200,
              tokensOut: 480,
              durationMs: 5400,
              costUsd: 0.012,
            ),
            onStop: () {},
          ),
        ),
      ),
    );

    expect(find.text('Compare Rust vs Go'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
    expect(find.text('1,200'), findsOneWidget);
    expect(find.text('480'), findsOneWidget);
  });

  testWidgets('UiSubagentRunCard shows failed status with reason tooltip target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSubagentRunCard(
            conn: ChatConn(),
            chatId: 1,
            push: PromptRunPush(
              reqId: 'child-3',
              parentReqId: 'parent-1',
              label: 'Device screenshot',
              status: 'failed',
              failReason: 'Agent offline',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Device screenshot'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('UiSubagentRunCard hides usage row while running', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSubagentRunCard(
            conn: ChatConn(),
            chatId: 1,
            push: PromptRunPush(
              parentReqId: 'parent-1',
              label: 'Queued task',
              status: 'queued',
              tokensIn: 900,
              tokensOut: 100,
              durationMs: 1000,
              costUsd: 0.01,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Queued'), findsOneWidget);
    expect(find.text('900'), findsNothing);
  });
}
