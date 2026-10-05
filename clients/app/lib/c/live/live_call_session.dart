import 'dart:async';
import 'dart:convert';

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

class LiveCallSession {
  LiveCallSession();

  WebSocketChannel? _ch;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<Uint8List>? _micSub;
  AudioRecorder? _recorder;
  final AudioPlayer _player = AudioPlayer();
  final List<Uint8List> _playQueue = [];
  var _playBusy = false;
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<bool> ready = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<LiveUsage?> usage = ValueNotifier(null);

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
    final url = liveWsUri(res);
    _ch = WebSocketChannel.connect(Uri.parse(url));
    await _ch!.ready;
    connected.value = true;
    _wsSub = _ch!.stream.listen(
      _onMessage,
      onError: (e) {
        error.value = e.toString();
        connected.value = false;
      },
      onDone: () {
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
    final text = _wsPayload(data);
    if (text == null || text.isEmpty) return;
    if (text.contains('"live":"ready"') || text.contains('"live": "ready"')) {
      ready.value = true;
      return;
    }
    if (text.contains('liveError')) {
      try {
        final m = jsonDecode(text) as Map<String, dynamic>;
        error.value = m['liveError']?.toString();
      } catch (_) {
        error.value = text;
      }
      return;
    }
    if (text.contains('setupComplete')) ready.value = true;
    try {
      final v = jsonDecode(text);
      _readUsage(v);
      _playGeminiAudio(v);
    } catch (_) {}
  }

  void _readUsage(dynamic v) {
    if (v is! Map) return;
    final u = v['usageMetadata'] ?? v['usage_metadata'];
    if (u is! Map) return;
    int n(String a, String b) => (u[a] ?? u[b]) is num ? ((u[a] ?? u[b]) as num).toInt() : 0;
    final total = n('totalTokenCount', 'total_token_count');
    if (total <= 0) return;
    usage.value = LiveUsage(
      promptTokens: n('promptTokenCount', 'prompt_token_count'),
      responseTokens: n('responseTokenCount', 'response_token_count'),
      totalTokens: total,
    );
  }

  void _playGeminiAudio(dynamic v) {
    if (v is! Map) return;
    final parts = v['serverContent']?['modelTurn']?['parts'];
    if (parts is! List) return;
    for (final p in parts) {
      if (p is! Map) continue;
      final inline = p['inlineData'] ?? p['inline_data'];
      if (inline is! Map) continue;
      final b64 = inline['data']?.toString();
      if (b64 == null || b64.isEmpty) continue;
      final mime = inline['mimeType']?.toString() ?? inline['mime_type']?.toString() ?? 'audio/pcm;rate=24000';
      final rate = int.tryParse(RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1) ?? '') ?? 24000;
      final pcm = base64Decode(b64);
      final wav = SttService.pcmToWav(pcm, sampleRate: rate, channels: 1);
      _enqueuePlayback(wav);
    }
  }

  void _enqueuePlayback(Uint8List wav) {
    _playQueue.add(wav);
    unawaited(_drainPlayback());
  }

  Future<void> _drainPlayback() async {
    if (_playBusy) return;
    _playBusy = true;
    try {
      while (_playQueue.isNotEmpty) {
        final wav = _playQueue.removeAt(0);
        final done = _player.onPlayerComplete.first.timeout(const Duration(seconds: 120));
        await _player.play(BytesSource(wav));
        await done;
      }
    } catch (e) {
      error.value = 'Audio playback failed: $e';
    } finally {
      _playBusy = false;
      if (_playQueue.isNotEmpty) unawaited(_drainPlayback());
    }
  }

  Future<void> _startMic() async {
    _recorder = AudioRecorder();
    if (!await _recorder!.hasPermission()) {
      error.value = 'Microphone permission required';
      return;
    }
    const cfg = RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1);
    final stream = await _recorder!.startStream(cfg);
    _micSub = stream.listen((chunk) {
      if (_ch == null || chunk.isEmpty) return;
      _ch!.sink.add(chunk);
    });
  }

  Future<void> hangup() async {
    try {
      _ch?.sink.add('{"type":"hangup"}');
    } catch (_) {}
    await disconnect();
  }

  Future<void> disconnect() async {
    ready.value = false;
    connected.value = false;
    _playQueue.clear();
    await _wsSub?.cancel();
    _wsSub = null;
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    await _recorder?.dispose();
    _recorder = null;
    await _player.stop();
    await _ch?.sink.close();
    _ch = null;
  }

  void dispose() {
    unawaited(disconnect());
    _player.dispose();
    connected.dispose();
    ready.dispose();
    error.dispose();
    usage.dispose();
  }
}
