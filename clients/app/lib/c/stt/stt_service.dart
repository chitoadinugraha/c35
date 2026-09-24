import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SttService {
  SttService._();

  static final SttService instance = SttService._();

  VoiceApi? _voiceApi;

  void bindVoiceApi(VoiceApi? api) => _voiceApi = api;

  @visibleForTesting
  static String sttEngineRoute(String engine) {
    if (engine == 'cloud') return 'cloud';
    if (engine == 'local') return 'local';
    return 'web';
  }

  static const maxRecordingSeconds = 30;

  AudioRecorder? _recorder;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _recordSecondTimer;
  String? _recordingMime;
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> isTranscribing = ValueNotifier(false);
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  final ValueNotifier<double> audioAmplitude = ValueNotifier(0.0);
  final ValueNotifier<List<double>> amplitudeHistory = ValueNotifier(const []);
  final ValueNotifier<String> liveTranscript = ValueNotifier('');
  String? lastStartError;
  String? lastTranscribeError;
  VoidCallback? onAutoStop;

  static String sanitizeTranscript(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t == '00:00' || t == '0:00' || t.startsWith('00:00')) return '';
    final lower = t.toLowerCase();
    if (lower == '[silence]' || lower == '(silence)' || lower == 'silence' || lower == 'no speech') return '';
    if (RegExp(r'^\d{1,2}:\d{2}(?:\s*[-–—]\s*\d{1,2}:\d{2})?$').hasMatch(t)) return '';
    return t;
  }

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

  void _startRecordingTimers() {
    _stopTimers();
    _recordSecondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRecording.value) return;
      recordingSeconds.value++;
      if (recordingSeconds.value >= maxRecordingSeconds) {
        _stopTimers();
        onAutoStop?.call();
      }
    });
  }

  Future<bool> startRecording() async {
    lastStartError = null;
    if (isRecording.value) return true;

    await _init();
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
          audioAmplitude.value = 0.05;
          amplitudeHistory.value = const [];
          liveTranscript.value = '';
          _stopTimers();

          var speechDetected = false;
          DateTime? silenceSince;
          final history = <double>[];

          _startRecordingTimers();

          _ampSub = _recorder!.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((amp) {
            if (!isRecording.value) return;
            final current = amp.current;
            final maxAmp = amp.max;
            final level = current > maxAmp ? current : maxAmp;

            var norm = 0.0;
            if (level > -55 && level != -160) {
              final linear = ((level + 50) / 40).clamp(0.0, 1.0);
              norm = pow(linear, 2.4).toDouble();
            }

            audioAmplitude.value = norm;
            history.add(norm);
            if (history.length > 80) history.removeAt(0);
            amplitudeHistory.value = List.of(history);

            if (level > -38.0 || norm >= 0.35) {
              speechDetected = true;
              silenceSince = null;
            } else if (speechDetected && recordingSeconds.value >= 1) {
              silenceSince ??= DateTime.now();
              if (DateTime.now().difference(silenceSince!) >= const Duration(milliseconds: 2200)) {
                _stopTimers();
                onAutoStop?.call();
              }
            }
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
      _stopTimers();
      isRecording.value = false;
      return false;
    }
  }

  void _stopTimers() {
    _recordSecondTimer?.cancel();
    _recordSecondTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
    audioAmplitude.value = 0.0;
  }

  Future<String?> stopAndTranscribe({String? lang}) async {
    _stopTimers();
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
      final trimmed = transcript?.trim();
      final clean = (trimmed != null) ? sanitizeTranscript(trimmed) : null;
      if (clean != null && clean.isNotEmpty) {
        liveTranscript.value = clean;
        return clean;
      }
      lastTranscribeError = 'No speech detected';
      return null;
    } catch (e) {
      lastTranscribeError = uiFriendlyError(e, fallback: 'Speech recognition failed. Please try again.');
      debugPrint('[SttService] Transcription error: $e');
      return null;
    } finally {
      isTranscribing.value = false;
      try { await file.delete(); } catch (_) {}
    }
  }

  Future<void> cancel() async {
    _stopTimers();
    recordingSeconds.value = 0;
    amplitudeHistory.value = const [];
    liveTranscript.value = '';
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
    if (route == 'web') {
      if (webTranscribe != null) {
        final res = await webTranscribe(bytes, lang, mime);
        return res != null ? sanitizeTranscript(res) : null;
      }
      return null;
    }
    if (route == 'cloud') {
      if (_voiceApi == null) {
        debugPrint('[SttService] cloud STT requires VoiceApi (bind from page_ai_home)');
        if (bytes.isNotEmpty) {
          final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime);
          if (direct != null && direct.isNotEmpty) return sanitizeTranscript(direct);
        }
        return null;
      }
      try {
        lastTranscribeError = null;
        final res = await _voiceApi!.sttTranscribe(audio: bytes, mime: mime, lang: lang);
        if (res != null && res.isNotEmpty) {
          final clean = sanitizeTranscript(res);
          if (clean.isNotEmpty) return clean;
        }
      } catch (e) {
        debugPrint('[SttService] cloud STT error: $e, falling back to direct Gemini 3.1 Flash Lite');
        if (bytes.isNotEmpty) {
          final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime);
          if (direct != null && direct.isNotEmpty) return sanitizeTranscript(direct);
        }
        return null;
      }
    }
    if (webTranscribe != null) {
      final res = await webTranscribe(bytes, lang, mime);
      return res != null ? sanitizeTranscript(res) : null;
    }
    if (bytes.isNotEmpty) {
      final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime);
      if (direct != null && direct.isNotEmpty) return sanitizeTranscript(direct);
    }
    return null;
  }

  Future<String?> _transcribeGeminiDirect({
    required Uint8List bytes,
    required String lang,
    required String mime,
  }) async {
    try {
      final key = Platform.environment['GEMINI_API_KEY'] ??
          Platform.environment['GOOGLE_API_KEY'];
      if (key == null || key.isEmpty) return null;
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=$key');
      final prompt = lang.startsWith('id')
          ? 'Transkripsikan pesan suara ini dengan akurat dalam Bahasa Indonesia atau bahasa yang digunakan penutur. Balas hanya dengan kata-kata yang diucapkan, tanpa tanda kutip atau komentar. PENTING: Jika tidak ada ucapan manusia yang jelas atau hanya ada hening/suara latar, jangan kembalikan apapun (balas teks kosong). Jangan berikan penanda waktu atau timestamp seperti 00:00.'
          : 'Transcribe the spoken audio verbatim. Reply with only the spoken words. If no speech is heard or if there is only silence, noise, or breathing, return an empty string. Never return timestamps (such as 00:00), duration markers, explanations, or commentary.';

      final client = HttpClient();
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': mime.isNotEmpty ? mime : 'audio/wav',
                  'data': base64Encode(bytes),
                }
              },
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1024,
        }
      }));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final body = await utf8.decodeStream(res);
      final json = jsonDecode(body);
      if (json is! Map || !json.containsKey('candidates')) return null;
      final candidates = json['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final first = candidates.first;
      if (first is! Map || !first.containsKey('content')) return null;
      final parts = first['content']?['parts'];
      if (parts is! List || parts.isEmpty) return null;
      final text = parts.first['text']?.toString().trim();
      final clean = (text != null) ? sanitizeTranscript(text) : '';
      return clean.isNotEmpty ? clean : null;
    } catch (e) {
      debugPrint('[SttService] Gemini direct STT error: $e');
      return null;
    }
  }
}
