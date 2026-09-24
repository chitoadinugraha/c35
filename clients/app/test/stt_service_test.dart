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
  String? lastReqId;

  @override
  Future<String?> sttTranscribe({
    required Uint8List audio,
    required String mime,
    String? lang,
    String? reqId,
  }) async {
    lastReqId = reqId;
    return sttResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VoicePrefs.instance.load();
    SttService.instance.bindVoiceApi(null);
  });

  test('sttEngineRoute maps engines correctly and defaults appropriately', () {
    expect(VoicePrefs.instance.sttEngine, VoicePrefs.defaultSttEngine);
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

  test('transcribeRouted forwards interim reqId to VoiceApi', () async {
    await VoicePrefs.instance.setSttEngine('cloud');
    final fake = _FakeVoiceApi(sttResult: 'interim text');
    SttService.instance.bindVoiceApi(fake);
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List.fromList([10, 20]),
      lang: 'id-ID',
      mime: 'audio/wav',
      isInterim: true,
      reqId: 'interim_test_123',
    );
    expect(result, 'interim text');
    expect(fake.lastReqId, 'interim_test_123');
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

  test('pcmToWav generates valid WAV header matching PCM payload length and sample rate', () {
    final fakePcm = Uint8List(16000 * 2); // 1 second of 16kHz 16-bit mono PCM
    final wav = SttService.pcmToWav(fakePcm, sampleRate: 16000, channels: 1);
    expect(wav.length, 44 + fakePcm.length);
    // "RIFF"
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    // "WAVE"
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    // "fmt "
    expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
    // "data"
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
    // Sample rate at offset 24 (little-endian uint32)
    final byteData = ByteData.sublistView(wav);
    expect(byteData.getUint32(24, Endian.little), 16000);
    // Payload matches
    expect(wav.sublist(44), fakePcm);
  });

  test('pcmAmplitude computes correct level and norm for silence and peak signal', () {
    final silence = Uint8List(100);
    final silenceAmp = SttService.pcmAmplitude(silence);
    expect(silenceAmp.norm, 0.0);
    expect(silenceAmp.levelDb, -100.0);

    // Peak signal (32767 = 0xFF, 0x7F)
    final peak = Uint8List.fromList([0xFF, 0x7F]);
    final peakAmp = SttService.pcmAmplitude(peak);
    expect(peakAmp.norm, closeTo(1.0, 0.01));
    expect(peakAmp.levelDb, closeTo(0.0, 0.1));
  });

  test('transcribeRouted does not fall back to Gemini for web engine', () async {
    await VoicePrefs.instance.setSttEngine('web');
    final result = await SttService.instance.transcribeRouted(
      bytes: Uint8List.fromList([1, 2, 3]),
      lang: 'id-ID',
      mime: 'audio/wav',
    );
    expect(result, isNull);
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
