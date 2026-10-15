import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:alienai_c35/c/audio/mic_stream_candidates.dart' show liveCallMicStreamCandidates;
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/live/live_pcm_jitter_buffer.dart';
import 'package:alienai_c35/c/live/live_pcm_playout.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide AndroidAudioMode;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveUsage {
  const LiveUsage({required this.promptTokens, required this.responseTokens, required this.totalTokens});
  final int promptTokens;
  final int responseTokens;
  final int totalTokens;
}

class LiveCaption {
  const LiveCaption({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class LiveCallSession {
  /// Set on [error] when the socket drops without the user hanging up.
  static const disconnectedError = 'Call disconnected';

  static var _activeOutboundLiveCalls = 0;

  /// Active outbound live-call WebSocket sessions (OTA idle-apply busy gating).
  static bool get hasActiveLiveCall => _activeOutboundLiveCalls > 0;

  LiveCallSession({AudioPlayer? playerA, AudioPlayer? playerB})
      : _pA = playerA,
        _pB = playerB;

  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;
  AudioRecorder? _recorder;
  AudioPlayer? _pA;
  AudioPlayer? _pB;
  AudioPlayer get _playerA => _pA ??= AudioPlayer();
  AudioPlayer get _playerB => _pB ??= AudioPlayer();
  int _playbackEpoch = 0;
  Timer? _bufferJitterTimer;
  final LivePcmJitterBuffer _downlinkPcm = LivePcmJitterBuffer(
    sampleRateHz: 24000,
    ceilingTargetMs: _desktopJitterCeilingMs(),
    onUnderrun: () => debugPrint('[LiveCallSession] live_audio_underrun'),
  );
  int _audioSampleRate = 24000;
  var _playBusy = false;
  var _usePlayerA = true;
  LivePcmPlayout? _streamPlayout;
  Timer? _streamPlayoutTimer;
  var _streamPumpInFlight = false;

  static int _desktopJitterCeilingMs() {
    if (kIsWeb) return 1200;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 6000;
      default:
        return 1200;
    }
  }

  bool get _useDesktopWavPlayback =>
      _streamPlayout == null &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static double get _fallbackChunkSec {
    if (kIsWeb) return 0.12;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 1.5;
      default:
        return 0.12;
    }
  }

  /// Start the next WAV chunk before the previous one ends (desktop audioplayers gap fill).
  static const int _desktopPlaybackOverlapMs = 90;

  static bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static int get _streamFrameMs => kIsWeb ? 80 : 20;
  var _disposed = false;
  var _userHungUp = false;
  var _outboundLiveBusyTracked = false;

  // Track D: Client-Side VAD (Voice Activity Detection)
  static const int _vadSampleRate = 16000;
  static const int _vadBytesPerMs = (_vadSampleRate * 2) ~/ 1000; // 32 bytes per ms
  static const int _preSpeechBufferMaxBytes = 150 * _vadBytesPerMs; // 4800 bytes (150ms rolling window)
  static const int _hangoverDurationMs = 1000; // 1000ms generous hangover window
  static const double _vadThresholdMin = 70.0; // Gentle sensitive speech floor (captures normal/soft voice)
  static const double _vadThresholdMax = 150.0; // Safe upper ceiling
  /// While assistant audio plays, ignore uplink below this RMS (speaker echo often looks like speech).
  static const double _bargeInRmsMin = 280.0;
  static const int _liveWsAudioMagic0 = 0xC3;
  static const int _liveWsAudioMagic1 = 0x35;

  final List<Uint8List> _preSpeechRingBuffer = [];
  int _preSpeechBufferBytes = 0;
  double _ambientNoiseRms = 25.0;
  DateTime? _lastSpeechTime;
  bool _isTransmittingSpeech = false;

  @visibleForTesting
  void Function(dynamic data)? onWebSocketSendForTesting;
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<bool> ready = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<LiveUsage?> usage = ValueNotifier(null);
  final ValueNotifier<LiveCaption?> caption = ValueNotifier(null);
  final ValueNotifier<String?> userTranscript = ValueNotifier(null);
  final ValueNotifier<String?> responseTranscript = ValueNotifier(null);
  final ValueNotifier<String> mentionLabel = ValueNotifier('');
  final ValueNotifier<bool> switching = ValueNotifier(false);
  final ValueNotifier<bool> cameraActive = ValueNotifier(false);
  final ValueNotifier<bool> micMuted = ValueNotifier(false);
  final ValueNotifier<String?> activeAttachmentName = ValueNotifier(null);
  final ValueNotifier<String?> activeToolName = ValueNotifier(null);
  final ValueNotifier<bool> speakerOn = ValueNotifier(true);
  RTCVideoRenderer? cameraRenderer;
  MediaStream? _cameraStream;
  Timer? _videoFrameTimer;
  void Function(Map<String, dynamic> committed)? onTurnCommitted;

  /// Browsers block playback until audio runs inside a user gesture (Connect tap).
  Future<void> unlockWebAudioPlayback() async {
    if (!kIsWeb) return;
    try {
      await LivePcmPlayout.warmUpForUserGesture();
      await initAudioContext();
      final silence = Uint8List(1600);
      final wav = SttService.pcmToWav(silence, sampleRate: 16000, channels: 1);
      await _playerA.play(BytesSource(wav), volume: 0.01);
      await _playerA.stop();
    } catch (e) {
      debugPrint('[LiveCallSession] unlockWebAudioPlayback: $e');
    }
  }

  Future<void> initAudioContext() async {
    try {
      final audioCtx = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: speakerOn.value,
          stayAwake: true,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.voiceCommunication,
          audioMode: AndroidAudioMode.inCommunication,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            if (speakerOn.value) AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
          },
        ),
      );
      try {
        await _playerA.setAudioContext(audioCtx);
        await _playerA.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      try {
        await _playerB.setAudioContext(audioCtx);
        await _playerB.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
    } catch (e) {
      debugPrint('[LiveCallSession] setAudioContext error: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    speakerOn.value = !speakerOn.value;
    try {
      await Helper.setSpeakerphoneOn(speakerOn.value);
    } catch (_) {}
    final vol = speakerOn.value ? 1.0 : 0.25;
    try {
      await _pA?.setVolume(vol);
      await _pB?.setVolume(vol);
    } catch (_) {}
    await initAudioContext();
  }

  Future<void> switchCamera() async {
    if (!cameraActive.value || _cameraStream == null) return;
    final videoTracks = _cameraStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;
    try {
      await Helper.switchCamera(videoTracks.first);
    } catch (e) {
      debugPrint('[LiveCallSession] switchCamera error: $e');
      if (kIsWeb) return;
    }
  }

  void setMention({required String mentionId, required String label}) {
    mentionLabel.value = label;
    _sendMention([mentionId], label);
  }

  void clearMention() {
    mentionLabel.value = '';
    _sendMention(const [], '');
  }

  void _sendMention(List<String> ids, String label) {
    final ch = _ch;
    if (ch == null || !ready.value) return;
    ch.sink.add(jsonEncode({'type': 'mention', 'mention_ids': ids, 'label': label}));
  }

  static String liveWsUri(ResLiveStart res) {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final u = Uri.parse(base);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    final path = res.wsPath.trim();
    final parsed = Uri.parse(path.startsWith('/') ? 'http://x$path' : 'http://x/$path');
    final jwt = Session.instance.token.trim();
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: parsed.path,
      queryParameters: {...parsed.queryParameters, 'jwt': jwt},
    ).toString();
  }

  static String guestWsUri(String wsPath) {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final u = Uri.parse(base);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    final path = wsPath.trim();
    if (path.startsWith('ws://') || path.startsWith('wss://')) {
      return path;
    }
    final parsed = Uri.parse(path.startsWith('/') ? 'http://x$path' : 'http://x/$path');
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: parsed.path,
      queryParameters: parsed.queryParameters.isEmpty ? null : parsed.queryParameters,
    ).toString();
  }

