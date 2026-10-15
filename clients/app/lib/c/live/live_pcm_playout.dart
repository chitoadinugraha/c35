import 'dart:typed_data';

import 'live_pcm_playout_stub.dart'
    if (dart.library.html) 'live_pcm_playout_web.dart'
    if (dart.library.io) 'live_pcm_playout_io.dart' as playout_impl;

/// Streaming PCM output for Live Call (mono s16le).
abstract class LivePcmPlayout {
  static const String channelName = 'id.alienai/live_pcm_audio';

  static Future<LivePcmPlayout?> tryCreate() => playout_impl.createLivePcmPlayout();

  /// Resume Web Audio inside a user gesture (Connect tap). No-op on other platforms.
  static Future<void> warmUpForUserGesture() => playout_impl.warmUpLivePcmPlayout();

  /// Tear down web shared [AudioContext] after a call ends.
  static Future<void> disposePlatformAudio() => playout_impl.disposeLivePcmPlayout();

  /// Current audio duration scheduled ahead in the hardware timeline (milliseconds).
  int get scheduledAheadMs => 0;

  Future<void> start(int sampleRateHz);
  Future<void> write(Uint8List pcm);
  Future<void> stop();
}

