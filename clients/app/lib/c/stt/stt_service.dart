import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SttService {
  SttService._();

  static final SttService instance = SttService._();

  AudioRecorder? _recorder;
  Timer? _recordTimer;
  String? _recordingMime;
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> isTranscribing = ValueNotifier(false);
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  String? lastStartError;

  Future<void> _init() async => _recorder ??= AudioRecorder();

  Future<bool> hasPermission() async {
    await _init();
    if (!kIsWeb && !await sttMicPermissionGranted()) return false;
    try {
      return await _recorder!.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<({RecordConfig config, String ext, String mime})> _recordingFormat() async {
    await _init();
    final supports = _recorder!.isEncoderSupported;
    if (await supports(AudioEncoder.opus)) {
      return (config: const RecordConfig(encoder: AudioEncoder.opus, bitRate: 32000, sampleRate: 48000, numChannels: 1), ext: 'ogg', mime: 'audio/ogg');
    }
    if (!kIsWeb && Platform.isWindows) {
      if (await supports(AudioEncoder.aacLc)) {
        return (config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100, numChannels: 1), ext: 'm4a', mime: 'audio/mp4');
      }
      if (await supports(AudioEncoder.flac)) {
        return (config: const RecordConfig(encoder: AudioEncoder.flac, bitRate: 128000, sampleRate: 44100, numChannels: 1), ext: 'flac', mime: 'audio/flac');
      }
      return (config: const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, numChannels: 1), ext: 'wav', mime: 'audio/wav');
    }
    return (config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 16000, numChannels: 1), ext: 'm4a', mime: 'audio/mp4');
  }

  Future<bool> startRecording() async {
    await _init();
    lastStartError = null;
    if (isRecording.value) return true;
    try {
      if (!kIsWeb && !await sttMicPermissionEnsure()) {
        lastStartError = sttMicErrorMessage();
        return false;
      }
      if (!await _recorder!.hasPermission()) {
        lastStartError = sttMicErrorMessage();
        return false;
      }
      final fmt = await _recordingFormat();
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/stt_input_${DateTime.now().millisecondsSinceEpoch}.${fmt.ext}';
      _recordingMime = fmt.mime;
      await _recorder!.start(fmt.config, path: path);
      recordingSeconds.value = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) => recordingSeconds.value++);
      isRecording.value = true;
      return true;
    } catch (e) {
      debugPrint('[SttService] startRecording failed: $e');
      lastStartError = sttMicErrorMessage(cause: e);
      _recordingMime = null;
      _stopTimer();
      isRecording.value = false;
      return false;
    }
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    recordingSeconds.value = 0;
  }

  Future<String?> stopAndTranscribe({String? lang}) async {
    _stopTimer();
    if (!isRecording.value && _recorder == null) return null;
    String? path;
    try {
      path = await _recorder!.stop();
    } catch (e) {
      debugPrint('[SttService] stop error: $e');
    } finally {
      isRecording.value = false;
    }
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      try { await file.delete(); } catch (_) {}
      return null;
    }
    isTranscribing.value = true;
    final mime = _recordingMime ?? 'audio/mp4';
    _recordingMime = null;
    try {
      final pref = lang ?? VoicePrefs.instance.speechLang;
      final effectiveLang = speechLangSttLocale(pref, last: VoicePrefs.instance.lastLang);
      final transcript = await _transcribeWebEndpoint(bytes, effectiveLang, mime);
      return transcript?.trim();
    } catch (e) {
      debugPrint('[SttService] Transcription error: $e');
      return null;
    } finally {
      isTranscribing.value = false;
      try { await file.delete(); } catch (_) {}
    }
  }

  Future<void> cancel() async {
    _stopTimer();
    if (_recorder != null && isRecording.value) {
      try {
        final path = await _recorder!.stop();
        if (path != null) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      } catch (_) {}
    }
    isRecording.value = false;
    isTranscribing.value = false;
    _recordingMime = null;
  }

  Future<String?> _transcribeWebEndpoint(Uint8List bytes, String lang, String mime) async {
    try {
      final url = Uri.parse('https://www.google.com/speech-api/v2/recognize?output=json&lang=$lang&client=chromium');
      final res = await http.post(url, headers: {
        'Content-Type': mime,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
      }, body: bytes).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      for (final line in res.body.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          if (json is! Map || !json.containsKey('result')) continue;
          final result = json['result'];
          if (result is! List || result.isEmpty) continue;
          final first = result.first;
          if (first is! Map || !first.containsKey('alternative')) continue;
          final alt = first['alternative'];
          if (alt is! List || alt.isEmpty) continue;
          final text = alt.first['transcript']?.toString();
          if (text != null && text.isNotEmpty) return text;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[SttService] _transcribeWebEndpoint error: $e');
    }
    return null;
  }
}