  void _setOutboundLiveBusy(bool active) {
    if (active == _outboundLiveBusyTracked) return;
    _outboundLiveBusyTracked = active;
    if (active) {
      _activeOutboundLiveCalls++;
    } else if (_activeOutboundLiveCalls > 0) {
      _activeOutboundLiveCalls--;
    }
  }

  Future<void> connectGuest(String wsPath) async {
    final url = guestWsUri(wsPath);
    await connectUrl(url);
  }

  Future<void> connect(ResLiveStart res) async {
    final url = liveWsUri(res);
    await connectUrl(url);
  }

  Future<void> connectUrl(String url) async {
    await disconnect();
    if (_disposed) return;
    _userHungUp = false;
    await initAudioContext();
    _ch = WebSocketChannel.connect(Uri.parse(url));
    await _ch!.ready;
    if (_disposed) return;
    connected.value = true;
    _setOutboundLiveBusy(true);
    _wsSub = _ch!.stream.listen(
      _onMessage,
      onError: (e) {
        if (_disposed) return;
        error.value = e.toString();
        connected.value = false;
      },
      onDone: () {
        if (_disposed) return;
        final wasConnected = connected.value;
        connected.value = false;
        ready.value = false;
        if (wasConnected && !_userHungUp && error.value == null) {
          error.value = disconnectedError;
        }
      },
    );
    await _startMic();
  }


  String? _wsPayload(dynamic data) {
    if (data is String) return data;
    if (data is Uint8List) return utf8.decode(data, allowMalformed: true);
    if (data is List<int>) return utf8.decode(data, allowMalformed: true);
    return null;
  }

  @visibleForTesting
  void dispatchWsMessageForTesting(dynamic data) => _onMessage(data);

