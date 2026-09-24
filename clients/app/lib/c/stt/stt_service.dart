import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:ulid/ulid.dart';

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
  StreamSubscription<Uint8List>? _streamSub;
  Timer? _recordSecondTimer;
  Timer? _interimTimer;
  String? _recordingMime;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  bool _isStreamingPcm = false;
  bool _interimInFlight = false;
  bool _speechDetected = false;
  DateTime? _silenceSince;
  DateTime? _recordingStartedAt;
  String _sessionReqId = '';

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

  /// Converts raw 16-bit linear PCM byte buffer into a valid 16-bit WAV file buffer.
  static Uint8List pcmToWav(Uint8List pcm, {int sampleRate = 16000, int channels = 1}) {
    final totalDataLen = pcm.length;
    final totalFileLen = totalDataLen + 36;
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;
    final header = ByteData(44);

    // "RIFF"
    header.setUint8(0, 0x52);
    header.setUint8(1, 0x49);
    header.setUint8(2, 0x46);
    header.setUint8(3, 0x46);
    header.setUint32(4, totalFileLen, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57);
    header.setUint8(9, 0x41);
    header.setUint8(10, 0x56);
    header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66);
    header.setUint8(13, 0x6d);
    header.setUint8(14, 0x74);
    header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // BitsPerSample
    // "data"
    header.setUint8(36, 0x64);
    header.setUint8(37, 0x61);
    header.setUint8(38, 0x74);
    header.setUint8(39, 0x61);
    header.setUint32(40, totalDataLen, Endian.little);

    final wav = Uint8List(44 + totalDataLen);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + totalDataLen, pcm);
    return wav;
  }

  /// Calculates peak amplitude (0.0 - 1.0) and dB level from 16-bit linear PCM chunk.
  static ({double norm, double levelDb}) pcmAmplitude(Uint8List chunk) {
    if (chunk.isEmpty) return (norm: 0.0, levelDb: -100.0);
    var peak = 0;
    for (var i = 0; i < chunk.length - 1; i += 2) {
      var sample = chunk[i] | (chunk[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      final val = sample.abs();
      if (val > peak) peak = val;
    }
    final norm = (peak / 32768.0).clamp(0.0, 1.0);
    final levelDb = norm > 0 ? (20 * log(norm) / ln10) : -100.0;
    return (norm: norm, levelDb: levelDb);
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
      formats.add((
        config: const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        ext: 'wav',
        mime: 'audio/wav',
      ));
      if (await supports(AudioEncoder.aacLc)) {
        formats.add((
          config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100, numChannels: 1),
          ext: 'm4a',
          mime: 'audio/mp4',
        ));
      }
      if (await supports(AudioEncoder.flac)) {
        formats.add((
          config: const RecordConfig(encoder: AudioEncoder.flac, bitRate: 128000, sampleRate: 44100, numChannels: 1),
          ext: 'flac',
          mime: 'audio/flac',
        ));
      }
      return formats;
    }
    if (await supports(AudioEncoder.opus)) {
      formats.add((
        config: const RecordConfig(encoder: AudioEncoder.opus, bitRate: 32000, sampleRate: 48000, numChannels: 1),
        ext: 'ogg',
        mime: 'audio/ogg',
      ));
    }
    formats.add((
      config: const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 16000, numChannels: 1),
      ext: 'm4a',
      mime: 'audio/mp4',
    ));
    if (await supports(AudioEncoder.wav)) {
      formats.add((
        config: const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        ext: 'wav',
        mime: 'audio/wav',
      ));
    }
    return formats;
  }

  void _startRecordingTimers() {
    _recordSecondTimer?.cancel();
    _recordSecondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRecording.value) return;
      recordingSeconds.value++;
      if (recordingSeconds.value >= maxRecordingSeconds) {
        _stopTimers();
        onAutoStop?.call();
      }
    });
  }

  void _startInterimTranscribeLoop() {
    _interimTimer?.cancel();
    _interimTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
      if (!isRecording.value || !_isStreamingPcm || _interimInFlight || !_speechDetected) return;
      final currentPcm = _pcmBuffer.toBytes();
      // Require at least 0.8s of audio: 16,000 samples * 2 bytes = 32,000 bytes/s -> ~25,600 bytes
      if (currentPcm.length < 25600) return;
      _interimInFlight = true;
      try {
        final wav = pcmToWav(currentPcm, sampleRate: 16000, channels: 1);
        final pref = VoicePrefs.instance.speechLang;
        final effectiveLang = speechLangSttLocale(pref, last: VoicePrefs.instance.lastLang);
        final partial = await transcribeRouted(
          bytes: wav,
          lang: effectiveLang,
          mime: 'audio/wav',
          isInterim: true,
          reqId: 'interim_${_sessionReqId}_${recordingSeconds.value}',
        );
        if (partial != null && partial.isNotEmpty && isRecording.value) {
          liveTranscript.value = partial;
        }
      } catch (e) {
        debugPrint('[SttService] interim transcribe: $e');
      } finally {
        _interimInFlight = false;
      }
    });
  }

  void _onAudioLevel(double level, double norm, List<double> history) {
    audioAmplitude.value = norm;
    history.add(norm);
    if (history.length > 80) history.removeAt(0);
    amplitudeHistory.value = List.of(history);

    // Natural voice activity detection thresholds
    // Standard conversational speech into mics typically ranges between -48 dB and -30 dB.
    const speechDbThreshold = -48.0;
    const speechNormThreshold = 0.10;
    const silenceTimeoutMs = 1100;
    const initialSilenceTimeoutMs = 4500;

    if (level > speechDbThreshold || norm >= speechNormThreshold) {
      _speechDetected = true;
      _silenceSince = null;
    } else if (_speechDetected) {
      _silenceSince ??= DateTime.now();
      if (DateTime.now().difference(_silenceSince!).inMilliseconds >= silenceTimeoutMs) {
        _stopTimers();
        onAutoStop?.call();
      }
    } else if (_recordingStartedAt != null) {
      // If user started recording but no speech was detected after 4.5 seconds
      if (DateTime.now().difference(_recordingStartedAt!).inMilliseconds >= initialSilenceTimeoutMs) {
        _stopTimers();
        onAutoStop?.call();
      }
    }
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

      recordingSeconds.value = 0;
      audioAmplitude.value = 0.05;
      amplitudeHistory.value = const [];
      liveTranscript.value = '';
      _speechDetected = false;
      _silenceSince = null;
      _interimInFlight = false;
      _sessionReqId = Ulid().toString();
      _recordingStartedAt = DateTime.now();
      _stopTimers();

      // Try streaming PCM first (low latency, continuous interim snapshots, no file locks)
      try {
        const pcmConfig = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );
        final stream = await _recorder!.startStream(pcmConfig);
        _isStreamingPcm = true;
        _recordingMime = 'audio/wav';
        _pcmBuffer.clear();

        final history = <double>[];
        _streamSub = stream.listen((chunk) {
          if (!isRecording.value) return;
          _pcmBuffer.add(chunk);
          final amp = pcmAmplitude(chunk);
          _onAudioLevel(amp.levelDb, amp.norm, history);
        });

        _startRecordingTimers();
        _startInterimTranscribeLoop();
        isRecording.value = true;
        return true;
      } catch (streamErr) {
        debugPrint('[SttService] startStream not available ($streamErr), falling back to file recording');
        _isStreamingPcm = false;
      }

      // Fallback: file recording
      final formats = await _recordingFormats();
      final tempDir = await getTemporaryDirectory();
      Object? lastError;
      for (final fmt in formats) {
        final path = '${tempDir.path}/stt_input_${DateTime.now().millisecondsSinceEpoch}.${fmt.ext}';
        try {
          _recordingMime = fmt.mime;
          await _recorder!.start(fmt.config, path: path);

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

            _onAudioLevel(level, norm, history);
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
    _interimTimer?.cancel();
    _interimTimer = null;
    _ampSub?.cancel();
    _ampSub = null;
    _streamSub?.cancel();
    _streamSub = null;
    audioAmplitude.value = 0.0;
  }

  Future<String?> stopAndTranscribe({String? lang}) async {
    _stopTimers();
    if (!isRecording.value && _recorder == null && _pcmBuffer.isEmpty) return null;
    isRecording.value = false;

    Uint8List? audioBytes;
    String mime = _recordingMime ?? 'audio/wav';
    _recordingMime = null;

    if (_isStreamingPcm) {
      final pcm = _pcmBuffer.toBytes();
      _pcmBuffer.clear();
      _isStreamingPcm = false;
      try {
        await _recorder?.stop();
      } catch (_) {}
      if (pcm.isNotEmpty) {
        audioBytes = pcmToWav(pcm, sampleRate: 16000, channels: 1);
        mime = 'audio/wav';
      }
    } else {
      String? path;
      try {
        path = await _recorder?.stop();
      } catch (e) {
        debugPrint('[SttService] stop error: $e');
      }
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final b = await file.readAsBytes();
          try {
            await file.delete();
          } catch (_) {}
          if (b.isNotEmpty) audioBytes = b;
        }
      }
    }

    if (audioBytes == null || audioBytes.isEmpty) {
      if (liveTranscript.value.isNotEmpty) return liveTranscript.value;
      return null;
    }

    isTranscribing.value = true;
    lastTranscribeError = null;

    try {
      final pref = lang ?? VoicePrefs.instance.speechLang;
      final effectiveLang = speechLangSttLocale(pref, last: VoicePrefs.instance.lastLang);
      final transcript = await transcribeRouted(
        bytes: audioBytes,
        lang: effectiveLang,
        mime: mime,
        isInterim: false,
        reqId: 'final_$_sessionReqId',
      );
      final trimmed = transcript?.trim();
      final clean = (trimmed != null) ? sanitizeTranscript(trimmed) : null;
      if (clean != null && clean.isNotEmpty) {
        liveTranscript.value = clean;
        return clean;
      }
      if (liveTranscript.value.isNotEmpty) {
        return liveTranscript.value;
      }
      lastTranscribeError = 'No speech detected';
      return null;
    } catch (e) {
      if (liveTranscript.value.isNotEmpty) {
        return liveTranscript.value;
      }
      lastTranscribeError = uiFriendlyError(e, fallback: 'Speech recognition failed. Please try again.');
      debugPrint('[SttService] Transcription error: $e');
      return null;
    } finally {
      isTranscribing.value = false;
    }
  }

  Future<void> cancel() async {
    _stopTimers();
    recordingSeconds.value = 0;
    amplitudeHistory.value = const [];
    liveTranscript.value = '';
    _pcmBuffer.clear();
    _isStreamingPcm = false;
    _speechDetected = false;
    _silenceSince = null;
    _recordingStartedAt = null;

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
    bool isInterim = false,
    String? reqId,
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
          final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime, isInterim: isInterim);
          if (direct != null && direct.isNotEmpty) return sanitizeTranscript(direct);
        }
        return null;
      }
      try {
        lastTranscribeError = null;
        final res = await _voiceApi!.sttTranscribe(audio: bytes, mime: mime, lang: lang, reqId: reqId);
        if (res != null && res.isNotEmpty) {
          final clean = sanitizeTranscript(res);
          if (clean.isNotEmpty) return clean;
        }
      } catch (e) {
        debugPrint('[SttService] cloud STT error: $e, falling back to direct Gemini 3.1 Flash Lite');
        if (bytes.isNotEmpty) {
          final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime, isInterim: isInterim);
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
      final direct = await _transcribeGeminiDirect(bytes: bytes, lang: lang, mime: mime, isInterim: isInterim);
      if (direct != null && direct.isNotEmpty) return sanitizeTranscript(direct);
    }
    return null;
  }

  Future<String?> _transcribeGeminiDirect({
    required Uint8List bytes,
    required String lang,
    required String mime,
    bool isInterim = false,
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
      final timeoutDuration = isInterim ? const Duration(seconds: 4) : const Duration(seconds: 15);
      final res = await req.close().timeout(timeoutDuration);
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
