import 'dart:async';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:flutter/material.dart';

import 'voice_input_controller.dart';
import 'voice_transcript.dart';

bool sttVoiceErrorIsNoSpeech(dynamic error) {
  if (error is Map) {
    final code = '${error['error'] ?? ''}'.toLowerCase();
    if (code == 'no-speech' || code == 'no_speech') return true;
  }
  final msg = '$error'.toLowerCase();
  return msg.contains('no-speech') || msg.contains('no_speech');
}

bool sttVoiceErrorIsInvalidState(dynamic error) {
  if (error is Map) {
    final code = '${error['error'] ?? ''}'.toLowerCase();
    if (code == 'invalidstateerror') return true;
  }
  return '$error'.toLowerCase().contains('already started');
}

bool _sttVoiceErrorIsNetwork(dynamic error) {
  if (error is Map) {
    final code = '${error['error'] ?? ''}'.toLowerCase();
    if (code == 'network') return true;
  }
  return '$error'.toLowerCase().contains('network');
}

String sttVoiceErrorMessage(dynamic error) {
  if (_sttVoiceErrorIsNetwork(error)) {
    return 'Web Speech could not reach the speech service from WebView. '
        'Try https://alienai.id/tts.html in Edge, or switch to Cloud in Settings.';
  }
  if (error is Map) {
    final msg = '${error['message'] ?? ''}'.trim();
    if (msg.isNotEmpty && msg != 'Speech recognition error') return msg;
  }
  return 'Speech recognition failed. Try again or switch to Cloud engine in Settings.';
}

/// CSA-style live Web Speech input (headless WebView + tts.html).
class SttSpeechInput {
  SttSpeechInput();

  static const maxRecordingSeconds = 30;

  VoiceInputController? _voice;
  var _sessionLang = '';
  var _listening = false;
  var _transcriptFinal = '';
  var _transcriptInterim = '';
  var _handledFinal = false;
  var _sessionFailed = false;
  Timer? _secondTimer;
  DateTime? _lastTranscriptAt;
  final ValueNotifier<int> recordingSeconds = ValueNotifier(0);
  final ValueNotifier<bool> isPreparing = ValueNotifier(false);
  final ValueNotifier<String> liveTranscript = ValueNotifier('');

  bool get isRecording => _listening;
  bool get isBusy => _voice?.preparing ?? false;
  String get transcriptFinal => _transcriptFinal;
  String get transcriptInterim => _transcriptInterim;

  bool get isActive =>
      isRecording || isBusy || _transcriptFinal.trim().isNotEmpty || _transcriptInterim.trim().isNotEmpty;

  String _lang() => speechLangSttLocale(
        VoicePrefs.instance.speechLang,
        last: VoicePrefs.instance.lastLang,
      );

  Future<void> toggle({
    required TextEditingController controller,
    required VoidCallback onStateChanged,
    void Function(Object e)? onError,
  }) async {
    _sessionLang = _lang();
    _ensureVoice(controller: controller, onStateChanged: onStateChanged, onError: onError);

    if (_voice?.preparing ?? false) {
      await cancel();
      onStateChanged();
      return;
    }
    if (_listening || (_voice?.isListening ?? false)) {
      await _voice!.stop();
      return;
    }

    _handledFinal = false;
    _sessionFailed = false;
    _transcriptFinal = '';
    _transcriptInterim = '';
    liveTranscript.value = '';
    onStateChanged();
    try {
      await _voice!.start();
    } catch (e) {
      _stopTimers();
      _listening = false;
      _transcriptFinal = '';
      _transcriptInterim = '';
      liveTranscript.value = '';
      onStateChanged();
      onError?.call(e);
      rethrow;
    }
  }

  Future<void> cancel() async {
    _handledFinal = true;
    _sessionFailed = false;
    _transcriptFinal = '';
    _transcriptInterim = '';
    _listening = false;
    liveTranscript.value = '';
    _stopTimers();
    await _voice?.stop();
  }

  void dispose() {
    _stopTimers();
    _voice?.dispose();
    _voice = null;
    recordingSeconds.dispose();
    isPreparing.dispose();
    liveTranscript.dispose();
  }

