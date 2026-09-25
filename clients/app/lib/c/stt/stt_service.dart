import 'dart:async';
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
  static String sttEngineRoute(String engine) => 'cloud';


  static const maxRecordingSeconds = 30;

  AudioRecorder? _recorder;
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<Uint8List>? _streamSub;
  Timer? _recordSecondTimer;
  Timer? _interimTimer;
  bool _interimInFlight = false;
  int _interimCounter = 0;
  String? _recordingMime;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);
  bool _isStreamingPcm = false;
  bool _speechDetected = false;
  DateTime? _silenceSince;
  DateTime? _recordingStartedAt;
  String _sessionReqId = '';
  double? _noiseFloorDb;
  int _consecutiveSpeechFrames = 0;

  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> isTranscribing = ValueNotifier(false);
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  final ValueNotifier<double> audioAmplitude = ValueNotifier(0.0);
  final ValueNotifier<List<double>> amplitudeHistory = ValueNotifier(const []);
  final ValueNotifier<String> liveTranscript = ValueNotifier('');
  String? lastStartError;
  String? lastTranscribeError;
  VoidCallback? onAutoStop;

  int _streamSampleRate = 16000;
  int _streamChannels = 1;

  static String sanitizeTranscript(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t.contains('[NO_SPEECH]') || t.contains('NO_SPEECH')) return '';
    if (t == '00:00' || t == '0:00' || t.startsWith('00:00')) return '';
    final lower = t.toLowerCase();
    if (lower == '[silence]' || lower == '(silence)' || lower == 'silence' || lower == 'no speech') return '';
    if (lower == 'thank you.' ||
        lower == 'thank you' ||
        lower == 'thank you!' ||
        lower == 'thanks for watching.' ||
        lower == 'thanks for watching' ||
        lower == 'thank you for watching.' ||
        lower == 'you' ||
        lower == 'you.' ||
        lower == 'bye.' ||
        lower == 'bye') {
      return '';
    }
    if (lower.startsWith('subtitles by') || lower.startsWith('subtitle by')) return '';
    if (RegExp(r'^\d{1,2}:\d{2}(?:\s*[-–—]\s*\d{1,2}:\d{2})?$').hasMatch(t)) return '';
    if (RegExp(r'^[\d\s:\-–—]+$').hasMatch(t)) return '';
    return t;
  }

  /// Downsamples 16-bit linear PCM from any sample rate / channel count to 16kHz mono.
  static Uint8List resampleTo16kMono(Uint8List pcm, {required int srcRate, required int srcChannels}) {
    if (pcm.isEmpty) return pcm;
    if (srcRate == 16000 && srcChannels == 1) return pcm;

    final bytesPerSrcSample = 2;
    final bytesPerSrcFrame = srcChannels * bytesPerSrcSample;
    final totalSrcFrames = pcm.length ~/ bytesPerSrcFrame;
    if (totalSrcFrames == 0) return Uint8List(0);

    final totalDstFrames = (totalSrcFrames * 16000) ~/ srcRate;
    if (totalDstFrames == 0) return Uint8List(0);

    final dst = Uint8List(totalDstFrames * 2);
    final dstData = ByteData.sublistView(dst);
    final srcData = ByteData.sublistView(pcm);

    final step = srcRate / 16000.0;
    for (var i = 0; i < totalDstFrames; i++) {
      final srcFrameIdx = (i * step).toInt().clamp(0, totalSrcFrames - 1);
      final byteOffset = srcFrameIdx * bytesPerSrcFrame;

      var monoSample = 0;
      if (srcChannels == 1) {
        monoSample = srcData.getInt16(byteOffset, Endian.little);
      } else {
        final left = srcData.getInt16(byteOffset, Endian.little);
        final right = srcData.getInt16(byteOffset + 2, Endian.little);
        monoSample = (left + right) ~/ 2;
      }
      dstData.setInt16(i * 2, monoSample, Endian.little);
    }
    return dst;
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

  /// Calculates peak amplitude (0.0 - 1.0) and dB level (from RMS) from 16-bit linear PCM chunk.
  static ({double norm, double levelDb}) pcmAmplitude(Uint8List chunk) {
    if (chunk.isEmpty) return (norm: 0.0, levelDb: -100.0);
    var peak = 0;
    var sumSq = 0.0;
    var count = 0;
    for (var i = 0; i < chunk.length - 1; i += 2) {
      var sample = chunk[i] | (chunk[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      final val = sample.abs();
      if (val > peak) peak = val;
      sumSq += (sample / 32768.0) * (sample / 32768.0);
      count++;
    }
    final norm = (peak / 32768.0).clamp(0.0, 1.0);
    final rms = count > 0 ? sqrt(sumSq / count) : 0.0;
    final levelDb = rms > 1e-5 ? (20 * log(rms) / ln10) : -100.0;
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

  /// Lists available audio input devices (microphones).
  Future<List<InputDevice>> listInputDevices() async {
    await _init();
    try {
      return await _recorder!.listInputDevices();
    } catch (e) {
      debugPrint('[SttService] listInputDevices error: $e');
      return const [];
    }
  }

  /// Queries the Windows registry to find the GUID of the actual Windows default
  /// recording endpoint (eConsole / Role 0, the one with the green checkmark).
  static Future<String?> _detectWindowsDefaultCaptureDeviceGuid() async {
    if (kIsWeb || !Platform.isWindows) return null;
    try {
      final regCmd = File(r'C:\Windows\System32\reg.exe').existsSync() ? r'C:\Windows\System32\reg.exe' : 'reg';
      final res = await Process.run(regCmd, [
        'query',
        r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture',
        '/s',
        '/v',
        'Level:0',
      ]);
      if (res.exitCode != 0) return null;
      final out = res.stdout as String;
      final lines = out.split(RegExp(r'[\r\n]+'));
      String? currentGuid;
      int maxLevel = -1;
      String? bestGuid;
      for (final line in lines) {
        final keyMatch = RegExp(r'Capture\\\{([0-9a-fA-F-]+)\}').firstMatch(line);
        if (keyMatch != null) {
          currentGuid = keyMatch.group(1);
          continue;
        }
        if (currentGuid != null && line.contains('Level:0')) {
          final valMatch = RegExp(r'0x([0-9a-fA-F]+)').firstMatch(line);
          if (valMatch != null) {
            final level = int.tryParse(valMatch.group(1)!, radix: 16) ?? -1;
            if (level > maxLevel) {
              maxLevel = level;
              bestGuid = currentGuid;
            }
          }
        }
      }
      return bestGuid?.toLowerCase();
    } catch (e) {
      debugPrint('[SttService] error detecting Windows default microphone: $e');
      return null;
    }
  }

  /// Resolves the active input device.
  /// If the user selected a specific device in VoicePrefs, uses that.
  /// Otherwise, discovers the true Windows Default recording device (eConsole / Role 0).
  Future<InputDevice?> resolveActiveMicDevice() async {
    final devices = await listInputDevices();
    if (devices.isEmpty) return null;

    final savedId = VoicePrefs.instance.micDeviceId.trim();
    if (savedId.isNotEmpty && savedId != 'default') {
      final match = devices.where((d) => d.id == savedId).firstOrNull;
      if (match != null) return match;
    }

    // 1. On Windows, locate the actual Windows Default recording device (eConsole / Role 0)
    if (!kIsWeb && Platform.isWindows) {
      final defaultGuid = await _detectWindowsDefaultCaptureDeviceGuid();
      if (defaultGuid != null && defaultGuid.isNotEmpty) {
        final winDefault = devices.where((d) => d.id.toLowerCase().contains(defaultGuid)).firstOrNull;
        if (winDefault != null) {
          debugPrint('[SttService] Using Windows default microphone: "${winDefault.label}" (id: ${winDefault.id})');
          return winDefault;
        }
      }
    }

    // 2. Fallback: pick the first non-virtual device
    InputDevice? best;
    for (final d in devices) {
      final lower = d.label.toLowerCase();
      final isVirtual = lower.contains('droidcam') ||
          lower.contains('virtual') ||
          lower.contains('cable') ||
          lower.contains('stereo mix');
      if (!isVirtual) {
        best = d;
        break;
      }
    }
    return best ?? devices.first;
  }

  Future<List<({RecordConfig config, String ext, String mime})>> _recordingFormats([InputDevice? device]) async {
    await _init();
    final supports = _recorder!.isEncoderSupported;
    final formats = <({RecordConfig config, String ext, String mime})>[];
    if (!kIsWeb && Platform.isWindows) {
      formats.add((
        config: RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
          device: device,
        ),
        ext: 'wav',
        mime: 'audio/wav',
      ));
      formats.add((
        config: RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 705600,
          device: device,
        ),
        ext: 'wav',
        mime: 'audio/wav',
      ));
      if (await supports(AudioEncoder.aacLc)) {
        formats.add((
          config: RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 44100,
            numChannels: 1,
            device: device,
          ),
          ext: 'm4a',
          mime: 'audio/mp4',
        ));
      }
      if (await supports(AudioEncoder.flac)) {
        formats.add((
          config: RecordConfig(
            encoder: AudioEncoder.flac,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1,
            device: device,
          ),
          ext: 'flac',
          mime: 'audio/flac',
        ));
      }
      return formats;
    }
    if (await supports(AudioEncoder.opus)) {
      formats.add((
        config: RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 32000,
          sampleRate: 48000,
          numChannels: 1,
          device: device,
        ),
        ext: 'ogg',
        mime: 'audio/ogg',
      ));
    }
    formats.add((
      config: RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
        device: device,
      ),
      ext: 'm4a',
      mime: 'audio/mp4',
    ));
    if (await supports(AudioEncoder.wav)) {
      formats.add((
        config: RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
          device: device,
        ),
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

    if (_isStreamingPcm) {
      _interimTimer?.cancel();
      _interimCounter = 0;
      _interimInFlight = false;
      _interimTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) async {
        if (!isRecording.value || !_speechDetected || _interimInFlight) return;
        final rawPcm = _pcmBuffer.toBytes();
        // At least 0.8s of speech audio before triggering interim snapshot
        final minBytes = (_streamSampleRate * _streamChannels * 2 * 0.8).toInt();
        if (rawPcm.length < minBytes) return;

        _interimInFlight = true;
        _interimCounter++;
        final reqId = 'interim_${_sessionReqId}_$_interimCounter';
        try {
          final pcm16k = resampleTo16kMono(rawPcm, srcRate: _streamSampleRate, srcChannels: _streamChannels);
          final wav = pcmToWav(pcm16k, sampleRate: 16000, channels: 1);
          final pref = VoicePrefs.instance.speechLang;
          final effectiveLang = speechLangSttLocale(pref, last: VoicePrefs.instance.lastLang);
          final text = await transcribeRouted(
            bytes: wav,
            lang: effectiveLang,
            mime: 'audio/wav',
            isInterim: true,
            reqId: reqId,
          );
          if (isRecording.value && text != null && text.trim().isNotEmpty) {
            liveTranscript.value = text.trim();
          }
        } catch (e) {
          debugPrint('[SttService] interim transcribe ignored: $e');
        } finally {
          _interimInFlight = false;
        }
      });
    }
  }


  void _onAudioLevel(double level, double norm, List<double> history) {
    audioAmplitude.value = norm;
    history.add(norm);
    if (history.length > 80) history.removeAt(0);
    amplitudeHistory.value = List.of(history);

    // Adaptive noise floor tracking:
    // Noise floor must never adapt into conversational speech range (typically > -46 dB).
    if (level > -90.0) {
      if (_noiseFloorDb == null) {
        _noiseFloorDb = level.clamp(-75.0, -50.0);
      } else if (level < _noiseFloorDb!) {
        // Fast decay down to track lower ambient baseline
        _noiseFloorDb = _noiseFloorDb! * 0.70 + level * 0.30;
      } else if (!_speechDetected && level < -48.0) {
        // Slow rise only when clearly in ambient range
        _noiseFloorDb = _noiseFloorDb! * 0.95 + level * 0.05;
      }
      _noiseFloorDb = _noiseFloorDb!.clamp(-75.0, -48.0);
    }

    final ambientFloor = _noiseFloorDb ?? -55.0;
    // Dynamic speech threshold: +7 dB above ambient floor, minimum -44 dB
    final dynamicSpeechDb = max(ambientFloor + 7.0, -44.0);
    final isSpeechFrame = level > dynamicSpeechDb || norm >= 0.08;

    const silenceTimeoutMs = 1300;
    const initialSilenceTimeoutMs = 4500;

    if (isSpeechFrame) {
      _consecutiveSpeechFrames++;
      // Require at least 2 consecutive speech frames (~150ms) to filter out sporadic clicks/taps
      if (_consecutiveSpeechFrames >= 2) {
        _speechDetected = true;
        _silenceSince = null;
      }
    } else {
      _consecutiveSpeechFrames = 0;
      if (_speechDetected) {
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
      _sessionReqId = Ulid().toString();
      _recordingStartedAt = DateTime.now();
      _noiseFloorDb = null;
      _consecutiveSpeechFrames = 0;
      _stopTimers();

      final activeMic = await resolveActiveMicDevice();
      debugPrint('[SttService] Using microphone: "${activeMic?.label ?? 'system default'}" (id: ${activeMic?.id})');

      // Try streaming PCM first (low latency, continuous interim snapshots, no file locks)
      // On Windows Media Foundation, bitRate MUST match sampleRate * numChannels * 16 bits.
      final candidates = [
        (sampleRate: 48000, numChannels: 2, bitRate: 1536000),
        (sampleRate: 48000, numChannels: 1, bitRate: 768000),
        (sampleRate: 44100, numChannels: 2, bitRate: 1411200),
        (sampleRate: 44100, numChannels: 1, bitRate: 705600),
        (sampleRate: 16000, numChannels: 1, bitRate: 256000),
        (sampleRate: 16000, numChannels: 2, bitRate: 512000),
      ];
      for (final cand in candidates) {
        try {
          final pcmConfig = RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: cand.sampleRate,
            numChannels: cand.numChannels,
            bitRate: cand.bitRate,
            device: activeMic,
          );
          final stream = await _recorder!.startStream(pcmConfig);
          _streamSampleRate = cand.sampleRate;
          _streamChannels = cand.numChannels;
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
          isRecording.value = true;
          return true;
        } catch (streamErr) {
          debugPrint('[SttService] startStream (${cand.sampleRate}Hz) not available: $streamErr');
        }
      }
      _isStreamingPcm = false;

      // Fallback: file recording
      final formats = await _recordingFormats(activeMic);
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
    _interimInFlight = false;
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
        final pcm16k = resampleTo16kMono(pcm, srcRate: _streamSampleRate, srcChannels: _streamChannels);
        audioBytes = pcmToWav(pcm16k, sampleRate: 16000, channels: 1);
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
    _noiseFloorDb = null;
    _consecutiveSpeechFrames = 0;

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
        if (!isInterim) {
          lastTranscribeError = 'Voice API not ready. Please try again.';
        }
        return null;
      }
      try {
        if (!isInterim) lastTranscribeError = null;
        final timeout = isInterim ? const Duration(seconds: 8) : const Duration(seconds: 25);
        final res = await _voiceApi!.sttTranscribe(
          audio: bytes,
          mime: mime,
          lang: lang,
          reqId: reqId,
          timeout: timeout,
        );
        if (res != null && res.isNotEmpty) {
          final clean = sanitizeTranscript(res);
          if (clean.isNotEmpty) return clean;
        }
        return null;
      } catch (e) {
        debugPrint('[SttService] cloud STT error: $e');
        if (!isInterim) {
          lastTranscribeError = uiFriendlyError(e, fallback: 'Speech recognition failed. Please try again.');
        }
        return null;
      }
    }
    if (webTranscribe != null) {
      final res = await webTranscribe(bytes, lang, mime);
      return res != null ? sanitizeTranscript(res) : null;
    }
    return null;
  }
}
