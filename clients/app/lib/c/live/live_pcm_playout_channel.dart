import 'package:alienai_c35/c/live/live_pcm_playout.dart';
import 'package:flutter/services.dart';


class LivePcmPlayoutChannel implements LivePcmPlayout {
  static final MethodChannel _channel = MethodChannel(LivePcmPlayout.channelName);

  var _started = false;

  @override
  int get scheduledAheadMs => 0;

  @override
  Future<void> start(int sampleRateHz) async {
    if (_started) await stop();
    await _channel.invokeMethod<void>('start', {'sampleRate': sampleRateHz});
    _started = true;
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
  }
}
