import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ai/ui_talk_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PromptUsagePrefs.instance.load();
  });

  MsgRow assistant() => MsgRow(id: 1, chatId: 1, role: 'assistant', content: 'Hello there');

  Future<void> pump(
    WidgetTester tester, {
    MsgRow? row,
    required bool listening,
    MsgUsageStats? usage,
    bool speakEnabled = true,
    bool busy = false,
    String userText = 'what time is it',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiTalkStage(
            assistant: row,
            userText: userText,
            listening: listening,
            busy: busy,
            speakEnabled: speakEnabled,
            onMic: () {},
            onSpeak: () {},
            onAttach: () {},
            onModel: () {},
            usage: usage,
          ),
        ),
      ),
    );
  }

  testWidgets('shows assistant text, user text, and speaker without usage', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(false);
    await pump(
      tester,
      row: assistant(),
      listening: false,
      speakEnabled: true,
      usage: const MsgUsageStats(tokensIn: 10, tokensOut: 4, durationMs: 1500),
    );
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('what time is it'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.textContaining(' in'), findsNothing);
    expect(find.textContaining(' out'), findsNothing);
  });

  testWidgets('shows usage line when the pref is on', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(true);
    await pump(
      tester,
      row: assistant(),
      listening: false,
      usage: const MsgUsageStats(tokensIn: 10, tokensOut: 4, durationMs: 1500),
    );
    expect(find.textContaining(' in'), findsOneWidget);
    expect(find.textContaining(' out'), findsOneWidget);
  });

  testWidgets('shows Thinking... in the usage slot while busy', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(true);
    await pump(
      tester,
      row: assistant(),
      listening: false,
      busy: true,
      usage: const MsgUsageStats(tokensIn: 10, tokensOut: 4, durationMs: 1500),
    );
    expect(find.text('Thinking...'), findsOneWidget);
    expect(find.textContaining(' in'), findsNothing);
  });

  testWidgets('shows Listening when assistant is null and listening', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(false);
    await pump(tester, listening: true);
    expect(find.text('Listening...'), findsOneWidget);
  });

  testWidgets('shows mic without idle hint copy when idle', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(false);
    await pump(tester, row: null, listening: false, userText: '');
    expect(find.textContaining('Tap'), findsNothing);
    expect(find.textContaining('to start'), findsNothing);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('scrolls tall assistant text without overflow', (tester) async {
    await PromptUsagePrefs.instance.setShowUsageStats(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: UiTalkStage(
              assistant: MsgRow(id: 1, chatId: 1, role: 'assistant', content: List.filled(40, 'Hello there').join('\n')),
              userText: 'what time is it',
              listening: false,
              busy: false,
              speakEnabled: false,
              onMic: () {},
              onSpeak: () {},
              onAttach: () {},
              onModel: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Hello there'), findsOneWidget);
    expect(find.text('what time is it'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
