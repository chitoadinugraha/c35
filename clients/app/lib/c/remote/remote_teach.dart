import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

const remoteTeachChannelLabel = 'remote-teach';

/// Skill teach recorder over WebRTC data channel [remoteTeachChannelLabel].
class RemoteTeachApi {
  RemoteTeachApi(RTCDataChannel channel, this.deviceIid) : _channel = channel {
    channel.onMessage = _onMessage;
  }

  @visibleForTesting
  RemoteTeachApi.inMemory(this.deviceIid) : _channel = null;

  final RTCDataChannel? _channel;
  final int deviceIid;

  final recording = ValueNotifier<bool>(false);
  final steps = ValueNotifier<List<RemoteTeachStep>>(<RemoteTeachStep>[]);
  final lastLabel = ValueNotifier<String>('');
  final durationSec = ValueNotifier<int>(0);
  final title = ValueNotifier<String>('');

  Listenable get listenable => Listenable.merge([recording, steps, lastLabel, durationSec, title]);

  final _responseQueue = <Completer<Uint8List>>[];
  Timer? _pollTimer;
  var _disposed = false;

  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    _channel?.onMessage = null;
  }

  Future<RemoteTeachStartRes> teachStart(String teachTitle) async {
    _ensureOpen();
    final trimmed = teachTitle.trim();
    final res = await _call(
      RemoteTeachStartReq(title: trimmed, deviceIid: Int64(deviceIid)).writeToBuffer(),
    );
    final parsed = RemoteTeachStartRes.fromBuffer(res);
    if (parsed.ok) {
      title.value = trimmed;
      recording.value = true;
      steps.value = [];
      lastLabel.value = '';
      durationSec.value = 0;
      _armPoll();
      unawaited(refreshFromStatus());
    }
    return parsed;
  }

  Future<RemoteTeachStopRes> teachStop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _ensureOpen();
    final res = await _call(RemoteTeachStopReq(stop: true).writeToBuffer());
    final parsed = RemoteTeachStopRes.fromBuffer(res);
    recording.value = false;
    steps.value = List<RemoteTeachStep>.from(parsed.steps);
    return parsed;
  }

  Future<RemoteTeachStatusRes> teachStatus() async {
    _ensureOpen();
    final res = await _call(RemoteTeachStatusReq(poll: true).writeToBuffer(), timeout: const Duration(seconds: 8));
    return RemoteTeachStatusRes.fromBuffer(res);
  }

  Future<void> refreshFromStatus() async {
    if (_disposed || !recording.value) return;
    try {
      final parsed = await teachStatus();
      if (parsed.error.isNotEmpty) {
        lError('remote-teach status: ${parsed.error}');
        return;
      }
      recording.value = parsed.recording;
      steps.value = List<RemoteTeachStep>.from(parsed.steps);
      lastLabel.value = parsed.lastLabel;
      durationSec.value = parsed.durationSec.toInt();
    } catch (e) {
      lError('remote-teach poll: $e');
    }
  }

  void _armPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(refreshFromStatus()));
  }

  void _onMessage(RTCDataChannelMessage msg) {
    final data = msg.binary;
    if (data.isEmpty) return;
    final pending = _responseQueue.isNotEmpty ? _responseQueue.removeAt(0) : null;
    if (pending == null || pending.isCompleted) {
      l('remote-teach: unexpected message (${data.length} bytes)');
      return;
    }
    pending.complete(data);
  }

  void _ensureOpen() {
    if (_channel == null) throw StateError('remote-teach channel not attached');
    if (_channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('remote-teach channel not open');
    }
  }

  Future<Uint8List> _call(Uint8List req, {Duration timeout = const Duration(seconds: 30)}) async {
    final ch = _channel;
    if (ch == null) throw StateError('remote-teach channel not attached');
    final c = Completer<Uint8List>();
    _responseQueue.add(c);
    ch.send(RTCDataChannelMessage.fromBinary(req));
    return c.future.timeout(timeout, onTimeout: () {
      if (_responseQueue.isNotEmpty && _responseQueue.first == c) _responseQueue.removeAt(0);
      throw TimeoutException('remote-teach request timed out');
    });
  }
}
