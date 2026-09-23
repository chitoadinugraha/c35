import 'dart:async';
import 'dart:typed_data';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Filesystem ops over WebRTC data channel `remote-fs`.
/// Frames are protobuf-encoded `RemoteFs*` messages (request then response, serialized).
class RemoteFsApi {
  RemoteFsApi(this._channel) {
    _channel.onMessage = _onMessage;
  }

  final RTCDataChannel _channel;
  final _queue = <Completer<Uint8List>>[];

  void _onMessage(RTCDataChannelMessage msg) {
    final data = msg.binary;
    if (data.isEmpty) return;
    final pending = _queue.isNotEmpty ? _queue.removeAt(0) : null;
    if (pending == null || pending.isCompleted) {
      l('remote-fs: unexpected message (${data.length} bytes)');
      return;
    }
    pending.complete(data);
  }

  Future<Uint8List> _call(Uint8List req, {Duration timeout = const Duration(seconds: 30)}) async {
    if (_channel.state != RTCDataChannelState.RTCDataChannelOpen) throw 'remote-fs channel not open';
    final c = Completer<Uint8List>();
    _queue.add(c);
    _channel.send(RTCDataChannelMessage.fromBinary(req));
    return c.future.timeout(timeout, onTimeout: () {
      if (_queue.isNotEmpty && _queue.first == c) _queue.removeAt(0);
      throw TimeoutException('remote-fs request timed out');
    });
  }

  Future<RemoteFsListRes> fsList(String path) async {
    final res = await _call(RemoteFsListReq(path: path).writeToBuffer());
    return RemoteFsListRes.fromBuffer(res);
  }

  /// Read a chunk of a file. Default [len] is 256KB matching host native chunk size.
  Future<RemoteFsReadRes> fsRead(String path, {int offset = 0, int len = 262144}) async {
    final res = await _call(RemoteFsReadReq(path: path, offset: Int64(offset), length: len).writeToBuffer());
    return RemoteFsReadRes.fromBuffer(res);
  }

  /// Write a chunk to a file on the remote device.
  Future<RemoteFsWriteRes> fsWrite(
    String path,
    Uint8List data, {
    int offset = 0,
    bool finalize = false,
  }) async {
    final res = await _call(RemoteFsWriteReq(
      path: path,
      offset: Int64(offset),
      data: data,
      finalize: finalize,
    ).writeToBuffer());
    return RemoteFsWriteRes.fromBuffer(res);
  }

  /// Stream/download file chunks concurrently using a pipelined sliding window.
  /// [concurrency] specifies how many chunk requests are in-flight over WebRTC simultaneously.
  Stream<RemoteFsReadRes> streamFile(
    String path, {
    int chunkSize = 262144,
    int concurrency = 4,
    int startOffset = 0,
  }) async* {
    var nextReqOffset = startOffset;
    var isEof = false;
    final inFlight = <Future<RemoteFsReadRes>>[];

    void dispatchNext() {
      if (isEof) return;
      final offset = nextReqOffset;
      nextReqOffset += chunkSize;
      inFlight.add(fsRead(path, offset: offset, len: chunkSize));
    }

    for (var i = 0; i < concurrency; i++) {
      dispatchNext();
    }

    while (inFlight.isNotEmpty) {
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
