import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Adaptive PCM playout buffer for Live Call downlink (mono s16le).
class LivePcmJitterBuffer {
  LivePcmJitterBuffer({
    required int sampleRateHz,
    this.onUnderrun,
    this.floorTargetMs = 250,
    this.ceilingTargetMs = 1200,
    this.jitterThresholdMs = 80,
  })  : _sampleRateHz = sampleRateHz,
        _targetBufferMs = floorTargetMs;

  static const int _bytesPerSample = 2;
  static const int _maxInterArrivalSamples = 64;

  final VoidCallback? onUnderrun;
  final int floorTargetMs;
  final int ceilingTargetMs;
  final int jitterThresholdMs;

  int _sampleRateHz;
  int _targetBufferMs;
  int _underrunCount = 0;
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  final List<int> _interArrivalMs = [];
  DateTime? _lastWriteAt;

  int get sampleRateHz => _sampleRateHz;
  int get targetBufferMs => _targetBufferMs;
  int get underrunCount => _underrunCount;
  int get length => _pcm.length;
  bool get isEmpty => _pcm.isEmpty;
  bool get isNotEmpty => _pcm.isNotEmpty;

  int bufferedMs() {
    if (_sampleRateHz <= 0 || _pcm.isEmpty) return 0;
    return (_pcm.length * 1000) ~/ (_sampleRateHz * _bytesPerSample);
  }

  void setSampleRateHz(int rate) {
    if (rate > 0) _sampleRateHz = rate;
  }

  void write(Uint8List pcm) {
    if (pcm.isEmpty) return;
    final now = DateTime.now();
    if (_lastWriteAt != null) {
      _recordInterArrival(now.difference(_lastWriteAt!).inMilliseconds);
      _adaptTargetBuffer();
    }
    _lastWriteAt = now;
    _pcm.add(pcm);
    _trimToCeilingBytes();
  }

  Uint8List readFrame(int frameSamples) {
    if (frameSamples <= 0) return Uint8List(0);
    return takeForPlayback(frameSamples * _bytesPerSample);
  }

  Uint8List takeForPlayback(int maxBytes) {
    if (maxBytes <= 0) return Uint8List(0);
    if (_pcm.isEmpty) {
      _underrunCount++;
      onUnderrun?.call();
      return Uint8List(0);
    }
    if (_pcm.length <= maxBytes) {
      return _pcm.takeBytes();
    }
    final all = _pcm.takeBytes();
    final chunk = Uint8List.sublistView(all, 0, maxBytes);
    final remaining = Uint8List.sublistView(all, maxBytes);
    _pcm.add(remaining);
    return chunk;
  }

  void clear() {
    _pcm.clear();
    _lastWriteAt = null;
    _interArrivalMs.clear();
    _targetBufferMs = floorTargetMs;
    _underrunCount = 0;
  }

  void _recordInterArrival(int ms) {
    if (ms <= 0) return;
    _interArrivalMs.add(ms);
    while (_interArrivalMs.length > _maxInterArrivalSamples) {
      _interArrivalMs.removeAt(0);
    }
  }

  void _adaptTargetBuffer() {
    final p95 = _p95InterArrivalMs();
    if (p95 > jitterThresholdMs) {
      final bump = max(25, (p95 - jitterThresholdMs) ~/ 2);
      _targetBufferMs = min(ceilingTargetMs, _targetBufferMs + bump);
    } else if (_interArrivalMs.length >= 8) {
      _targetBufferMs = max(floorTargetMs, _targetBufferMs - 5);
    }
  }

  int _p95InterArrivalMs() {
    if (_interArrivalMs.isEmpty) return 0;
    final sorted = List<int>.from(_interArrivalMs)..sort();
    final idx = ((sorted.length - 1) * 0.95).ceil().clamp(0, sorted.length - 1);
    return sorted[idx];
  }

  void _trimToCeilingBytes() {
    final maxBytes = _bytesForMs(ceilingTargetMs);
    if (maxBytes <= 0 || _pcm.length <= maxBytes) return;
    final excess = _pcm.length - maxBytes;
    final all = _pcm.takeBytes();
    _pcm.add(Uint8List.sublistView(all, excess));
  }

  int _bytesForMs(int ms) {
    if (_sampleRateHz <= 0) return 0;
    return (_sampleRateHz * _bytesPerSample * ms) ~/ 1000;
  }

  @visibleForTesting
  int p95InterArrivalMsForTesting() => _p95InterArrivalMs();

  @visibleForTesting
  void recordInterArrivalForTesting(int ms) {
    _recordInterArrival(ms);
    _adaptTargetBuffer();
  }
}
