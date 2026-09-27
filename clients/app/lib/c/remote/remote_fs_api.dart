import 'dart:async';
import 'dart:typed_data';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Client-side priority for the single `remote-fs` SCTP channel.
enum RemoteFsPriority { high, low }

class _PendingFsCall {
  _PendingFsCall({
    required this.req,
    required this.priority,
    required this.completer,
    required this.timeout,
  });

  final Uint8List req;
  final RemoteFsPriority priority;
  final Completer<Uint8List> completer;
  final Duration timeout;
  Timer? timeoutTimer;
}

/// Filesystem ops over WebRTC data channel `remote-fs`.
/// Frames are protobuf-encoded `RemoteFs*` messages (request then response, serialized).
class RemoteFsApi {
  RemoteFsApi(this._channel) {
    _channel.onMessage = _onMessage;
  }

  final RTCDataChannel _channel;
  final _responseQueue = <Completer<Uint8List>>[];
  final _pending = <_PendingFsCall>[];
  var _draining = false;
  var _inFlight = false;

  /// Cap upload/download throughput for [RemoteFsPriority.low] ops (0 = no cap).
  int lowPriorityBytesPerSec = 512 * 1024;

  var _lowBytesAcc = 0;
  DateTime? _lowThrottleStart;

  bool get hasHighPriorityPending =>
      _pending.any((p) => p.priority == RemoteFsPriority.high) || (_inFlight && _inFlightIsHigh);

  var _inFlightIsHigh = false;

