import 'dart:typed_data';

import 'package:alienai_c35/c/live/live_call_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _makePcm16({required int sampleCount, required int sampleValue}) {
  final data = Uint8List(sampleCount * 2);
  final bd = ByteData.sublistView(data);
  for (var i = 0; i < sampleCount; i++) {
    bd.setInt16(i * 2, sampleValue, Endian.little);
  }
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveCallSession - Track D: Client-Side VAD', () {
    test('computes RMS energy correctly for 16-bit PCM', () {
      final silence = _makePcm16(sampleCount: 160, sampleValue: 0);
      expect(LiveCallSession.computeRms(silence), 0.0);

      final quiet = _makePcm16(sampleCount: 160, sampleValue: 200);
      expect(LiveCallSession.computeRms(quiet), closeTo(200.0, 0.1));

      final loud = _makePcm16(sampleCount: 160, sampleValue: 1500);
      expect(LiveCallSession.computeRms(loud), closeTo(1500.0, 0.1));

      // Negative samples in two's complement
      final loudNegative = _makePcm16(sampleCount: 160, sampleValue: -1500);
      expect(LiveCallSession.computeRms(loudNegative), closeTo(1500.0, 0.1));
    });

    test('suppresses silence packets and buffers in 150ms rolling ring buffer', () {
      final session = LiveCallSession();
      final sentData = <dynamic>[];
      session.onWebSocketSendForTesting = (data) => sentData.add(data);

      // 100ms chunk at 16kHz mono = 1600 samples = 3200 bytes
      final silence100ms = _makePcm16(sampleCount: 1600, sampleValue: 50);

      // Send 1st silence chunk: should NOT be transmitted
      session.processMicChunkWithVad(silence100ms);
      expect(sentData.isEmpty, isTrue);
      expect(session.isTransmittingSpeech, isFalse);
      expect(session.preSpeechBufferBytes, 3200);

      // Send 2nd silence chunk: total 6400 bytes, capped at 150ms (4800 bytes)
      session.processMicChunkWithVad(silence100ms);
      expect(sentData.isEmpty, isTrue);
      expect(session.isTransmittingSpeech, isFalse);
      expect(session.preSpeechBufferBytes, 3200); // 1st chunk dropped to stay <= 4800 bytes
      expect(session.preSpeechRingBufferCount, 1);
    });

    test('flushes pre-speech ring buffer immediately upon speech onset', () {
      final session = LiveCallSession();
      final sentData = <dynamic>[];
      session.onWebSocketSendForTesting = (data) => sentData.add(data);

      // Buffer 100ms of pre-speech silence (3200 bytes)
      final silence = _makePcm16(sampleCount: 1600, sampleValue: 30);
      session.processMicChunkWithVad(silence);
      expect(sentData.isEmpty, isTrue);
      expect(session.preSpeechBufferBytes, 3200);

      // Speech onset: RMS = 1200 > 500
      final speechChunk = _makePcm16(sampleCount: 1600, sampleValue: 1200);
      session.processMicChunkWithVad(speechChunk);

      // Should have flushed the pre-speech buffer first, then the current chunk
      expect(session.isTransmittingSpeech, isTrue);
      expect(sentData.length, 2);
      expect(sentData[0], silence);
      expect(sentData[1], speechChunk);
      expect(session.preSpeechBufferBytes, 0);
    });

    test('hangover window keeps transmitting for 1000ms after speech drops', () {
      final session = LiveCallSession();
      final sentData = <dynamic>[];
      session.onWebSocketSendForTesting = (data) => sentData.add(data);

      // Speech chunk
      final speechChunk = _makePcm16(sampleCount: 1600, sampleValue: 1000);
      session.processMicChunkWithVad(speechChunk);
      expect(session.isTransmittingSpeech, isTrue);
      expect(sentData.length, 1);

      // Silence chunk arrives immediately (< 400ms hangover)
      final silenceChunk = _makePcm16(sampleCount: 1600, sampleValue: 40);
      session.processMicChunkWithVad(silenceChunk);

      // Should transmit due to hangover window
      expect(sentData.length, 2);
      expect(sentData[1], silenceChunk);
    });

    test('speech onset transmits mic chunk and interruption clears playback', () {
      final session = LiveCallSession();
      final sentData = <dynamic>[];
      session.onWebSocketSendForTesting = (data) => sentData.add(data);

      // Simulate playback in progress
      session.setPlayBusyForTesting(true);
      session.addIncomingPcmForTesting(_makePcm16(sampleCount: 4800, sampleValue: 100));
      expect(session.incomingPcmBytes, greaterThan(0));
      expect(session.playBusy, isTrue);

      // User speaks -> mic chunk sent to server
      final speech = _makePcm16(sampleCount: 1600, sampleValue: 1200);
      session.processMicChunkWithVad(speech);
      expect(sentData.length, greaterThan(0));

      // Server echoes interruption or user triggers interruption
      session.handleInterruptionForTesting();

      // Incoming audio buffer cleared immediately
      expect(session.incomingPcmBytes, 0);
      expect(session.playBusy, isFalse);
    });
  });

  group('LiveCallSession - Track E: Playback Buffer & Ping-Pong', () {
    test('extracts burst accumulation segments up to 3 seconds', () {
      final session = LiveCallSession();
      session.setAudioSampleRateForTesting(24000); // 24kHz = 48000 bytes/sec

      // Add 5 seconds of audio (240000 bytes)
      final fiveSeconds = Uint8List(240000);
      session.addIncomingPcmForTesting(fiveSeconds);
      expect(session.incomingPcmBytes, 240000);

      // Extract chunk with max 3.0 seconds
      final chunk1 = session.extractPlaybackChunkForTesting(maxDurationSec: 3.0);
      // 3.0 sec * 48000 bytes/sec = 144000 bytes
      expect(chunk1.length, 144000);
      // Remaining bytes in buffer: 240000 - 144000 = 96000 (2.0 seconds)
      expect(session.incomingPcmBytes, 96000);

      // Extract next chunk
      final chunk2 = session.extractPlaybackChunkForTesting(maxDurationSec: 3.0);
      expect(chunk2.length, 96000);
      expect(session.incomingPcmBytes, 0);
    });

    test('calculates chunk duration accurately in milliseconds', () {
      final session = LiveCallSession();
      session.setAudioSampleRateForTesting(24000); // 48 bytes per millisecond

      // 600ms = 600 * 48 = 28800 bytes
      expect(session.chunkDurationMsForTesting(28800), 600);

      // 1500ms = 1500 * 48 = 72000 bytes
      expect(session.chunkDurationMsForTesting(72000), 1500);

      // 3000ms = 3000 * 48 = 144000 bytes
      expect(session.chunkDurationMsForTesting(144000), 3000);
    });

    test('handleInterruption clears buffers and resets playBusy', () {
      final session = LiveCallSession();
      session.addIncomingPcmForTesting(Uint8List(5000));
      expect(session.incomingPcmBytes, 5000);

      session.handleInterruptionForTesting();
      expect(session.incomingPcmBytes, 0);
      expect(session.playBusy, isFalse);
    });
  });

  group('LiveCallSession - Track B: Client Audio Routing, Camera JPEG & Flip', () {
    test('toggles speaker state and defaults to true', () async {
      final session = LiveCallSession();
      expect(session.speakerOn.value, isTrue);

      await session.toggleSpeaker();
      expect(session.speakerOn.value, isFalse);

      await session.toggleSpeaker();
      expect(session.speakerOn.value, isTrue);
    });

    test('switchCamera handles inactive camera stream gracefully', () async {
      final session = LiveCallSession();
      expect(session.cameraActive.value, isFalse);
      await expectLater(session.switchCamera(), completes);
    });

    test('compresses PNG video frame to JPEG', () {
      final testImg = img.Image(width: 160, height: 120);
      for (var y = 0; y < 120; y++) {
        for (var x = 0; x < 160; x++) {
          testImg.setPixelRgba(x, y, (x * 13 + y * 7) % 256, (x * 5 + y * 19) % 256, (x + y) % 256, 255);
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(testImg));

      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);

      final jpgBytes = LiveCallSession.compressFrameBytes(pngBytes);

      expect(jpgBytes[0], 0xFF);
      expect(jpgBytes[1], 0xD8);
      expect(jpgBytes[2], 0xFF);
      expect(jpgBytes.isNotEmpty, isTrue);
    });
  });
}
