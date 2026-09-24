import 'dart:async';

import 'voice_transcript.dart';

typedef VoiceVoidCb = void Function();
typedef VoiceValueCb<V> = void Function(V value);

abstract class VoiceRecognizer {
  VoiceRecognizer({
    this.onStart,
    this.onEnd,
    this.onInit,
    this.onTranscript,
    this.onTranscriptFinal,
    this.onError,
  });

  final VoiceVoidCb? onStart;
  final VoiceVoidCb? onEnd;
  final VoiceVoidCb? onInit;
  final VoiceValueCb<VoiceTranscript>? onTranscript;
  final VoiceValueCb<VoiceTranscript>? onTranscriptFinal;
  final VoiceValueCb<dynamic>? onError;

  bool isInitialized = false;
  Future<void> get ready;

  bool _isListening = false;
  final _scIsListening = StreamController<bool>.broadcast();
  Stream<bool> get isListeningStream => _scIsListening.stream;
  bool get isListening => _isListening;

  set isListening(bool value) {
    if (_isListening == value) return;
    _isListening = value;
    if (!_scIsListening.isClosed) _scIsListening.add(value);
  }

  Future<void> init();
  Future<void> start(String lang);
  Future<void> stop();

  void dispose() => _scIsListening.close();
}