  /// Transfer pump waits here while list/preview ops are queued or in flight.
  Future<void> waitForLowPrioritySlot() async {
    while (hasHighPriorityPending) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> throttleLowPriority(int bytes) async {
    final cap = lowPriorityBytesPerSec;
    if (cap <= 0 || bytes <= 0) return;
    _lowBytesAcc += bytes;
    final window = Duration(milliseconds: ((_lowBytesAcc * 1000) / cap).ceil());
    _lowThrottleStart ??= DateTime.now();
    final elapsed = DateTime.now().difference(_lowThrottleStart!);
    if (elapsed < window) {
      await Future<void>.delayed(window - elapsed);
    }
    _lowBytesAcc = 0;
    _lowThrottleStart = DateTime.now();
  }

  void _onMessage(RTCDataChannelMessage msg) {
    final data = msg.binary;
    if (data.isEmpty) return;
    final pending = _responseQueue.isNotEmpty ? _responseQueue.removeAt(0) : null;
    if (pending == null || pending.isCompleted) {
      l('remote-fs: unexpected message (${data.length} bytes)');
      return;
    }
    pending.complete(data);
  }

  void _scheduleDrain() {
    if (_draining) return;
    _draining = true;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    try {
      while (true) {
        final idx = _pending.indexWhere((p) => p.priority == RemoteFsPriority.high);
        final pick = idx >= 0 ? idx : (_pending.isEmpty ? -1 : 0);
        if (pick < 0) break;
        final call = _pending.removeAt(pick);
        if (_channel.state != RTCDataChannelState.RTCDataChannelOpen) {
          if (!call.completer.isCompleted) {
            call.completer.completeError('remote-fs channel not open');
          }
          continue;
        }
        _inFlight = true;
        _inFlightIsHigh = call.priority == RemoteFsPriority.high;
        final c = Completer<Uint8List>();
        _responseQueue.add(c);
        call.timeoutTimer = Timer(call.timeout, () {
          if (_responseQueue.isNotEmpty && _responseQueue.first == c) {
            _responseQueue.removeAt(0);
          }
          if (!c.isCompleted) c.completeError(TimeoutException('remote-fs request timed out'));
          if (!call.completer.isCompleted) {
            call.completer.completeError(TimeoutException('remote-fs request timed out'));
          }
        });
        _channel.send(RTCDataChannelMessage.fromBinary(call.req));
        try {
          final res = await c.future;
          call.timeoutTimer?.cancel();
          if (!call.completer.isCompleted) call.completer.complete(res);
        } catch (e, st) {
          call.timeoutTimer?.cancel();
          if (!call.completer.isCompleted) call.completer.completeError(e, st);
        } finally {
          _inFlight = false;
          _inFlightIsHigh = false;
        }
      }
    } finally {
      _draining = false;
      if (_pending.isNotEmpty) _scheduleDrain();
    }
  }

  Future<Uint8List> _call(
    Uint8List req, {
    Duration timeout = const Duration(seconds: 30),
    RemoteFsPriority priority = RemoteFsPriority.high,
  }) async {
    final c = Completer<Uint8List>();
    _pending.add(_PendingFsCall(req: req, priority: priority, completer: c, timeout: timeout));
    _scheduleDrain();
    return c.future;
  }

  Future<RemoteFsListRes> fsList(String path, {RemoteFsPriority priority = RemoteFsPriority.high}) async {
    final res = await _call(RemoteFsListReq(path: path).writeToBuffer(), priority: priority);
    return RemoteFsListRes.fromBuffer(res);
  }

  Future<RemoteFsReadRes> fsRead(
    String path, {
    int offset = 0,
    int len = 262144,
    RemoteFsPriority priority = RemoteFsPriority.high,
  }) async {
    final res = await _call(
      RemoteFsReadReq(path: path, offset: Int64(offset), length: len).writeToBuffer(),
      priority: priority,
    );
    return RemoteFsReadRes.fromBuffer(res);
  }

  Future<RemoteFsWriteRes> fsWrite(
    String path,
    Uint8List data, {
    int offset = 0,
    bool finalize = false,
    RemoteFsPriority priority = RemoteFsPriority.low,
  }) async {
    final res = await _call(
      RemoteFsWriteReq(
        path: path,
        offset: Int64(offset),
        data: data,
        finalize: finalize,
      ).writeToBuffer(),
      priority: priority,
    );
    return RemoteFsWriteRes.fromBuffer(res);
  }

  Future<RemoteFsMkdirRes> fsMkdir(String path) async {
    final res = await _call(RemoteFsMkdirReq(path: path).writeToBuffer());
    return RemoteFsMkdirRes.fromBuffer(res);
  }

  Future<RemoteFsDeleteRes> fsDelete(String path) async {
    final res = await _call(RemoteFsDeleteReq(path: path).writeToBuffer());
    return RemoteFsDeleteRes.fromBuffer(res);
  }

  Future<RemoteFsRenameRes> fsRename(String fromPath, String toPath) async {
    final res = await _call(RemoteFsRenameReq(fromPath: fromPath, toPath: toPath).writeToBuffer());
    return RemoteFsRenameRes.fromBuffer(res);
  }

  Future<RemoteMediaOpenRes> mediaOpen(String path) async {
    final res = await _call(
      RemoteMediaOpenReq(path: path).writeToBuffer(),
      timeout: const Duration(seconds: 60),
    );
    return RemoteMediaOpenRes.fromBuffer(res);
  }

  Future<RemoteMediaCloseRes> mediaClose() async {
    final res = await _call(RemoteMediaCloseReq(close: true).writeToBuffer());
    return RemoteMediaCloseRes.fromBuffer(res);
  }

  Future<RemoteMediaStatusRes> mediaStatus() async {
    final res = await _call(RemoteMediaStatusReq(query: true).writeToBuffer());
    return RemoteMediaStatusRes.fromBuffer(res);
  }

  /// Stream/download file chunks (low priority, throttled).
  Stream<RemoteFsReadRes> streamFile(
    String path, {
    int chunkSize = 262144,
    int concurrency = 2,
    int startOffset = 0,
  }) async* {
    var nextReqOffset = startOffset;
    var isEof = false;
    final inFlight = <Future<RemoteFsReadRes>>[];

    void dispatchNext() {
      if (isEof || hasHighPriorityPending) return;
      final offset = nextReqOffset;
      nextReqOffset += chunkSize;
      inFlight.add(() async {
        await waitForLowPrioritySlot();
        final res = await fsRead(path, offset: offset, len: chunkSize, priority: RemoteFsPriority.low);
        await throttleLowPriority(res.data.length);
        return res;
      }());
    }

    for (var i = 0; i < concurrency; i++) {
      dispatchNext();
    }

    while (inFlight.isNotEmpty) {
      if (hasHighPriorityPending) {
        await waitForLowPrioritySlot();
        while (inFlight.length < concurrency && !isEof) {
          dispatchNext();
        }
        continue;
      }
      final res = await inFlight.removeAt(0);
      if (res.error.isNotEmpty) throw res.error;
      yield res;
      if (res.eof || res.data.isEmpty) {
        isEof = true;
      } else if (!isEof) {
        dispatchNext();
      }
    }
  }

  void dispose() => _channel.onMessage = null;
}
