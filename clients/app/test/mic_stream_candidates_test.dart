import 'package:alienai_c35/c/audio/mic_stream_candidates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web prefers 16k mono first', () {
    final c = micStreamCandidates(isMobile: false, isWeb: true);
    expect(c.first.sampleRate, 16000);
    expect(c.first.numChannels, 1);
  });

  test('mobile prefers 16k mono first', () {
    final c = micStreamCandidates(isMobile: true, isWeb: false);
    expect(c.first.sampleRate, 16000);
    expect(c.first.numChannels, 1);
  });

  test('desktop non-web keeps stereo 48k first', () {
    final c = micStreamCandidates(isMobile: false, isWeb: false);
    expect(c.first.sampleRate, 48000);
    expect(c.first.numChannels, 2);
  });
}
