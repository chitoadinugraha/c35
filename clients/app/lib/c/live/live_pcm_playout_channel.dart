import 'package:alienai_c35/c/live/live_pcm_playout.dart';
import 'package:flutter/services.dart';


class LivePcmPlayoutChannel implements LivePcmPlayout {
  static final MethodChannel _channel = MethodChannel(LivePcmPlayout.channelName);

  var _started = false;
  int _nativeQueuedMs = 0;

  @override
  int get scheduledAheadMs => _nativeQueuedMs;

  @override
  Future<void> refreshQueuedMs() async {
    if (!_started) {
      _nativeQueuedMs = 0;
      return;
    }
    try {
      _nativeQueuedMs = await _channel.invokeMethod<int>('queuedMs') ?? 0;
    } catch (_) {
      _nativeQueuedMs = 0;
    }
  }

  @override
  Future<void> start(int sampleRateHz) async {
    if (_started) await stop();
    final ok = await _channel.invokeMethod<bool>('start', {'sampleRate': sampleRateHz});
    if (ok != true) {
      throw StateError('Live PCM playout start failed');
    }
    _started = true;
    _nativeQueuedMs = 0;
  }

  @override
  Future<void> write(Uint8List pcm) async {
    if (!_started || pcm.isEmpty) return;
    await _channel.invokeMethod<void>('write', pcm);
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
    _started = false;
    _nativeQueuedMs = 0;
  }
}
