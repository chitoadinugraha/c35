import 'dart:typed_data';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
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

  test('ttsEngineRoute always routes to cloud', () {
    expect(TtsService.ttsEngineRoute('web'), 'cloud');
    expect(TtsService.ttsEngineRoute('local'), 'cloud');
    expect(TtsService.ttsEngineRoute('cloud'), 'cloud');
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
