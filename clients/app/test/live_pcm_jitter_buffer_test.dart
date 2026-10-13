import 'dart:typed_data';

import 'package:alienai_c35/c/live/live_pcm_jitter_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _pcmBytes(int sampleCount) {
  return Uint8List(sampleCount * 2);
}

void main() {
  group('LivePcmJitterBuffer', () {
    test('empty read returns empty and signals underrun', () {
      var underruns = 0;
      final buf = LivePcmJitterBuffer(
        sampleRateHz: 24000,
        onUnderrun: () => underruns++,
      );

      expect(buf.takeForPlayback(480), isEmpty);
      expect(buf.readFrame(240), isEmpty);
      expect(underruns, 2);
      expect(buf.bufferedMs(), 0);
    });

    test('fill and drain PCM in order', () {
      final buf = LivePcmJitterBuffer(sampleRateHz: 24000);
      final a = _pcmBytes(100);
      final b = _pcmBytes(50);
      buf.write(a);
      buf.write(b);

      expect(buf.length, 300);
      expect(buf.bufferedMs(), closeTo(6, 1));

      final chunk = buf.takeForPlayback(200);
      expect(chunk.length, 200);
      expect(buf.length, 100);

      final rest = buf.takeForPlayback(1000);
      expect(rest.length, 100);
      expect(buf.isEmpty, isTrue);
    });

    test('caps stored audio at ceiling duration', () {
      final buf = LivePcmJitterBuffer(
        sampleRateHz: 24000,
        ceilingTargetMs: 1200,
      );
      // 2 seconds of audio at 24kHz mono = 96000 bytes
      buf.write(Uint8List(96000));
      expect(buf.bufferedMs(), lessThanOrEqualTo(1200));
      expect(buf.length, 24000 * 2 * 1200 ~/ 1000);
    });

    test('adaptive target grows on high inter-arrival jitter', () {
      final buf = LivePcmJitterBuffer(
        sampleRateHz: 24000,
        floorTargetMs: 250,
        ceilingTargetMs: 1200,
        jitterThresholdMs: 80,
      );
      expect(buf.targetBufferMs, 250);

      for (var i = 0; i < 20; i++) {
        buf.recordInterArrivalForTesting(150);
      }
      expect(buf.p95InterArrivalMsForTesting(), greaterThan(80));
      expect(buf.targetBufferMs, greaterThan(250));
      expect(buf.targetBufferMs, lessThanOrEqualTo(1200));
    });

    test('adaptive target does not exceed ceiling', () {
      final buf = LivePcmJitterBuffer(
        sampleRateHz: 24000,
        floorTargetMs: 250,
        ceilingTargetMs: 1200,
      );
      for (var i = 0; i < 40; i++) {
        buf.recordInterArrivalForTesting(500);
      }
      expect(buf.targetBufferMs, 1200);
    });

    test('clear resets buffer and target', () {
      final buf = LivePcmJitterBuffer(sampleRateHz: 24000);
      buf.recordInterArrivalForTesting(200);
      buf.write(_pcmBytes(1000));
      expect(buf.isNotEmpty, isTrue);
      expect(buf.targetBufferMs, greaterThan(250));

      buf.clear();
      expect(buf.isEmpty, isTrue);
      expect(buf.targetBufferMs, 250);
    });
  });
}