  void _ensureVoice({
    required TextEditingController controller,
    required VoidCallback onStateChanged,
    void Function(Object e)? onError,
  }) {
    final lang = _sessionLang.isEmpty ? _lang() : _sessionLang;
    if (_voice != null && _voice!.lang == lang) return;
    _voice?.dispose();
    _voice = VoiceInputController(
      lang: lang,
      onPreparing: (v) {
        isPreparing.value = v;
        onStateChanged();
      },
      onStart: () {
        debugPrint('[SttSpeechInput] listening ($lang)');
        _listening = true;
        _handledFinal = false;
        _sessionFailed = false;
        _transcriptFinal = '';
        _transcriptInterim = '';
        liveTranscript.value = '';
        recordingSeconds.value = 0;
        _lastTranscriptAt = null;
        _startTimers(onStateChanged);
        onStateChanged();
      },
      onTranscript: (t) {
        _applyLiveTranscript(t);
        final line = liveTranscript.value;
        if (line.isNotEmpty) {
          controller.text = line;
          controller.selection = TextSelection.collapsed(offset: controller.text.length);
        }
        onStateChanged();
      },
      onFinalTranscript: (t) {
        _applyLiveTranscript(t);
        _applyFinal(t, controller: controller, onStateChanged: onStateChanged);
      },
      onStop: () {
        if (_sessionFailed) {
          _sessionFailed = false;
          return;
        }
        _listening = false;
        _stopTimers();
        if (!_handledFinal) {
          final txt = liveTranscript.value.trim();
          if (txt.isNotEmpty) {
            _applyFinal(
              VoiceTranscript(lang: lang, txt: txt, confidence: 1, isFinal: true),
              controller: controller,
              onStateChanged: onStateChanged,
            );
          }
        }
        onStateChanged();
      },
      onError: (e) {
        debugPrint('[SttSpeechInput] error: $e');
        if (sttVoiceErrorIsInvalidState(e)) return;
        if (sttVoiceErrorIsNoSpeech(e)) {
          _listening = false;
          _transcriptFinal = '';
          _transcriptInterim = '';
          liveTranscript.value = '';
          _stopTimers();
          onStateChanged();
          return;
        }
        _sessionFailed = true;
        _handledFinal = true;
        _listening = false;
        _transcriptFinal = '';
        _transcriptInterim = '';
        liveTranscript.value = '';
        _stopTimers();
        onStateChanged();
        onError?.call(e);
      },
    );
  }

  void _applyLiveTranscript(VoiceTranscript t) {
    if (t.isFinal) {
      if (t.txt.isNotEmpty) _transcriptFinal = t.txt.trim();
      _transcriptInterim = '';
    } else if (t.interim.isNotEmpty) {
      if (t.txt.isNotEmpty) _transcriptFinal = t.txt.trim();
      _transcriptInterim = t.interim.trim();
    } else if (t.txt.isNotEmpty) {
      _transcriptInterim = t.txt.trim();
    }
    final line = [_transcriptFinal, _transcriptInterim].where((s) => s.isNotEmpty).join(' ');
    if (line.isNotEmpty) {
      liveTranscript.value = SttService.sanitizeTranscript(line);
      _lastTranscriptAt = DateTime.now();
    }
  }

  void _applyFinal(
    VoiceTranscript t, {
    required TextEditingController controller,
    required VoidCallback onStateChanged,
  }) {
    if (_handledFinal) return;
    _handledFinal = true;
    final raw = t.txt.trim().isNotEmpty ? t.txt.trim() : liveTranscript.value.trim();
    final txt = SttService.sanitizeTranscript(raw);
    _transcriptFinal = txt;
    _transcriptInterim = '';
    _listening = false;
    liveTranscript.value = txt;
    if (txt.isEmpty) {
      onStateChanged();
      return;
    }
    final current = controller.text.trim();
    controller.text = current.isEmpty ? txt : '$current $txt';
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    onStateChanged();
  }

  void _startTimers(VoidCallback onStateChanged) {
    _stopTimers();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_listening) return;
      recordingSeconds.value++;
      if (recordingSeconds.value >= maxRecordingSeconds) {
        unawaited(_voice?.stop());
        return;
      }
      if (_lastTranscriptAt != null && recordingSeconds.value >= 1) {
        if (DateTime.now().difference(_lastTranscriptAt!) >= const Duration(milliseconds: 2200)) {
          unawaited(_voice?.stop());
        }
      }
    });
  }

  void _stopTimers() {
    _secondTimer?.cancel();
    _secondTimer = null;
  }
}
