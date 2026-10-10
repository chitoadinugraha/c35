import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/remote/remote_fs_api.dart';
import 'package:alienai_c35/c/remote/remote_teach.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ulid/ulid.dart';

const _fsChannelLabel = 'remote-fs';
const _inputChannelLabel = 'remote-input';
const _screenChannelLabel = 'remote-screen';

class RemoteScreenFrame {
  const RemoteScreenFrame({
    required this.width,
    required this.height,
    required this.timestampMs,
    required this.jpegBytes,
  });

  final int width;
  final int height;
  final int timestampMs;
  final Uint8List jpegBytes;

  static final Map<int, _FrameReassembly> _pendingFrames = {};

  static RemoteScreenFrame? parse(Uint8List raw) {
    if (raw.length < 16) return null;
    final b0 = raw[0];
    final b1 = raw[1];
    final b2 = raw[2];
    final b3 = raw[3];

    // CS35: unfragmented single-packet frame
    if (b0 == 0x43 && b1 == 0x53 && b2 == 0x33 && b3 == 0x35) {
      final bd = ByteData.view(raw.buffer, raw.offsetInBytes, raw.lengthInBytes);
      final w = bd.getUint16(4, Endian.big);
      final h = bd.getUint16(6, Endian.big);
      final ts = bd.getUint64(8, Endian.big);
      final jpeg = Uint8List.sublistView(raw, 16);
      return RemoteScreenFrame(
        width: w,
        height: h,
        timestampMs: ts,
        jpegBytes: jpeg,
      );
    }

    // CS36: chunked frame
    if (b0 == 0x43 && b1 == 0x53 && b2 == 0x33 && b3 == 0x36 && raw.length >= 24) {
      final bd = ByteData.view(raw.buffer, raw.offsetInBytes, raw.lengthInBytes);
      final frameId = bd.getUint32(4, Endian.big);
      final chunkIdx = bd.getUint16(8, Endian.big);
      final totalChunks = bd.getUint16(10, Endian.big);
      final w = bd.getUint16(12, Endian.big);
      final h = bd.getUint16(14, Endian.big);
      final ts = bd.getUint64(16, Endian.big);
      final payload = Uint8List.sublistView(raw, 24);

      if (_pendingFrames.length > 10) {
        _pendingFrames.remove(_pendingFrames.keys.first);
      }

      final entry = _pendingFrames.putIfAbsent(
        frameId,
        () => _FrameReassembly(w: w, h: h, ts: ts, totalChunks: totalChunks),
      );
      entry.chunks[chunkIdx] = payload;

      if (entry.chunks.length == totalChunks) {
        _pendingFrames.remove(frameId);
        final totalLen = entry.chunks.values.fold<int>(0, (sum, c) => sum + c.length);
        final fullJpeg = Uint8List(totalLen);
        var offset = 0;
        for (var i = 0; i < totalChunks; i++) {
          final c = entry.chunks[i];
          if (c == null) return null;
          fullJpeg.setRange(offset, offset + c.length, c);
          offset += c.length;
        }
        return RemoteScreenFrame(
          width: entry.w,
          height: entry.h,
          timestampMs: entry.ts,
          jpegBytes: fullJpeg,
        );
      }
    }

    return null;
  }
}

class _FrameReassembly {
  _FrameReassembly({
    required this.w,
    required this.h,
    required this.ts,
    required this.totalChunks,
  });

  final int w;
  final int h;
  final int ts;
  final int totalChunks;
  final Map<int, Uint8List> chunks = {};
}

enum RemoteSessionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// One WebRTC session per remote device. Reused by Files + Remote tabs.
class RemoteSession {
  RemoteSession._(this.conn, this.deviceIid);

  final ChatConn conn;
  final int deviceIid;

