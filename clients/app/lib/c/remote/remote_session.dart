import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/remote/remote_fs_api.dart';
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

  static RemoteScreenFrame? parse(Uint8List raw) {
    if (raw.length < 16) return null;
    if (raw[0] != 0x43 || raw[1] != 0x53 || raw[2] != 0x33 || raw[3] != 0x35) return null; // "CS35"
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
  final mode = ValueNotifier<RemoteConnectionMode>(RemoteConnectionMode.REMOTE_CONNECTION_MODE_UNSPECIFIED);
  final screenFrame = ValueNotifier<RemoteScreenFrame?>(null);
  final isControlEnabled = ValueNotifier<bool>(false);
  final fps = ValueNotifier<int>(0);
  final hasVideoTrack = ValueNotifier<bool>(false);
  final updateReady = ValueNotifier<bool>(false);
  final updateVersion = ValueNotifier<int?>(null);

  final videoRenderer = RTCVideoRenderer();
  var _rendererInitialized = false;

  String? sessionId;
  RemoteFsApi? fs;

  RTCPeerConnection? _pc;
  RTCDataChannel? _fsChannel;
  RTCDataChannel? _inputChannel;
  RTCDataChannel? _screenChannel;
  StreamSubscription<WsRes>? _signalSub;
  Timer? _fpsTimer;
  Timer? _reconnectTimer;
  static Timer? _leaveDevicesTimer;
  var _frameCount = 0;
  var _lastDecodedFrames = 0;
  var _starting = false;
  var _retryCount = 0;
  var _manualStop = false;

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
      }
    }
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
        start();
      }
    });
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  Future<void> start() async {
    if (kIsWeb) throw UnsupportedError('WebRTC remote session is not supported on web');
    if (_starting) return;
    if (connected.value) return;
    if (!conn.connected) {
      l('remote session start skipped: server ws not connected');
      status.value = RemoteSessionStatus.disconnected;
      return;
    }
    _manualStop = false;
    _starting = true;
    status.value = RemoteSessionStatus.connecting;
    try {
      if (!_rendererInitialized && !kIsWeb) {
        await videoRenderer.initialize();
        _rendererInitialized = true;
      }
      await _teardownPc();
      sessionId = Ulid().toString();
      l('remote session start device=$deviceIid session=$sessionId');

      final iceRes = await conn.remoteIceConfig();
      final iceServers = iceRes.iceServers
          .map((s) => {
                'urls': s.urls.toList(),
                if (s.username.isNotEmpty) 'username': s.username,
                if (s.credential.isNotEmpty) 'credential': s.credential,
              })
          .toList();

      final startRes = await conn.remoteSessionStart(deviceIid, sessionId!);
      if (!startRes.ok) throw startRes.error.isNotEmpty ? startRes.error : 'session start failed';

      _signalSub = conn.onRemoteSignal.listen(_onSignal, onError: (e) => lError('remote signal: $e'));

      _pc = await createPeerConnection({'iceServers': iceServers});
      _pc!.onIceCandidate = (c) => unawaited(_sendIce(c));
      _pc!.onTrack = (event) async {
        l('remote onTrack: ${event.track.kind} streams=${event.streams.length}');
        if (event.track.kind == 'video') {
          if (event.streams.isNotEmpty) {
            videoRenderer.srcObject = event.streams[0];
          } else {
            final stream = await createLocalMediaStream('remote_video_stream');
            stream.addTrack(event.track);
            videoRenderer.srcObject = stream;
          }
          hasVideoTrack.value = true;
        }
      };
      _pc!.onConnectionState = (s) {
        final up = s == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
        if (connected.value != up) {
          connected.value = up;
          l('remote pc state=$s connected=$up');
        }
        if (up) {
          _retryCount = 0;
          status.value = RemoteSessionStatus.connected;
        } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          final wasConnected = connected.value;
          unawaited(_teardownPc(keepSessionId: true));
          if (wasConnected && !_manualStop) {
            _scheduleReconnect();
          }
        }
      };
      _pc!.onDataChannel = (ch) {
        if (ch.label == _fsChannelLabel) _bindFsChannel(ch);
        if (ch.label == _inputChannelLabel) _inputChannel = ch;
        if (ch.label == _screenChannelLabel) _bindScreenChannel(ch);
      };

      _fsChannel = await _pc!.createDataChannel(_fsChannelLabel, RTCDataChannelInit());
      _bindFsChannel(_fsChannel!);

      _inputChannel = await _pc!.createDataChannel(_inputChannelLabel, RTCDataChannelInit()..ordered = true);
      _screenChannel = await _pc!.createDataChannel(_screenChannelLabel, RTCDataChannelInit()..ordered = true);
      _bindScreenChannel(_screenChannel!);

      _startFpsTimer();

      final offer = await _pc!.createOffer({'offerToReceiveVideo': true, 'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(offer);
      await conn.rtcSignalOffer(RtcSignalOffer(deviceIid: Int64(deviceIid), sessionId: sessionId!, sdp: offer.sdp ?? ''));
      l('remote offer sent (video+audio enabled)');
    } catch (e) {
      lError('remote session start: $e');
      status.value = RemoteSessionStatus.failed;
      await _teardownPc();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _manualStop = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    status.value = RemoteSessionStatus.disconnected;
    final sid = sessionId;
    if (sid != null) {
      try {
        await conn.remoteSessionStop(deviceIid, sid);
      } catch (e) {
        lError('remote session stop: $e');
      }
    }
    await _teardownPc();
    sessionId = null;
  }

  Future<void> _teardownPc({bool keepSessionId = false}) async {
    _fpsTimer?.cancel();
    _fpsTimer = null;
    _frameCount = 0;
    _lastDecodedFrames = 0;
    fps.value = 0;
    screenFrame.value = null;
    hasVideoTrack.value = false;
    videoRenderer.srcObject = null;
    isControlEnabled.value = false;
    connected.value = false;
    updateReady.value = false;
    updateVersion.value = null;
    fs?.dispose();
    fs = null;
    _fsChannel = null;
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

  void _bindScreenChannel(RTCDataChannel ch) {
    _screenChannel = ch;
    ch.onMessage = (msg) {
      if (!msg.isBinary) return;
      final frame = RemoteScreenFrame.parse(msg.binary);
      if (frame != null) {
        screenFrame.value = frame;
        _frameCount++;
      }
    };
  }

  void _startFpsTimer() {
    _fpsTimer?.cancel();
    _frameCount = 0;
    _lastDecodedFrames = 0;
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (hasVideoTrack.value && _pc != null) {
        try {
          final stats = await _pc!.getStats();
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
        } catch (_) {}
      }
      fps.value = _frameCount;
      _frameCount = 0;
    });
  }

  void sendInput(RemoteInputEvent evt) {
    if (!isControlEnabled.value) return;
    final ch = _inputChannel;
    if (ch != null && ch.state == RTCDataChannelState.RTCDataChannelOpen) {
      ch.send(RTCDataChannelMessage.fromBinary(evt.writeToBuffer()));
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

  // -------------------------------------------------------------------------
  // Signaling
  // -------------------------------------------------------------------------

  void _onSignal(WsRes res) {
    if (res.hasRemoteSessionPush()) {
      final push = res.remoteSessionPush;
      if (push.deviceIid.toInt() != deviceIid) return;
      if (sessionId != null && push.sessionId != sessionId) return;
      if (push.hasMode()) mode.value = push.mode;
      if (push.hasWebrtcConnected()) connected.value = push.webrtcConnected;
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
