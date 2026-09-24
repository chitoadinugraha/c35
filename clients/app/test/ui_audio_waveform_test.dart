import 'package:alienai_c35/widgets/ai/ui_audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiAudioWaveform displays duration timer and triggers cancel / commit', (tester) async {
    final recordingSeconds = ValueNotifier<int>(65);
    final amplitude = ValueNotifier<double>(0.75);
    final amplitudeHistory = ValueNotifier<List<double>>([0.2, 0.5, 0.75]);
    var cancelled = false;
    var committed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: recordingSeconds,
            amplitude: amplitude,
            amplitudeHistory: amplitudeHistory,
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

    // Tap commit button (Icons.arrow_upward_rounded)
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(committed, isTrue);
  });

  testWidgets('UiAudioWaveform shows cloud icon when transcribing with cloud engine', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: ValueNotifier(5),
            amplitude: ValueNotifier(0.5),
            isTranscribing: ValueNotifier(true),
            engine: 'cloud',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.text('Recognizing…'), findsOneWidget);
  });

  testWidgets('UiAudioWaveform shows web icon when transcribing with web engine', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: ValueNotifier(5),
            amplitude: ValueNotifier(0.5),
            isTranscribing: ValueNotifier(true),
            engine: 'web',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.text('Recognizing…'), findsOneWidget);
  });

  testWidgets('UiAudioWaveform shows preparing state without timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: ValueNotifier(0),
            amplitude: ValueNotifier(0.0),
            isPreparing: ValueNotifier(true),
            engine: 'web',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.text('Preparing…'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('UiAudioWaveform shows device icon when transcribing with local engine', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiAudioWaveform(
            recordingSeconds: ValueNotifier(5),
            amplitude: ValueNotifier(0.5),
            isTranscribing: ValueNotifier(true),
            engine: 'local',
            onCancel: () {},
            onCommit: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
    expect(find.text('Recognizing…'), findsOneWidget);
  });
}
