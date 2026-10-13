import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:alienai_c35/c/live/live_pcm_convert.dart';
import 'package:alienai_c35/c/live/live_pcm_playout.dart';
import 'package:web/web.dart';

AudioContext? _sharedWebAudioContext;
double _scheduledEndTime = 0;

Future<LivePcmPlayout?> createLivePcmPlayout() async {
  return LivePcmPlayoutWeb();
}

Future<void> warmUpLivePcmPlayout() async {
  final ctx = _ensureWebAudioContext();
  if (ctx.state == 'suspended') {
    await ctx.resume().toDart;
  }
}

Future<void> disposeLivePcmPlayout() => disposeSharedWebAudioContext();

AudioContext _ensureWebAudioContext() {
  return _sharedWebAudioContext ??= AudioContext();
}

class LivePcmPlayoutWeb implements LivePcmPlayout {
  AudioContext? _ctx;
  int _sampleRate = 24000;
  var _started = false;

  @override
  Future<void> start(int sampleRateHz) async {
    _sampleRate = sampleRateHz;
    _ctx = _ensureWebAudioContext();
    await warmUpLivePcmPlayout();
    final now = _ctx!.currentTime;
    _scheduledEndTime = now + 0.05;
    _started = true;
  }

  @override
  Future<void> write(Uint8List pcm) async {
    if (!_started || pcm.isEmpty) return;
    final ctx = _ctx;
    if (ctx == null) return;
    if (ctx.state == 'suspended') {
      await ctx.resume().toDart;
    }

    final numSamples = pcm.length ~/ 2;
    if (numSamples <= 0) return;

    final buffer = ctx.createBuffer(1, numSamples, _sampleRate);
    final floats = pcmS16leToFloat32(pcm);
    buffer.copyToChannel(floats.toJS, 0, 0);

    final source = ctx.createBufferSource();
    source.buffer = buffer;
    source.connect(ctx.destination);

    final now = ctx.currentTime;
    var startAt = _scheduledEndTime;
    if (startAt < now + 0.02) {
      startAt = now + 0.02;
    }
    source.start(startAt);
    _scheduledEndTime = startAt + numSamples / _sampleRate;
  }

  @override
  Future<void> stop() async {
    _started = false;
    _scheduledEndTime = 0;
  }
}

Future<void> disposeSharedWebAudioContext() async {
  final ctx = _sharedWebAudioContext;
  _sharedWebAudioContext = null;
  _scheduledEndTime = 0;
  if (ctx != null) {
    try {
      await ctx.close().toDart;
    } catch (_) {}
  }
}
