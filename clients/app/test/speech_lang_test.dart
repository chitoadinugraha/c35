import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects Indonesian from common particles', () {
    expect(speechLangDetect('Apa kabar kamu hari ini?'), 'id-ID');
  });

  test('detects English from function words', () {
    expect(speechLangDetect('What is the latest status of the project?'), 'en-US');
  });

  test('returns null when there are no language hints', () {
    expect(speechLangDetect('12345 !!!'), isNull);
  });

  test('auto mode ignores stale lastLang and defaults to Indonesian', () {
    expect(speechLangResolve('123', last: 'en-US', locale: kSpeechLangAuto), kSpeechLangFallback);
    expect(speechLangResolve('saya mau kopi', last: 'en-US', locale: kSpeechLangAuto), 'id-ID');
  });

  test('explicit locale wins over lastLang when detection is empty', () {
    expect(speechLangResolve('123', last: 'en-US', locale: 'id-ID'), 'id-ID');
    expect(speechLangResolve('123', last: 'id-ID', locale: 'en-US'), 'en-US');
  });

  test('resolve uses lastLang only for explicit non-auto locale without hints', () {
    expect(speechLangResolve('123', last: 'en-US', locale: 'en-US'), 'en-US');
  });

  test('cleanTextForSpeech strips markdown and urls', () {
    final clean = speechTextClean('Hello **world** see https://x.com and `code`');
    expect(clean.contains('http'), isFalse);
    expect(clean.contains('**'), isFalse);
    expect(clean.contains('Hello'), isTrue);
    expect(clean.contains('world'), isTrue);
  });

  test('speechTextCap keeps two sentences', () {
    expect(speechTextCap('One. Two. Three.', maxSentences: 2), 'One. Two.');
  });
}
