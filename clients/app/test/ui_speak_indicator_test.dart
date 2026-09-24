import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/widgets/ai/ui_speak_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('speak indicator hidden when not speaking', (tester) async {
    TtsService.instance.isSpeaking.value = false;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: UiSpeakIndicator())));
    expect(find.textContaining('Speaking in'), findsNothing);
  });

  testWidgets('speak indicator shows language and stop tap', (tester) async {
    TtsService.instance.isSpeaking.value = true;
    TtsService.instance.speakingLang.value = 'id-ID';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: UiSpeakIndicator())));
    await tester.pump();
    expect(find.text('Speaking in Indonesian...'), findsOneWidget);
    await tester.tap(find.byType(GestureDetector));
    expect(TtsService.instance.isSpeaking.value, isFalse);
  });
}