  void _schedulePlaybackDrain({bool flush = false}) {
    if (_streamPlayout != null) {
      unawaited(_pumpStreamPlayout(flush: flush));
      return;
    }
    final targetSec = _downlinkPcm.targetBufferMs / 1000.0;
    final minBytes = (_audioSampleRate * 2 * targetSec).toInt();
    if (_downlinkPcm.length >= minBytes || flush) {
      _bufferJitterTimer?.cancel();
      unawaited(_drainPlayback(flush: flush));
    } else if (_downlinkPcm.isNotEmpty && !_playBusy) {
      _bufferJitterTimer?.cancel();
      final waitMs = max(50, _downlinkPcm.targetBufferMs ~/ 2);
      _bufferJitterTimer = Timer(Duration(milliseconds: waitMs), () {
        if (!_disposed && !_playBusy && _downlinkPcm.isNotEmpty) {
          unawaited(_drainPlayback(flush: true));
        }
      });
    }
  }

  void _ingestDownlinkPcm(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == _liveWsAudioMagic0 && bytes[1] == _liveWsAudioMagic1) {
      try {
        final audio = LiveWsAudio.fromBuffer(bytes.sublist(2));
        if (audio.sampleRateHz > 0) {
          _audioSampleRate = audio.sampleRateHz;
          _downlinkPcm.setSampleRateHz(_audioSampleRate);
        }
        final pcm = Uint8List.fromList(audio.pcmS16le);
        if (pcm.isEmpty) return;
        _downlinkPcm.write(pcm);
        _schedulePlaybackDrain();
        return;
      } catch (e) {
        debugPrint('[LiveCallSession] LiveWsAudio decode failed: $e');
      }
    }
    _downlinkPcm.setSampleRateHz(_audioSampleRate);
    _downlinkPcm.write(bytes);
    _schedulePlaybackDrain();
  }

  void _onMessage(dynamic data) {
    if (_disposed) return;
    if (data is Uint8List || data is List<int>) {
      final bytes = data is Uint8List ? data : Uint8List.fromList(data as List<int>);
      if (bytes.isNotEmpty && bytes[0] != 0x7B && bytes[0] != 0x5B) {
        _ingestDownlinkPcm(bytes);
        return;
      }
    }
    final text = _wsPayload(data);
    if (text == null || text.isEmpty) return;
    if (text.contains('"live":"ready"') || text.contains('"live": "ready"')) {
      if (!_disposed) ready.value = true;
      unawaited(_initStreamPlayout());
      return;
    }
    if (text.contains('"live":"hangup"') || text.contains('"live": "hangup"')) {
      unawaited(hangup());
      return;
    }
    if (text.contains('"live":"tool_start"') || text.contains('"live": "tool_start"')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        if (!_disposed) activeToolName.value = m['name']?.toString() ?? 'tool';
      } catch (_) {}
      return;
    }
    if (text.contains('"live":"tool_end"') || text.contains('"live": "tool_end"')) {
      if (!_disposed) activeToolName.value = null;
      return;
    }
    if (text.contains('"live":"mention"') || text.contains('"live": "mention"')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        if (m['live'] == 'mention' && !_disposed) {
          mentionLabel.value = m['label']?.toString() ?? '';
          switching.value = m['switching'] == true;
          return;
        }
      } catch (_) {}
    }
    if (text.contains('liveError')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        if (!_disposed) error.value = m['liveError']?.toString();
      } catch (_) {
        if (!_disposed) error.value = text;
      }
      return;
    }
    if (text.contains('"error"') || text.contains('"error":')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        final err = m['error'];
        final msg = (err is Map ? err['message'] : err)?.toString();
        if (msg != null && msg.isNotEmpty && !_disposed) {
          error.value = msg;
          return;
        }
      } catch (_) {}
    }
    if (text.contains('liveTurnCommitted')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        final committed = m['liveTurnCommitted'] as Map<String, dynamic>?;
        if (committed != null) {
          onTurnCommitted?.call(committed);
          final uText = committed['user_text']?.toString();
          final aText = committed['assistant_text']?.toString();
          if (uText != null && uText.trim().isNotEmpty && !_disposed) {
            userTranscript.value = uText.trim();
          }
          if (aText != null && aText.trim().isNotEmpty && !_disposed) {
            responseTranscript.value = aText.trim();
          }
        }
      } catch (_) {}
      return;
    }
    if (text.contains('setupComplete')) {
      if (!_disposed) ready.value = true;
      unawaited(_initStreamPlayout());
    }
    try {
      final v = jsonDecode(text);
      if (v is Map) {
        if (v['serverContent']?['interrupted'] == true) {
          _handleInterruption();
          return;
        }
        final tc = v['toolCall'] ?? v['serverContent']?['toolCall'];
        if (tc is Map) {
          final fcs = tc['functionCalls'];
          if (fcs is List && fcs.isNotEmpty && fcs[0] is Map) {
            final name = fcs[0]['name']?.toString() ?? 'tool';
            if (!_disposed) activeToolName.value = name;
          }
        }
      }
      _readUsage(v);
      _readTranscription(v);
      _playGeminiAudio(v);
    } catch (_) {}
  }

  void _handleInterruption() {
    _playbackEpoch++;
    _downlinkPcm.clear();
    _bufferJitterTimer?.cancel();
    _playBusy = false;
    unawaited(_pA?.stop());
    unawaited(_pB?.stop());
  }

  void toggleMicMute() {
    micMuted.value = !micMuted.value;
    if (micMuted.value) {
      _isTransmittingSpeech = false;
      _lastSpeechTime = null;
      _preSpeechRingBuffer.clear();
      _preSpeechBufferBytes = 0;
    }
  }

  Future<void> toggleCamera() async {
    if (cameraActive.value) {
      await stopCamera();
    } else {
      await startCamera();
    }
  }

  Future<void> startCamera() async {
    if (_disposed || cameraActive.value) return;
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!_disposed) error.value = 'Camera permission required';
          return;
        }
      }

      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      cameraRenderer = renderer;

      final mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '15',
          },
          'facingMode': 'user',
          'optional': [],
        }
      };

      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _cameraStream = stream;
      renderer.srcObject = stream;
      cameraActive.value = true;

      _videoFrameTimer?.cancel();
      _videoFrameTimer = Timer.periodic(const Duration(seconds: 1), (_) => _captureAndSendFrame());
    } catch (e) {
      debugPrint('[LiveCallSession] startCamera error: $e');
      if (!_disposed) error.value = 'Failed to access camera: $e';
      await stopCamera();
    }
  }

  Future<void> _captureAndSendFrame() async {
    if (_disposed || !cameraActive.value || _cameraStream == null || _ch == null) return;
    try {
      final videoTracks = _cameraStream!.getVideoTracks();
      if (videoTracks.isEmpty) return;
      final track = videoTracks.first;
      final buffer = await track.captureFrame();
      final bytes = buffer.asUint8List();
      if (bytes.isEmpty) return;

      Uint8List sendBytes = bytes;
      var mimeType = 'image/jpeg';
      final isPng = bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;

      if (isPng) {
        final image = img.decodeImage(bytes);
        if (image != null) {
          sendBytes = Uint8List.fromList(img.encodeJpg(image, quality: 75));
          mimeType = 'image/jpeg';
        } else {
          mimeType = 'image/png';
        }
      }

      final b64 = base64Encode(sendBytes);
      _sendWs(jsonEncode({
        'type': 'video',
        'data': b64,
        'mime_type': mimeType,
      }));
    } catch (e) {
      debugPrint('[LiveCallSession] captureFrame error: $e');
    }
  }

  Future<void> stopCamera() async {
    _videoFrameTimer?.cancel();
    _videoFrameTimer = null;
    cameraActive.value = false;
    try {
      if (_cameraStream != null) {
        for (final track in _cameraStream!.getTracks()) {
          track.stop();
        }
        await _cameraStream!.dispose();
        _cameraStream = null;
      }
      if (cameraRenderer != null) {
        cameraRenderer!.srcObject = null;
        await cameraRenderer!.dispose();
        cameraRenderer = null;
      }
    } catch (e) {
      debugPrint('[LiveCallSession] stopCamera error: $e');
    }
  }

  void _readTranscription(dynamic v) {
    if (_disposed || v is! Map) return;
    final sc = v['serverContent'];
    if (sc is! Map) return;

    // Spoken input transcription (live user speech)
    final inText = sc['inputTranscription']?['text']?.toString() ??
        sc['interimInputTranscription']?['text']?.toString();
    if (inText != null && inText.trim().isNotEmpty) {
      if (!_disposed) {
        // When user speaks again, clear previous response bubble and replace user transcript
        if (responseTranscript.value != null && responseTranscript.value!.isNotEmpty) {
          responseTranscript.value = null;
        }
        userTranscript.value = inText.trim();
        caption.value = LiveCaption(text: inText.trim(), isUser: true);
      }
      return;
    }

    // Spoken output transcription (model speech stream)
    final outText = sc['outputTranscription']?['text']?.toString();
    if (outText != null && outText.isNotEmpty) {
      if (!_disposed) {
        activeToolName.value = null;
        final cur = responseTranscript.value ?? '';
        final newText = cur.isEmpty ? outText.trimLeft() : '$cur$outText';
        responseTranscript.value = newText;
        caption.value = LiveCaption(text: newText, isUser: false);
      }
      return;
    }

    // Also check modelTurn parts for text (used when model responds after tool calls)
    final parts = sc['modelTurn']?['parts'];
    if (parts is List) {
      for (final p in parts) {
        if (p is Map && p['text'] is String) {
          final pText = (p['text'] as String).trim();
          if (pText.isNotEmpty && !_disposed) {
            activeToolName.value = null;
            final cur = responseTranscript.value ?? '';
            final newText = cur.isEmpty ? pText : '$cur $pText';
            responseTranscript.value = newText;
            caption.value = LiveCaption(text: newText, isUser: false);
          }
        }
      }
    }
  }

  void _readUsage(dynamic v) {
    if (_disposed || v is! Map) return;
    final u = v['usageMetadata'] ?? v['usage_metadata'];
    if (u is! Map) return;
    int n(String a, String b) => (u[a] ?? u[b]) is num ? ((u[a] ?? u[b]) as num).toInt() : 0;
    final total = n('totalTokenCount', 'total_token_count');
    if (total <= 0) return;
    if (!_disposed) {
      usage.value = LiveUsage(
        promptTokens: n('promptTokenCount', 'prompt_token_count'),
        responseTokens: n('responseTokenCount', 'response_token_count'),
        totalTokens: total,
      );
    }
  }

  void _playGeminiAudio(dynamic v) {
    if (v is! Map) return;
    final parts = v['serverContent']?['modelTurn']?['parts'];
    if (parts is List) {
      for (final p in parts) {
        if (p is! Map) continue;
        final inline = p['inlineData'] ?? p['inline_data'];
        if (inline is! Map) continue;
        final b64 = inline['data']?.toString();
        if (b64 == null || b64.isEmpty) continue;
        final mime = inline['mimeType']?.toString() ?? inline['mime_type']?.toString() ?? 'audio/pcm;rate=24000';
        _audioSampleRate = int.tryParse(RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1) ?? '') ?? 24000;
        _downlinkPcm.setSampleRateHz(_audioSampleRate);
        final pcm = base64Decode(b64);
        _downlinkPcm.write(pcm);
      }
    }
    final turnEnded = v['serverContent']?['turnComplete'] == true || v['serverContent']?['generationComplete'] == true;
    if (_downlinkPcm.isNotEmpty) {
      _schedulePlaybackDrain(flush: turnEnded);
    }
  }

  int _chunkDurationMs(int bytesLength) {
    if (_audioSampleRate <= 0) return 0;
    return (bytesLength * 1000) ~/ (_audioSampleRate * 2);
  }

  Uint8List _extractPlaybackChunk({double maxDurationSec = 3.0}) {
    final maxBytes = (_audioSampleRate * 2 * maxDurationSec).toInt();
    return _downlinkPcm.takeForPlayback(maxBytes);
  }

  Future<void> _initStreamPlayout() async {
    if (_disposed || _streamPlayout != null) return;
    final playout = await LivePcmPlayout.tryCreate();
    if (playout == null || _disposed) return;
    try {
      await playout.start(_audioSampleRate);
      _streamPlayout = playout;
      _streamPlayoutTimer?.cancel();
      _streamPlayoutTimer = Timer.periodic(Duration(milliseconds: _streamFrameMs), (_) {
        unawaited(_pumpStreamPlayout());
      });
      debugPrint('[LiveCallSession] stream playout active @ ${_audioSampleRate}Hz');
    } catch (e) {
      debugPrint('[LiveCallSession] stream playout init failed: $e — using WAV fallback');
    }
  }

  Future<void> _pumpStreamPlayout({bool flush = false}) async {
    if (_streamPumpInFlight) return;
    final playout = _streamPlayout;
    if (_disposed || playout == null) return;
    _streamPumpInFlight = true;
    try {
      final frameBytes = (_audioSampleRate * 2 * _streamFrameMs) ~/ 1000;
      if (frameBytes <= 0) return;
      final minBytes = (_audioSampleRate * 2 * _downlinkPcm.targetBufferMs) ~/ 1000;
      if (!flush && _downlinkPcm.length < minBytes) {
        await playout.refreshQueuedMs();
        _playBusy = _downlinkPcm.bufferedMs() > 30 || playout.scheduledAheadMs > 20;
        return;
      }

      const maxLookaheadMs = 300;
      final burstCap = kIsWeb || playout.scheduledAheadMs > 0 ? 10 : 1;
      var iterations = 0;
      while (_downlinkPcm.isNotEmpty && !_disposed) {
        await playout.refreshQueuedMs();
        if (playout.scheduledAheadMs >= maxLookaheadMs && !flush) break;
        final chunk = _downlinkPcm.takeForPlayback(frameBytes);
        if (chunk.isEmpty) break;
        try {
          await playout.write(chunk);
        } catch (e) {
          debugPrint('[LiveCallSession] stream write failed: $e');
          break;
        }
        iterations++;
        if (iterations >= burstCap) break;
      }
      await playout.refreshQueuedMs();
      _playBusy = _downlinkPcm.bufferedMs() > 30 || playout.scheduledAheadMs > 20;
    } finally {
      _streamPumpInFlight = false;
    }
  }


  Future<void> _stopStreamPlayout() async {
    _streamPlayoutTimer?.cancel();
    _streamPlayoutTimer = null;
    final playout = _streamPlayout;
    _streamPlayout = null;
    if (playout != null) {
      try {
        await playout.stop();
      } catch (_) {}
    }
  }

  Future<void> _awaitPlayerDone(AudioPlayer player, int durMs) async {
    if (durMs <= 0) return;
    // audioplayers on Windows often signals complete before PCM finishes, which
    // caused the drain loop to skip ahead (cropped tail-only audio) and dropped
    // mic gating (broken uplink / subtitles).
    if (_useDesktopWavPlayback) {
      await Future.delayed(Duration(milliseconds: durMs + 50));
      return;
    }
    try {
      await player.onPlayerComplete.first.timeout(Duration(milliseconds: durMs + 300));
    } catch (_) {
      await Future.delayed(Duration(milliseconds: durMs));
    }
  }

  Future<void> _drainPlayback({bool flush = false}) async {
    if (_playBusy || _downlinkPcm.isEmpty || _disposed) return;
    _playBusy = true;
    final epoch = ++_playbackEpoch;
    final targetSec = _downlinkPcm.targetBufferMs / 1000.0;
    final minBytes = (_audioSampleRate * 2 * targetSec).toInt();

    try {
      while (_downlinkPcm.isNotEmpty && !_disposed && _playbackEpoch == epoch) {
        if (!flush && _downlinkPcm.length < minBytes) break;
        final chunk = _extractPlaybackChunk(maxDurationSec: _fallbackChunkSec);
        if (chunk.isEmpty) break;
        final durMs = _chunkDurationMs(chunk.length);
        final wav = SttService.pcmToWav(chunk, sampleRate: _audioSampleRate, channels: 1);

        final player = _usePlayerA ? _playerA : _playerB;
        await player.play(BytesSource(wav));
        if (_disposed || _playbackEpoch != epoch) break;
        if (_useDesktopWavPlayback) {
          final waitMs = max(0, durMs - _desktopPlaybackOverlapMs);
          await Future.delayed(Duration(milliseconds: waitMs));
        } else {
          await _awaitPlayerDone(player, durMs);
        }
        if (_disposed || _playbackEpoch != epoch) break;
        _usePlayerA = !_usePlayerA;
        flush = false;
      }
    } catch (e) {
      if (!_disposed) {
        final hint = kIsWeb ? ' (check browser tab mute / autoplay settings)' : '';
        error.value = 'Audio playback failed: $e$hint';
      }
    } finally {
      if (_playbackEpoch == epoch) {
        _playBusy = false;
        if (!_disposed && _downlinkPcm.isNotEmpty) {
          if (_downlinkPcm.length >= minBytes) {
            unawaited(_drainPlayback());
          }
        }
      }
    }
  }

  static double _computeRms(Uint8List pcm) {
    if (pcm.length < 2) return 0.0;
    final bd = ByteData.sublistView(pcm);
    final numSamples = pcm.length ~/ 2;
    double sumSquares = 0.0;
    for (var i = 0; i < numSamples; i++) {
      final sample = bd.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }
    return sqrt(sumSquares / numSamples);
  }

  void _sendWs(dynamic data) {
    onWebSocketSendForTesting?.call(data);
    _ch?.sink.add(data);
  }

  void _addToPreSpeechBuffer(Uint8List chunk) {
    _preSpeechRingBuffer.add(chunk);
    _preSpeechBufferBytes += chunk.length;
    while (_preSpeechBufferBytes > _preSpeechBufferMaxBytes && _preSpeechRingBuffer.isNotEmpty) {
      final removed = _preSpeechRingBuffer.removeAt(0);
      _preSpeechBufferBytes -= removed.length;
    }
  }

  void _flushPreSpeechBuffer() {
    if (_preSpeechRingBuffer.isEmpty) return;
    for (final chunk in _preSpeechRingBuffer) {
      _sendWs(chunk);
    }
    _preSpeechRingBuffer.clear();
    _preSpeechBufferBytes = 0;
  }

  void _processMicChunkWithVad(Uint8List pcm16k) {
    if (_disposed || pcm16k.isEmpty || micMuted.value) return;
    if (_ch == null && onWebSocketSendForTesting == null) return;

    final rms = _computeRms(pcm16k);

    // Windows `record` + AEC often yields near-silent PCM so client VAD never uplinks.
    // Stream continuously while the assistant is not playing; keep barge-in during playback.
    if (_isWindowsDesktop) {
      if (_playBusy) {
        final bargeIn = rms >= _bargeInRmsMin;
        if (!bargeIn) {
          _addToPreSpeechBuffer(pcm16k);
          return;
        }
        _handleInterruption();
      }
      _sendWs(pcm16k);
      return;
    }
    // Dynamic speech threshold with gentle sensitive floor (70.0) and bounded ceiling (150.0):
    // Silence/hiss is typically RMS 5-30. Normal/soft speech is RMS 100-500.
    final threshold = min(_vadThresholdMax, max(_vadThresholdMin, _ambientNoiseRms * 1.3));
    final isSpeech = rms >= threshold;
    final now = DateTime.now();

    // Speaker playback bleeds into the mic and can look like continuous user speech to Gemini.
    // Hold uplink unless the user clearly barges in (loud/local voice over the echo).
    if (_playBusy) {
      final bargeIn = isSpeech && rms >= _bargeInRmsMin;
      if (!bargeIn) {
        _addToPreSpeechBuffer(pcm16k);
        return;
      }
      _handleInterruption();
    }

    if (isSpeech) {
      _lastSpeechTime = now;
    } else if (!_playBusy) {
      // Track ambient noise baseline slowly during silence, bounded to prevent runaway
      _ambientNoiseRms = min(80.0, (_ambientNoiseRms * 0.98) + (rms * 0.02));
    }

    // Hangover window: 1000ms. Keep transmitting for 1.0s after speech drops below threshold to avoid clipping word endings.
    final inHangover = _lastSpeechTime != null &&
        now.difference(_lastSpeechTime!).inMilliseconds <= _hangoverDurationMs;

    final shouldTransmit = isSpeech || inHangover;

    if (shouldTransmit) {
      if (!_isTransmittingSpeech) {
        // When speech begins: immediately flush _preSpeechRingBuffer to _ch!.sink first, then stream the current chunk.
        _isTransmittingSpeech = true;
        _flushPreSpeechBuffer();
      }
      _sendWs(pcm16k);
    } else {
      // When silence > 1000ms: drop chunk (do NOT send to WebSocket). Maintain 150ms rolling ring buffer.
      _isTransmittingSpeech = false;
      _addToPreSpeechBuffer(pcm16k);
    }
  }

  Future<void> _startMic() async {
    // 1. Ensure runtime microphone permission is actively requested and granted
    final permGranted = await sttMicPermissionEnsure();
    if (!permGranted) {
      if (!_disposed) error.value = sttMicErrorMessage();
      return;
    }

    // 2. Stop any active recording on SttService to prevent AudioRecord collision
    if (SttService.instance.isRecording.value) {
      try {
        await SttService.instance.cancel();
      } catch (_) {}
    }

    _recorder = AudioRecorder();
    if (!await _recorder!.hasPermission()) {
      if (!_disposed) error.value = sttMicErrorMessage();
      return;
    }

    // 3. Resolve active input device only on Windows desktop; mobile uses default system mic
    InputDevice? activeMic;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      try {
        activeMic = await SttService.instance.resolveActiveMicDevice();
      } catch (_) {}
    }

    // 4. Platform-tailored stream candidates:
    // On mobile (Android / iOS): Strictly mono (1 channel), prioritized at 16kHz for Gemini/OpenAI live models.
    // Stereo with hardware AEC is rejected by Android audio HAL and causes fatal process aborts.
    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    final isWindowsDesktop = _isWindowsDesktop;
    final candidates = liveCallMicStreamCandidates(
      isMobile: isMobile,
      isWeb: kIsWeb,
      isWindowsDesktop: isWindowsDesktop,
    );

    Stream<Uint8List>? stream;
    int streamRate = 16000;
    int streamChannels = 1;

    for (final cand in candidates) {
      // Windows desktop: skip AEC/NS — drivers often mute the stream or break Live uplink.
      if (!isWindowsDesktop) {
        try {
          final cfg = RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: cand.sampleRate,
            numChannels: cand.numChannels,
            bitRate: cand.bitRate,
            device: activeMic,
            noiseSuppress: true,
            echoCancel: true,
          );
          stream = await _recorder!.startStream(cfg);
          streamRate = cand.sampleRate;
          streamChannels = cand.numChannels;
          debugPrint('[LiveCallSession] startStream active: ${cand.sampleRate}Hz ${cand.numChannels}ch (AEC on)');
          break;
        } catch (e) {
          debugPrint('[LiveCallSession] candidate ${cand.sampleRate}Hz with AEC failed: $e');
        }
      }

      try {
        final fallbackCfg = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: cand.sampleRate,
          numChannels: cand.numChannels,
          bitRate: cand.bitRate,
          device: activeMic,
          noiseSuppress: false,
          echoCancel: false,
        );
        stream = await _recorder!.startStream(fallbackCfg);
        streamRate = cand.sampleRate;
        streamChannels = cand.numChannels;
        debugPrint('[LiveCallSession] startStream active fallback: ${cand.sampleRate}Hz ${cand.numChannels}ch (raw)');
        break;
      } catch (e) {
        debugPrint('[LiveCallSession] candidate ${cand.sampleRate}Hz raw failed: $e');
      }
    }

    if (stream == null) {
      if (!_disposed) error.value = 'Failed to start microphone stream';
      return;
    }

    _micSub = stream.listen((chunk) {
      if (_disposed || (_ch == null && onWebSocketSendForTesting == null) || chunk.isEmpty || micMuted.value) return;
      final pcm16k = (streamRate == 16000 && streamChannels == 1)
          ? chunk
          : SttService.resampleTo16kMono(chunk, srcRate: streamRate, srcChannels: streamChannels);
      _processMicChunkWithVad(pcm16k);
    });
  }

  void sendMediaAttachment({
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) {
    if (_disposed || _ch == null || bytes.isEmpty) return;
    activeAttachmentName.value = name;
    final b64 = base64Encode(bytes);
    final payload = jsonEncode({
      'type': 'media_attach',
      'name': name,
      'mime_type': mimeType,
      'data': b64,
    });
    _sendWs(payload);
  }

  void clearMediaAttachment() {
    activeAttachmentName.value = null;
  }

  Future<void> hangup() async {
    _userHungUp = true;
    try {
      _ch?.sink.add('{"type":"hangup"}');
    } catch (_) {}
    await disconnect();
  }

  Future<void> disconnect() async {
    _setOutboundLiveBusy(false);
    if (!_disposed) {
      ready.value = false;
      connected.value = false;
      caption.value = null;
      userTranscript.value = null;
      responseTranscript.value = null;
      activeAttachmentName.value = null;
      activeToolName.value = null;
      speakerOn.value = true;
    }
    await stopCamera();
    if (kDebugMode) {
      debugPrint(
        '[LiveCallSession] audio stats: underruns=${_downlinkPcm.underrunCount} '
        'targetMs=${_downlinkPcm.targetBufferMs} stream=${_streamPlayout != null}',
      );
    }
    await _stopStreamPlayout();
    await LivePcmPlayout.disposePlatformAudio();
    _bufferJitterTimer?.cancel();
    _bufferJitterTimer = null;
    _playbackEpoch++;
    _downlinkPcm.clear();
    _playBusy = false;
    _preSpeechRingBuffer.clear();
    _preSpeechBufferBytes = 0;
    _isTransmittingSpeech = false;
    _lastSpeechTime = null;
    await _wsSub?.cancel();
    _wsSub = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
    try {
      await _pA?.stop();
    } catch (_) {}
    try {
      await _pB?.stop();
    } catch (_) {}
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  void dispose() {
    _disposed = true;
    _playbackEpoch++;
    _bufferJitterTimer?.cancel();
    _bufferJitterTimer = null;
    unawaited(disconnect());
    try {
      _pA?.dispose();
    } catch (_) {}
    try {
      _pB?.dispose();
    } catch (_) {}
    connected.dispose();
    ready.dispose();
    error.dispose();
    usage.dispose();
    caption.dispose();
    userTranscript.dispose();
    responseTranscript.dispose();
    mentionLabel.dispose();
    switching.dispose();
    cameraActive.dispose();
    micMuted.dispose();
    activeAttachmentName.dispose();
    activeToolName.dispose();
    speakerOn.dispose();
  }

  @visibleForTesting
  static double computeRms(Uint8List pcm) => _computeRms(pcm);

  @visibleForTesting
  bool get isTransmittingSpeech => _isTransmittingSpeech;

  @visibleForTesting
  int get preSpeechBufferBytes => _preSpeechBufferBytes;

  @visibleForTesting
  int get preSpeechRingBufferCount => _preSpeechRingBuffer.length;

  @visibleForTesting
  double get ambientNoiseRms => _ambientNoiseRms;

  @visibleForTesting
  void processMicChunkWithVad(Uint8List pcm16k) => _processMicChunkWithVad(pcm16k);

  @visibleForTesting
  int get incomingPcmBytes => _downlinkPcm.length;

  @visibleForTesting
  Uint8List extractPlaybackChunkForTesting({double maxDurationSec = 3.0}) =>
      _extractPlaybackChunk(maxDurationSec: maxDurationSec);

  @visibleForTesting
  int chunkDurationMsForTesting(int bytesLength) => _chunkDurationMs(bytesLength);

  @visibleForTesting
  void addIncomingPcmForTesting(Uint8List bytes) => _downlinkPcm.write(bytes);

  @visibleForTesting
  void setAudioSampleRateForTesting(int rate) => _audioSampleRate = rate;

  @visibleForTesting
  bool get playBusy => _playBusy;

  @visibleForTesting
  void setPlayBusyForTesting(bool busy) => _playBusy = busy;

  @visibleForTesting
  void handleInterruptionForTesting() => _handleInterruption();

  @visibleForTesting
  static Uint8List compressFrameBytes(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        return Uint8List.fromList(img.encodeJpg(decoded, quality: 75));
      }
    }
    return bytes;
  }
}