  final connected = ValueNotifier<bool>(false);
  final status = ValueNotifier<RemoteSessionStatus>(RemoteSessionStatus.disconnected);
  late final Listenable presenceListenable = Listenable.merge([connected, status]);
  final mode = ValueNotifier<RemoteConnectionMode>(RemoteConnectionMode.REMOTE_CONNECTION_MODE_UNSPECIFIED);
  final screenFrame = ValueNotifier<RemoteScreenFrame?>(null);
  final isControlEnabled = ValueNotifier<bool>(true);
  final fps = ValueNotifier<int>(0);
  /// End-to-end frame age (MJPEG) or ICE RTT (H.264), milliseconds.
  final latencyMs = ValueNotifier<int?>(null);
  final bytesInPerSec = ValueNotifier<int>(0);
  final bytesOutPerSec = ValueNotifier<int>(0);
  /// MJPEG JPEG quality (40–95) sent to agent via `remote-screen`.
  final streamQuality = ValueNotifier<int>(80);
  final hasVideoTrack = ValueNotifier<bool>(false);
  final updateReady = ValueNotifier<bool>(false);
  final updateVersion = ValueNotifier<int?>(null);
  final remoteCursorShape = ValueNotifier<String>('arrow');

  final videoRenderer = RTCVideoRenderer();
  var _rendererInitialized = false;

  String? sessionId;
  RemoteFsApi? fs;
  RemoteTeachApi? teach;

  /// Teach HUD state (recording, steps, last label, duration).
  Listenable? get teachListenable => teach?.listenable;
  ValueNotifier<bool>? get teachRecording => teach?.recording;
  ValueNotifier<List<RemoteTeachStep>>? get teachSteps => teach?.steps;
  ValueNotifier<String>? get teachLastLabel => teach?.lastLabel;

  RTCPeerConnection? _pc;
  RTCDataChannel? _fsChannel;
  RTCDataChannel? _teachChannel;
  RTCDataChannel? _inputChannel;
  RTCDataChannel? _screenChannel;
  StreamSubscription<WsRes>? _signalSub;
  Timer? _fpsTimer;
  Timer? _reconnectTimer;
  Timer? _linkTimeout;
  Timer? _disconnectedGraceTimer;
  static Timer? _leaveDevicesTimer;
  var _frameCount = 0;
  var _lastDecodedFrames = 0;
  var _statsBytesIn = 0;
  var _statsBytesOut = 0;
  var _bandwidthPrimed = false;
  var _starting = false;
  var _retryCount = 0;
  var _manualStop = false;
  var _forceRelayIce = false;
  var _startSeq = 0;

  bool get stoppedByUser => _manualStop;

  bool get isLinking =>
      status.value == RemoteSessionStatus.connecting || status.value == RemoteSessionStatus.reconnecting;

  // -------------------------------------------------------------------------
  // Registry
  // -------------------------------------------------------------------------

  static final _sessions = <int, RemoteSession>{};

  static RemoteSession of(ChatConn conn, int deviceIid) =>
      _sessions.putIfAbsent(deviceIid, () => RemoteSession._(conn, deviceIid));

  static RemoteSession? get(int deviceIid) => _sessions[deviceIid];

  static Future<void> dispose(int deviceIid) async {
    final s = _sessions.remove(deviceIid);
    if (s != null) {
      await s.stop();
      if (s._rendererInitialized) {
        await s.videoRenderer.dispose();
        s._rendererInitialized = false;
      }
    }
  }

  Future<void> _ensureVideoRenderer() async {
    if (kIsWeb || _rendererInitialized) return;
    await videoRenderer.initialize();
    _rendererInitialized = true;
  }

  void _clearVideoRendererStream() {
    if (!_rendererInitialized) return;
    videoRenderer.srcObject = null;
  }

  /// Devices page opened — keep WebRTC alive while user is on the page.
  static void devicesPageVisible() {
    _leaveDevicesTimer?.cancel();
    _leaveDevicesTimer = null;
  }

