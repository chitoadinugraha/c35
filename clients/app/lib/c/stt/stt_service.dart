import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SttService {
  SttService._();

  static final SttService instance = SttService._();

  VoiceApi? _voiceApi;

  void bindVoiceApi(VoiceApi? api) => _voiceApi = api;

  @visibleForTesting
  static String sttEngineRoute(String engine) => engine == 'cloud' ? 'cloud' : 'web';

  AudioRecorder? _recorder;
  Timer? _recordTimer;
  String? _recordingMime;
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> isTranscribing = ValueNotifier(false);
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  final ValueNotifier<double> audioAmplitude = ValueNotifier(0.0);
  String? lastStartError;
  String? lastTranscribeError;

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

  Future<List<({RecordConfig config, String ext, String mime})>> _recordingFormats() async {
    await _init();
    final supports = _recorder!.isEncoderSupported;
    final formats = <({RecordConfig config, String ext, String mime})>[];
    if (!kIsWeb && Platform.isWindows) {
      formats.add((config: const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), ext: 'wav', mime: 'audio/wav'));
      if (await supports(AudioEncoder.aacLc)) {
        formats.add((config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100, numChannels: 1), ext: 'm4a', mime: 'audio/mp4'));
      }
      if (await supports(AudioEncoder.flac)) {
        formats.add((config: const RecordConfig(encoder: AudioEncoder.flac, bitRate: 128000, sampleRate: 44100, numChannels: 1), ext: 'flac', mime: 'audio/flac'));
      }
      return formats;
    }
    if (await supports(AudioEncoder.opus)) {
      formats.add((config: const RecordConfig(encoder: AudioEncoder.opus, bitRate: 32000, sampleRate: 48000, numChannels: 1), ext: 'ogg', mime: 'audio/ogg'));
    }
    formats.add((config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 16000, numChannels: 1), ext: 'm4a', mime: 'audio/mp4'));
    if (await supports(AudioEncoder.wav)) {
      formats.add((config: const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), ext: 'wav', mime: 'audio/wav'));
    }
    return formats;
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
      final formats = await _recordingFormats();
      final tempDir = await getTemporaryDirectory();
      Object? lastError;
      for (final fmt in formats) {
        final path = '${tempDir.path}/stt_input_${DateTime.now().millisecondsSinceEpoch}.${fmt.ext}';
        try {
          _recordingMime = fmt.mime;
          await _recorder!.start(fmt.config, path: path);
          recordingSeconds.value = 0;
          audioAmplitude.value = 0.0;
          _recordTimer?.cancel();
          var tick = 0;
          _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
            tick++;
            if (tick % 10 == 0) recordingSeconds.value++;
            try {
              final amp = await _recorder?.getAmplitude();
              if (amp != null) {
                final norm = ((amp.current + 50) / 50).clamp(0.0, 1.0);
                audioAmplitude.value = norm;
              }
            } catch (_) {}
          });
          isRecording.value = true;
          return true;
        } catch (e) {
          lastError = e;
          _recordingMime = null;
          debugPrint('[SttService] start ${fmt.ext} failed: $e');
        }
      }
      throw lastError ?? StateError('No supported recording format');
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
    audioAmplitude.value = 0.0;
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
    lastTranscribeError = null;
    final mime = _recordingMime ?? 'audio/mp4';
    _recordingMime = null;
    try {
      final pref = lang ?? VoicePrefs.instance.speechLang;
      final effectiveLang = speechLangSttLocale(pref, last: VoicePrefs.instance.lastLang);
      final transcript = await transcribeRouted(bytes: bytes, lang: effectiveLang, mime: mime);
      return transcript?.trim();
    } catch (e) {
      lastTranscribeError = uiFriendlyError(e, fallback: 'Cloud speech recognition failed. Please try again.');
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

  @visibleForTesting
  Future<String?> transcribeRouted({
    required Uint8List bytes,
    required String lang,
    required String mime,
    Future<String?> Function(Uint8List bytes, String lang, String mime)? webTranscribe,
  }) async {
    final route = sttEngineRoute(VoicePrefs.instance.sttEngine);
    if (route == 'cloud') {
      if (_voiceApi == null) {
        debugPrint('[SttService] cloud STT requires VoiceApi (bind from page_ai_home)');
        return null;
      }
      try {
        lastTranscribeError = null;
        return await _voiceApi!.sttTranscribe(audio: bytes, mime: mime, lang: lang);
      } catch (e) {
        lastTranscribeError = uiFriendlyError(e, fallback: 'Cloud speech recognition failed. Please try again.');
        debugPrint('[SttService] cloud STT error: $e');
        return null;
      }
    }
    return await (webTranscribe ?? _transcribeWebEndpoint)(bytes, lang, mime);
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
