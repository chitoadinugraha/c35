import 'package:alienai_c35/widgets/ai/ui_audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiAudioWaveform displays duration timer and triggers cancel / commit', (tester) async {
    final recordingSeconds = ValueNotifier<int>(65);
    final amplitude = ValueNotifier<double>(0.75);
    var cancelled = false;
    var committed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: recordingSeconds,
            amplitude: amplitude,
            onCancel: () => cancelled = true,
            onCommit: () => committed = true,
          ),
        ),
      ),
    );

    // 65 seconds -> 01:05
    expect(find.text('01:05'), findsOneWidget);

    // Tap cancel button (Icons.close_rounded)
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(cancelled, isTrue);

    // Tap commit button ('Done')
    await tester.tap(find.text('Done'));
    expect(committed, isTrue);
  });
}
