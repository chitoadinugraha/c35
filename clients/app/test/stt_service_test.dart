import 'dart:typed_data';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeVoiceApi extends VoiceApi {
  _FakeVoiceApi({this.sttResult}) : super(ChatConn());

  final String? sttResult;

  @override
  Future<String?> sttTranscribe({
    required Uint8List audio,
    required String mime,
    String? lang,
    String? reqId,
  }) async =>
      sttResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VoicePrefs.instance.load();
    SttService.instance.bindVoiceApi(null);
  });

  test('sttEngineRoute maps engines correctly and defaults to web', () {
    expect(VoicePrefs.instance.sttEngine, 'web');
    expect(SttService.sttEngineRoute('web'), 'web');
    expect(SttService.sttEngineRoute('local'), 'local');
    expect(SttService.sttEngineRoute('cloud'), 'cloud');
  });

  test('transcribeRouted uses web path when engine is web', () async {
    await VoicePrefs.instance.setSttEngine('web');
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List.fromList([1, 2, 3]),
      lang: 'en-US',
      mime: 'audio/wav',
      webTranscribe: (_, lang, mime) async {
        expect(lang, 'en-US');
        expect(mime, 'audio/wav');
        return 'web transcript';
      },
    );
    expect(result, 'web transcript');
  });

  test('transcribeRouted uses VoiceApi when engine is cloud', () async {
    await VoicePrefs.instance.setSttEngine('cloud');
    SttService.instance.bindVoiceApi(_FakeVoiceApi(sttResult: 'cloud transcript'));
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List.fromList([4, 5]),
      lang: 'id-ID',
      mime: 'audio/ogg',
      webTranscribe: (_, __, ___) async => 'should not run',
    );
    expect(result, 'cloud transcript');
  });

  test('transcribeRouted returns null for cloud without VoiceApi', () async {
    await VoicePrefs.instance.setSttEngine('cloud');
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List(0),
      lang: 'en-US',
      mime: 'audio/wav',
      webTranscribe: (_, __, ___) async => 'web',
    );
    expect(result, isNull);
  });

  test('sanitizeTranscript filters out 00:00, timestamps, and silence tokens', () {
    expect(SttService.sanitizeTranscript('00:00'), '');
    expect(SttService.sanitizeTranscript('0:00'), '');
    expect(SttService.sanitizeTranscript('00:00 - 00:03'), '');
    expect(SttService.sanitizeTranscript('[silence]'), '');
    expect(SttService.sanitizeTranscript('(silence)'), '');
    expect(SttService.sanitizeTranscript('   '), '');
    expect(SttService.sanitizeTranscript('Hello world'), 'Hello world');
    expect(SttService.sanitizeTranscript('Halo apa kabar'), 'Halo apa kabar');
  });

  test('transcribeRouted filters out 00:00 hallucinated response from cloud STT', () async {
    await VoicePrefs.instance.setSttEngine('cloud');
    SttService.instance.bindVoiceApi(_FakeVoiceApi(sttResult: '00:00'));
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List.fromList([4, 5]),
      lang: 'id-ID',
      mime: 'audio/wav',
    );
    expect(result, isNull);
  });
}
