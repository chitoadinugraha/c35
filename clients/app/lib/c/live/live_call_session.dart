import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:audioplayers/audioplayers.dart';
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
  LiveCallSession();

  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;
  AudioRecorder? _recorder;
  final AudioPlayer _player = AudioPlayer();
  final BytesBuilder _incomingPcm = BytesBuilder(copy: false);
  int _audioSampleRate = 24000;
  var _playBusy = false;
  var _disposed = false;
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<bool> ready = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<LiveUsage?> usage = ValueNotifier(null);
  final ValueNotifier<LiveCaption?> caption = ValueNotifier(null);
  final ValueNotifier<String> mentionLabel = ValueNotifier('');
  final ValueNotifier<bool> switching = ValueNotifier(false);
  void Function(Map<String, dynamic> committed)? onTurnCommitted;

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

  Future<void> connect(ResLiveStart res) async {
    await disconnect();
    if (_disposed) return;
    final url = liveWsUri(res);
    _ch = WebSocketChannel.connect(Uri.parse(url));
    await _ch!.ready;
    if (_disposed) return;
    connected.value = true;
    _wsSub = _ch!.stream.listen(
      _onMessage,
      onError: (e) {
        if (_disposed) return;
        error.value = e.toString();
        connected.value = false;
      },
      onDone: () {
        if (_disposed) return;
        connected.value = false;
        ready.value = false;
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

  void _onMessage(dynamic data) {
    if (_disposed) return;
    final text = _wsPayload(data);
    if (text == null || text.isEmpty) return;
    if (text.contains('"live":"ready"') || text.contains('"live": "ready"')) {
      if (!_disposed) ready.value = true;
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
    if (text.contains('liveTurnCommitted')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        final committed = m['liveTurnCommitted'] as Map<String, dynamic>?;
        if (committed != null) {
          onTurnCommitted?.call(committed);
        }
      } catch (_) {}
      return;
    }
    if (text.contains('setupComplete')) {
      if (!_disposed) ready.value = true;
    }
    try {
      final v = jsonDecode(text);
      if (v is Map) {
        if (v['serverContent']?['interrupted'] == true) {
          _handleInterruption();
          return;
        }
      }
      _readUsage(v);
      _readTranscription(v);
      _playGeminiAudio(v);
    } catch (_) {}
  }

  void _handleInterruption() {
    _incomingPcm.clear();
    _playBusy = false;
    unawaited(_player.stop());
  }

  void _readTranscription(dynamic v) {
    if (_disposed || v is! Map) return;
    final sc = v['serverContent'];
    if (sc is! Map) return;

    // Spoken input transcription (live user speech)
    final inText = sc['inputTranscription']?['text']?.toString() ??
        sc['interimInputTranscription']?['text']?.toString();
    if (inText != null && inText.trim().isNotEmpty) {
      if (!_disposed) caption.value = LiveCaption(text: inText.trim(), isUser: true);
      return;
    }

    // Spoken output transcription (model speech stream)
    final outText = sc['outputTranscription']?['text']?.toString();
    if (outText != null && outText.isNotEmpty) {
      final cur = caption.value;
      final newText = (cur != null && !cur.isUser) ? '${cur.text}$outText' : outText.trimLeft();
      if (!_disposed) caption.value = LiveCaption(text: newText, isUser: false);
      return;
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
        final pcm = base64Decode(b64);
        _incomingPcm.add(pcm);
      }
    }
    final turnEnded = v['serverContent']?['turnComplete'] == true || v['serverContent']?['generationComplete'] == true;
    final minBytes = (_audioSampleRate * 2 * 0.25).toInt();
    if (_incomingPcm.length >= minBytes || (turnEnded && _incomingPcm.isNotEmpty)) {
      unawaited(_drainPlayback());
    }
  }

  Future<void> _drainPlayback() async {
    if (_playBusy || _incomingPcm.isEmpty) return;
    _playBusy = true;
    try {
      while (_incomingPcm.isNotEmpty) {
        final bytes = _incomingPcm.takeBytes();
        if (bytes.isEmpty) break;
        final wav = SttService.pcmToWav(bytes, sampleRate: _audioSampleRate, channels: 1);
        final done = _player.onPlayerComplete.first.timeout(const Duration(seconds: 120));
        await _player.play(BytesSource(wav));
        await done;
      }
    } catch (e) {
      if (!_disposed) error.value = 'Audio playback failed: $e';
    } finally {
      _playBusy = false;
      if (!_disposed && _incomingPcm.isNotEmpty) unawaited(_drainPlayback());
    }
  }

  Future<void> _startMic() async {
    _recorder = AudioRecorder();
    if (!await _recorder!.hasPermission()) {
      if (!_disposed) error.value = 'Microphone permission required';
      return;
    }
    InputDevice? activeMic;
    try {
      activeMic = await SttService.instance.resolveActiveMicDevice();
    } catch (_) {}

    final candidates = [
      (sampleRate: 48000, numChannels: 2, bitRate: 1536000),
      (sampleRate: 48000, numChannels: 1, bitRate: 768000),
      (sampleRate: 44100, numChannels: 2, bitRate: 1411200),
      (sampleRate: 44100, numChannels: 1, bitRate: 705600),
      (sampleRate: 16000, numChannels: 1, bitRate: 256000),
      (sampleRate: 16000, numChannels: 2, bitRate: 512000),
    ];

    Stream<Uint8List>? stream;
    int streamRate = 16000;
    int streamChannels = 1;

    for (final cand in candidates) {
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
        debugPrint('[LiveCallSession] startStream active: ${cand.sampleRate}Hz ${cand.numChannels}ch');
        break;
      } catch (e) {
        debugPrint('[LiveCallSession] candidate ${cand.sampleRate}Hz failed: $e');
      }
    }

    if (stream == null) {
      if (!_disposed) error.value = 'Failed to start microphone stream';
      return;
    }

    _micSub = stream.listen((chunk) {
      if (_disposed || _ch == null || chunk.isEmpty) return;
      final pcm16k = (streamRate == 16000 && streamChannels == 1)
          ? chunk
          : SttService.resampleTo16kMono(chunk, srcRate: streamRate, srcChannels: streamChannels);
      _ch!.sink.add(pcm16k);
    });
  }

  Future<void> hangup() async {
    try {
      _ch?.sink.add('{"type":"hangup"}');
    } catch (_) {}
    await disconnect();
  }

  Future<void> disconnect() async {
    if (!_disposed) {
      ready.value = false;
      connected.value = false;
      caption.value = null;
    }
    _incomingPcm.clear();
    _playBusy = false;
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
      await _player.stop();
    } catch (_) {}
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    try {
      _player.dispose();
    } catch (_) {}
    connected.dispose();
    ready.dispose();
    error.dispose();
    usage.dispose();
    caption.dispose();
  }
}
