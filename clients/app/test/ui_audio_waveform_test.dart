import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/widgets/ai/ui_audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiAudioWaveform displays duration timer and triggers cancel / commit', (tester) async {
    final recordingElapsedMs = ValueNotifier<int>(65000);
    final amplitude = ValueNotifier<double>(0.75);
    final amplitudeHistory = ValueNotifier<List<double>>([0.2, 0.5, 0.75]);
    var cancelled = false;
    var committed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingElapsedMs: recordingElapsedMs,
            amplitude: amplitude,
            amplitudeHistory: amplitudeHistory,
            onCancel: () => cancelled = true,
            onCommit: () => committed = true,
          ),
        ),
      ),
    );

    expect(find.text('01:05.000'), findsOneWidget);
    expect(find.text('/ 00:30.000'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(cancelled, isTrue);

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(committed, isTrue);
  });

  testWidgets('UiAudioWaveform shows talk max duration cap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingElapsedMs: ValueNotifier(1000),
            amplitude: ValueNotifier(0.5),
            maxRecordingSeconds: SttService.maxRecordingSecondsTalk,
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.text('/ 01:00.000'), findsOneWidget);
  });

  testWidgets('UiAudioWaveform shows spinner while transcribing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingElapsedMs: ValueNotifier(5000),
            amplitude: ValueNotifier(0.5),
            isTranscribing: ValueNotifier(true),
            engine: 'cloud',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
  });

  testWidgets('UiAudioWaveform shows preparing state without elapsed timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingElapsedMs: ValueNotifier(0),
            amplitude: ValueNotifier(0.0),
            isPreparing: ValueNotifier(true),
            engine: 'web',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.text('composer.preparing'), findsOneWidget);
    expect(find.text('00:00.000'), findsNothing);
  });
}
