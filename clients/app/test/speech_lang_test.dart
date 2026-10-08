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

  test('markdown lists become one spoken phrase without number pauses', () {
    const raw = '''
Here are the points:

1. Alpha
2. Beta
3. Gamma
''';
    final clean = speechTextClean(raw);
    expect(clean.contains('1.'), isFalse);
    expect(clean.contains('2.'), isFalse);
    expect(clean.contains('3.'), isFalse);
    expect(clean, 'Here are the points: Alpha, Beta, Gamma');
  });

  test('headings bold and bullets are plain speech', () {
    final clean = speechTextClean('## Shopping\n\n- **Milk**\n- Eggs');
    expect(clean.contains('#'), isFalse);
    expect(clean.contains('*'), isFalse);
    expect(clean.contains('-'), isFalse);
    expect(clean, 'Shopping. Milk, Eggs');
  });

  test('speechPullChunks keeps a bullet list in one clip until flush', () {
    const raw = 'Points:\n- Alpha\n- Beta\n- Gamma\n';
    final held = speechPullChunks(raw);
    expect(held.ready, isEmpty);
    expect(held.rest, raw);
    final done = speechPullChunks(held.rest, flush: true);
    expect(done.ready, ['Points: Alpha, Beta, Gamma']);
    expect(done.rest, isEmpty);
  });

  test('speechTextCap keeps two sentences', () {
    expect(speechTextCap('One. Two. Three.', maxSentences: 2), 'One. Two.');
  });
}
