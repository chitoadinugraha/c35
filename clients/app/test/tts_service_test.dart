import 'dart:async';
import 'dart:typed_data';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVoiceApi extends VoiceApi {
  _FakeVoiceApi({this.ttsBytes}) : super(ChatConn());

  final Uint8List? ttsBytes;

  @override
  Future<({Uint8List bytes, String mime})?> ttsSynthesize({
    required String text,
    String? lang,
    String? reqId,
  }) async {
    if (ttsBytes == null) return null;
    return (bytes: ttsBytes!, mime: 'audio/mpeg');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VoicePrefs.instance.load();
    TtsService.instance.bindVoiceApi(null);
  });

  test('speakPreparedText keeps full cleaned message', () {
    const raw = 'One. Two. Three. Four.';
    expect(TtsService.speakPreparedText(raw), 'One. Two. Three. Four.');
    expect(speechTextCap(TtsService.speakPreparedText(raw)), 'One. Two.');
  });

  test('ttsEngineRoute returns persisted engine choice', () {
    expect(TtsService.ttsEngineRoute('web'), 'web');
    expect(TtsService.ttsEngineRoute('local'), 'local');
    expect(TtsService.ttsEngineRoute('cloud'), 'cloud');
    expect(TtsService.ttsEngineRoute('unknown'), 'cloud');
  });

  test('speakRouted uses web fetch for web engine', () async {
    final played = await TtsService.instance.speakRouted(
      engine: 'web',
      spoken: 'Hello',
      effectiveLang: 'en-US',
      speechRate: 1.0,
      webFetch: (spoken, lang) async {
        expect(spoken, 'Hello');
        expect(lang, 'en-US');
        return Uint8List.fromList([9, 8, 7]);
      },
    );
    expect(played, isFalse);
  });

  test('speakRouted uses cloud synthesize callback', () async {
    final played = await TtsService.instance.speakRouted(
      engine: 'cloud',
      spoken: 'Hi',
      effectiveLang: 'en-US',
      speechRate: 1.0,
      cloudSynthesize: ({required text, lang}) async {
        expect(text, 'Hi');
        expect(lang, 'en-US');
        return (bytes: Uint8List.fromList([1, 2, 3]), mime: 'audio/mpeg');
      },
    );
    expect(played, isFalse);
  });

  test('speakRouted returns false for cloud without VoiceApi', () async {
    final played = await TtsService.instance.speakRouted(
      engine: 'cloud',
      spoken: 'Hi',
      effectiveLang: 'en-US',
      speechRate: 1.0,
    );
    expect(played, isFalse);
  });

  test('speakRouted uses bound VoiceApi for cloud engine', () async {
    TtsService.instance.bindVoiceApi(_FakeVoiceApi(ttsBytes: Uint8List.fromList([5, 6])));
    final played = await TtsService.instance.speakRouted(
      engine: 'cloud',
      spoken: 'Cloud',
      effectiveLang: 'en-US',
      speechRate: 1.0,
    );
    expect(played, isFalse);
  });

  test('stream queue speaks a markdown list as one clip', () async {
    final spoken = <String>[];
    final q = TtsStreamQueue(
      speak: (text) async {
        spoken.add(text);
      },
    );
    q.feedChunk('Points:\n');
    q.feedChunk('- Alpha\n- Beta\n');
    q.feedChunk('- Gamma\n');
    expect(spoken, isEmpty);
    q.flush();
    await Future<void>.delayed(Duration.zero);
    expect(spoken, ['Points: Alpha, Beta, Gamma']);
  });

  test('stream queue stop drops clips not yet spoken', () async {
    final spoken = <String>[];
    final started = Completer<void>();
    final release = Completer<void>();
    final q = TtsStreamQueue(
      speak: (text) async {
        spoken.add(text);
        if (!started.isCompleted) started.complete();
        await release.future;
      },
    );
    final firstClip = 'Alpha beta gamma. ' * 80;
    final secondClip = 'Delta epsilon zeta. ' * 80;
    q.feedChunk('$firstClip\n\n');
    q.feedChunk(secondClip);
    await started.future.timeout(const Duration(seconds: 2));
    q.cancel();
    release.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(spoken, hasLength(1));
    expect(q.isHalted, isTrue);
  });

  test('stop halts the active stream queue', () async {
    final q = TtsStreamQueue();
    await TtsService.instance.stop();
    expect(q.isHalted, isTrue);
  });

  test('speakRouted returns false for local engine', () async {
    await VoicePrefs.instance.setTtsEngine('local');
    final played = await TtsService.instance.speakRouted(
      engine: 'local',
      spoken: 'Local only',
      effectiveLang: 'en-US',
      speechRate: 1.0,
      webFetch: (_, __) async => Uint8List(3),
    );
    expect(played, isFalse);
  });
}