  /// Devices page closed — tear down WebRTC after 1 minute off the page.
  static void devicesPageHidden() {
    _leaveDevicesTimer?.cancel();
    _leaveDevicesTimer = Timer(const Duration(minutes: 1), () {
      l('devices page left for 60s, stopping remote sessions');
      for (final iid in _sessions.keys.toList()) {
        unawaited(dispose(iid));
      }
    });
  }

  // -------------------------------------------------------------------------
  // Reconnect
  // -------------------------------------------------------------------------

  void userActivityPing() {}

  void _scheduleReconnect() {
    if (_manualStop) return;
    if (_retryCount >= 5) {
      status.value = RemoteSessionStatus.failed;
      return;
    }
    _retryCount++;
    status.value = RemoteSessionStatus.reconnecting;
    final delay = Duration(seconds: (1 << (_retryCount - 1)).clamp(1, 16));
    l('scheduling remote reconnect attempt $_retryCount in ${delay.inSeconds}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!conn.connected) {
        status.value = RemoteSessionStatus.disconnected;
        return;
      }
      if (!_manualStop && !connected.value) {
        _forceRelayIce = false;
        start();
      }
    });
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  void prepareUserReconnect() {
    _manualStop = false;
    _retryCount = 0;
    _forceRelayIce = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _linkTimeout?.cancel();
    _linkTimeout = null;
    _disconnectedGraceTimer?.cancel();
    _disconnectedGraceTimer = null;
  }

  bool _startAborted(int seq) => _manualStop || seq != _startSeq;

  bool get _peerLive => _pc != null && connected.value;

  void _armLinkTimeout() {
    _linkTimeout?.cancel();
    _linkTimeout = Timer(const Duration(seconds: 45), () {
      if (_manualStop || _peerLive) return;
      l('remote link timeout');
      status.value = RemoteSessionStatus.failed;
      unawaited(_teardownPc(keepSessionId: true));
    });
  }

  Future<void> start({bool forceRelay = false}) async {
    if (kIsWeb) throw UnsupportedError('WebRTC remote session is not supported on web');
    if (_manualStop) return;
    if (_starting) return;
    if (_peerLive) return;
    if (forceRelay) _forceRelayIce = true;
    if (!conn.connected) {
      l('remote session start skipped: server ws not connected');
      status.value = RemoteSessionStatus.disconnected;
      return;
    }
    _starting = true;
    final mySeq = _startSeq;
    status.value = RemoteSessionStatus.connecting;
    try {
      await _ensureVideoRenderer();
      if (_startAborted(mySeq)) return;
      await _teardownPc();
      if (_startAborted(mySeq)) return;
      sessionId = Ulid().toString();
      l('remote session start device=$deviceIid session=$sessionId');

      await _signalSub?.cancel();
      if (_startAborted(mySeq)) return;
      _signalSub = conn.onRemoteSignal.listen(_onSignal, onError: (e) => lError('remote signal: $e'));

      final iceRes = await conn.remoteIceConfig();
      if (_startAborted(mySeq)) return;
      final iceServers = iceRes.iceServers
          .map((s) => {
                'urls': s.urls.toList(),
                if (s.username.isNotEmpty) 'username': s.username,
                if (s.credential.isNotEmpty) 'credential': s.credential,
              })
          .toList();

      final startRes = await conn.remoteSessionStart(deviceIid, sessionId!);
      if (_startAborted(mySeq)) return;
      if (!startRes.ok) throw startRes.error.isNotEmpty ? startRes.error : 'session start failed';

      _armLinkTimeout();

      final pcConfig = <String, dynamic>{'iceServers': iceServers};
      if (_forceRelayIce) {
        pcConfig['iceTransportPolicy'] = 'relay';
        l('remote session using TURN relay (iceTransportPolicy=relay)');
      }
      _pc = await createPeerConnection(pcConfig);
      if (_startAborted(mySeq)) return;
      _pc!.onIceCandidate = (c) => unawaited(_sendIce(c));
      _pc!.onTrack = (event) async {
        if (_manualStop) return;
        l('remote onTrack: ${event.track.kind} streams=${event.streams.length}');
        if (event.track.kind == 'video') {
          try {
            await _ensureVideoRenderer();
            if (_manualStop || _pc == null) return;
            if (event.streams.isNotEmpty) {
              videoRenderer.srcObject = event.streams[0];
            } else {
              final stream = await createLocalMediaStream('remote_video_stream');
              stream.addTrack(event.track);
              videoRenderer.srcObject = stream;
            }
            hasVideoTrack.value = true;
            screenFrame.value = null;
          } catch (e) {
            lError('remote onTrack video attach failed: $e');
          }
        }
      };
      _pc!.onConnectionState = (s) {
        final up = s == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        final wasConnected = connected.value;
        if (connected.value != up) {
          connected.value = up;
          l('remote pc state=$s connected=$up');
        }
        if (up) {
          _disconnectedGraceTimer?.cancel();
          _disconnectedGraceTimer = null;
          _linkTimeout?.cancel();
          _linkTimeout = null;
          _retryCount = 0;
          status.value = RemoteSessionStatus.connected;
          isControlEnabled.value = true;
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _disconnectedGraceTimer?.cancel();
          _disconnectedGraceTimer = null;
          _linkTimeout?.cancel();
          _linkTimeout = null;
          if (_manualStop) return;
          if (!wasConnected && !_forceRelayIce) {
            _forceRelayIce = true;
            l('remote peer failed on direct ICE; retrying via TURN relay');
            unawaited(() async {
              await _teardownPc(keepSessionId: true);
              if (!_manualStop && !connected.value) await start(forceRelay: true);
            }());
            return;
          }
          unawaited(_teardownPc(keepSessionId: true));
          if (wasConnected) _scheduleReconnect();
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _disconnectedGraceTimer?.cancel();
          _disconnectedGraceTimer = null;
          final wasConnected = connected.value;
          if (_manualStop || !wasConnected) return;
          unawaited(_teardownPc(keepSessionId: true));
          _scheduleReconnect();
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          final wasConnected = connected.value;
          if (_manualStop || !wasConnected) return;
          l('remote peer connection disconnected; waiting grace period for recovery');
          _disconnectedGraceTimer?.cancel();
          _disconnectedGraceTimer = Timer(const Duration(seconds: 4), () {
            _disconnectedGraceTimer = null;
            if (_manualStop || !connected.value) return;
            l('remote peer connection disconnected grace period expired; reconnecting');
            unawaited(_teardownPc(keepSessionId: true));
            _scheduleReconnect();
          });
        }
      };
      _pc!.onDataChannel = (ch) {
        if (ch.label == _fsChannelLabel) _bindFsChannel(ch);
        if (ch.label == remoteTeachChannelLabel) _bindTeachChannel(ch);
        if (ch.label == _inputChannelLabel) _bindInputChannel(ch);
        if (ch.label == _screenChannelLabel) _bindScreenChannel(ch);
      };

      _fsChannel = await _pc!.createDataChannel(_fsChannelLabel, RTCDataChannelInit());
      _bindFsChannel(_fsChannel!);

      _teachChannel = await _pc!.createDataChannel(remoteTeachChannelLabel, RTCDataChannelInit()..ordered = true);
      _bindTeachChannel(_teachChannel!);

      _inputChannel = await _pc!.createDataChannel(_inputChannelLabel, RTCDataChannelInit()..ordered = true);
      _bindInputChannel(_inputChannel!);
      _screenChannel = await _pc!.createDataChannel(_screenChannelLabel, RTCDataChannelInit()..ordered = true);
      if (_startAborted(mySeq)) return;
      _bindScreenChannel(_screenChannel!);

      _startFpsTimer();

      final offer = await _pc!.createOffer({'offerToReceiveVideo': true, 'offerToReceiveAudio': true});
      if (_startAborted(mySeq)) return;
      await _pc!.setLocalDescription(offer);
      if (_startAborted(mySeq)) return;
      await conn.rtcSignalOffer(RtcSignalOffer(deviceIid: Int64(deviceIid), sessionId: sessionId!, sdp: offer.sdp ?? ''));
      if (_startAborted(mySeq)) return;
      l('remote offer sent (video+audio enabled)');
    } catch (e) {
      if (_startAborted(mySeq)) return;
      lError('remote session start: $e');
      status.value = RemoteSessionStatus.failed;
      await _teardownPc();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  /// [userInitiated] false when reconnecting (Connect / Retry) — does not latch [stoppedByUser].
  Future<void> stop({bool userInitiated = true}) async {
    if (userInitiated) _manualStop = true;
    _startSeq++;
    _starting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _linkTimeout?.cancel();
    _linkTimeout = null;
    _disconnectedGraceTimer?.cancel();
    _disconnectedGraceTimer = null;
    status.value = RemoteSessionStatus.disconnected;
    final sid = sessionId;
    await _teardownPc();
    if (sid != null) {
      try {
        await conn.remoteSessionStop(deviceIid, sid);
      } catch (e) {
        lError('remote session stop: $e');
      }
    }
  }

  Future<void> _teardownPc({bool keepSessionId = false}) async {
    _linkTimeout?.cancel();
    _linkTimeout = null;
    _disconnectedGraceTimer?.cancel();
    _disconnectedGraceTimer = null;
    _fpsTimer?.cancel();
    _fpsTimer = null;
    _frameCount = 0;
    _lastDecodedFrames = 0;
    fps.value = 0;
    latencyMs.value = null;
    bytesInPerSec.value = 0;
    bytesOutPerSec.value = 0;
    _statsBytesIn = 0;
    _statsBytesOut = 0;
    _bandwidthPrimed = false;
    screenFrame.value = null;
    remoteCursorShape.value = 'arrow';
    hasVideoTrack.value = false;
    _clearVideoRendererStream();
    isControlEnabled.value = false;
    connected.value = false;
    updateReady.value = false;
    updateVersion.value = null;
    fs?.dispose();
    fs = null;
    teach?.dispose();
    teach = null;
    _fsChannel = null;
    _teachChannel = null;
    _inputChannel = null;
    _screenChannel = null;
    await _signalSub?.cancel();
    _signalSub = null;
    final pc = _pc;
    _pc = null;
    if (pc != null) {
      try {
        await pc.close();
      } catch (e) {
        lError('remote pc close: $e');
      }
    }
    if (!keepSessionId) sessionId = null;
    mode.value = RemoteConnectionMode.REMOTE_CONNECTION_MODE_UNSPECIFIED;
  }

  void _bindFsChannel(RTCDataChannel ch) {
    _fsChannel = ch;
    ch.onDataChannelState = (s) {
      l('remote-fs channel state=$s');
      if (s == RTCDataChannelState.RTCDataChannelOpen) fs = RemoteFsApi(ch);
    };
  }

  void _bindTeachChannel(RTCDataChannel ch) {
    _teachChannel = ch;
    ch.onDataChannelState = (s) {
      l('remote-teach channel state=$s');
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        teach = RemoteTeachApi(ch, deviceIid);
      }
    };
  }

  void _requireTeachReady() {
    if (!connected.value) throw StateError('WebRTC not connected');
    if (teach == null) throw StateError('remote-teach channel not open');
  }

  Future<void> remoteTeachStart(String title) async {
    _requireTeachReady();
    final res = await teach!.teachStart(title);
    if (!res.ok) throw StateError(res.error.isNotEmpty ? res.error : 'teach start failed');
  }

  Future<List<RemoteTeachStep>> remoteTeachStop() async {
    _requireTeachReady();
    final res = await teach!.teachStop();
    if (res.error.isNotEmpty) throw StateError(res.error);
    return List<RemoteTeachStep>.from(res.steps);
  }

  Future<RemoteTeachStatusRes> remoteTeachStatus() async {
    _requireTeachReady();
    return teach!.teachStatus();
  }

  void _bindInputChannel(RTCDataChannel ch) {
    _inputChannel = ch;
    ch.onDataChannelState = (s) {
      l('remote-input channel state=$s');
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        isControlEnabled.value = true;
      }
    };
    ch.onMessage = (msg) {
      if (!msg.isBinary) return;
      try {
        final cursor = RemoteCursorEvent.fromBuffer(msg.binary);
        if (cursor.shape.isNotEmpty) {
          remoteCursorShape.value = cursor.shape;
        }
      } catch (_) {}
    };
  }

  void _bindScreenChannel(RTCDataChannel ch) {
    _screenChannel = ch;
    ch.onDataChannelState = (s) {
      if (s == RTCDataChannelState.RTCDataChannelOpen) {
        sendStreamQuality(streamQuality.value);
      }
    };
    ch.onMessage = (msg) {
      if (_manualStop || !msg.isBinary) return;
      if (hasVideoTrack.value) return;
      final frame = RemoteScreenFrame.parse(msg.binary);
      if (frame != null) {
        screenFrame.value = frame;
        _frameCount++;
        _noteFrameLatency(frame);
      }
    };
  }

  void _startFpsTimer() {
    _fpsTimer?.cancel();
    _frameCount = 0;
    _lastDecodedFrames = 0;
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final pc = _pc;
      if (pc != null) {
        try {
          final stats = await pc.getStats();
          _pollRtcLatency(stats);
          _pollBandwidth(stats);
          if (hasVideoTrack.value) {
            for (final r in stats) {
              if (r.type == 'inbound-rtp' && r.values['kind'] == 'video') {
                final frames = int.tryParse(r.values['framesDecoded']?.toString() ?? '') ?? 0;
                if (_lastDecodedFrames > 0 && frames >= _lastDecodedFrames) {
                  fps.value = frames - _lastDecodedFrames;
                }
                _lastDecodedFrames = frames;
                return;
              }
            }
          }
        } catch (_) {}
      }
      fps.value = _frameCount;
      _frameCount = 0;
    });
  }

  void _noteFrameLatency(RemoteScreenFrame frame) {
    final lat = DateTime.now().millisecondsSinceEpoch - frame.timestampMs;
    if (lat >= 0 && lat < 60000) latencyMs.value = lat;
  }

  void _pollRtcLatency(List<StatsReport> stats) {
    for (final r in stats) {
      if (r.type != 'candidate-pair' && r.type != 'googCandidatePair') continue;
      final selected = r.values['selected'];
      if (selected != true && selected != 'true') continue;
      final rtt = r.values['currentRoundTripTime'] ?? r.values['roundTripTime'];
      if (rtt == null) continue;
      final sec = rtt is num ? rtt.toDouble() : double.tryParse(rtt.toString());
      if (sec == null || sec <= 0) continue;
      latencyMs.value = (sec * 1000).round();
      return;
    }
  }

  void _pollBandwidth(List<StatsReport> stats) {
    var inTot = 0;
    var outTot = 0;
    for (final r in stats) {
      switch (r.type) {
        case 'inbound-rtp':
        case 'remote-inbound-rtp':
          inTot += _statBytes(r.values['bytesReceived']);
        case 'outbound-rtp':
          outTot += _statBytes(r.values['bytesSent']);
        case 'data-channel':
          inTot += _statBytes(r.values['bytesReceived']);
          outTot += _statBytes(r.values['bytesSent']);
      }
    }
    if (_bandwidthPrimed) {
      bytesInPerSec.value = (inTot - _statsBytesIn).clamp(0, 1 << 30);
      bytesOutPerSec.value = (outTot - _statsBytesOut).clamp(0, 1 << 30);
    } else {
      _bandwidthPrimed = true;
    }
    _statsBytesIn = inTot;
    _statsBytesOut = outTot;
  }

  int _statBytes(Object? v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  void sendInput(RemoteInputEvent evt) {
    if (!isControlEnabled.value) return;
    final ch = _inputChannel;
    if (ch != null && ch.state == RTCDataChannelState.RTCDataChannelOpen) {
      ch.send(RTCDataChannelMessage.fromBinary(evt.writeToBuffer()));
    }
  }

  void sendStreamQuality(int quality) {
    final q = quality.clamp(40, 95);
    streamQuality.value = q;
    final ch = _screenChannel;
    if (ch != null && ch.state == RTCDataChannelState.RTCDataChannelOpen) {
      ch.send(RTCDataChannelMessage.fromBinary(
        RemoteScreenControl(quality: q).writeToBuffer(),
      ));
    }
  }

  void triggerUpdate() {
    final ch = _inputChannel;
    if (ch != null && ch.state == RTCDataChannelState.RTCDataChannelOpen) {
      final evt = RemoteInputEvent(eventType: 'apply_update');
      ch.send(RTCDataChannelMessage.fromBinary(evt.writeToBuffer()));
      l('triggerUpdate sent to remote agent on remote-input data channel');
    }
  }

  Future<void> sendBrowserMode(String mode) async {
    final m = mode == 'background' ? 'background' : 'interactive';
    final res = await conn.remoteAgentPush(deviceIid, 'c35.browser.mode:$m');
    if (!res.ok) throw res.error;
  }

  Future<Map<String, dynamic>> browserInvoke(String method, Map<String, dynamic> params) async {
    final res = await conn.remoteBrowserInvoke(
      deviceIid: deviceIid,
      method: method,
      paramsJson: jsonEncode(params),
    );
    if (!res.ok) throw res.error;
    if (res.resultJson.isEmpty) return {};
    final decoded = jsonDecode(res.resultJson);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'result': decoded};
  }

  // -------------------------------------------------------------------------
  // Signaling
  // -------------------------------------------------------------------------

  void _onSignal(WsRes res) {
    if (res.hasRemoteSessionPush()) {
      final push = res.remoteSessionPush;
      if (push.deviceIid.toInt() != deviceIid) return;
      if (sessionId != null && push.sessionId != sessionId) return;
      if (push.hasMode()) mode.value = push.mode;
      // Link state comes from local RTCPeerConnection only — agent push is for mode/OTA.
      if (push.hasUpdateReady()) {
        updateReady.value = push.updateReady;
        if (push.hasUpdateVersion()) {
          updateVersion.value = push.updateVersion.toInt();
        }
      }
      return;
    }
    if (res.hasRtcSignalAnswer()) {
      final ans = res.rtcSignalAnswer;
      if (ans.deviceIid.toInt() != deviceIid || ans.sessionId != sessionId) return;
      unawaited(_applyAnswer(ans.sdp));
      return;
    }
    if (res.hasRtcSignalIce()) {
      final ice = res.rtcSignalIce;
      if (ice.deviceIid.toInt() != deviceIid || ice.sessionId != sessionId) return;
      unawaited(_addIce(ice));
    }
  }

  Future<void> _applyAnswer(String sdp) async {
    final pc = _pc;
    if (pc == null || sdp.isEmpty) return;
    try {
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      l('remote answer applied');
    } catch (e) {
      lError('remote setRemoteDescription: $e');
    }
  }

  Future<void> _sendIce(RTCIceCandidate? c) async {
    if (c == null || sessionId == null) return;
    final candidate = c.candidate ?? '';
    if (candidate.isEmpty) return;
    try {
      await conn.rtcSignalIce(RtcSignalIce(
        deviceIid: Int64(deviceIid),
        sessionId: sessionId!,
        candidate: candidate,
        sdpMid: c.sdpMid ?? '',
        sdpMlineIndex: c.sdpMLineIndex ?? 0,
      ));
    } catch (e) {
      lError('remote send ice: $e');
    }
  }

  Future<void> _addIce(RtcSignalIce ice) async {
    final pc = _pc;
    if (pc == null) return;
    try {
      await pc.addCandidate(RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMlineIndex));
    } catch (e) {
      lError('remote addCandidate: $e');
    }
  }
}
