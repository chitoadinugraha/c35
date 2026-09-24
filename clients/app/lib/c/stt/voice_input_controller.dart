import 'dart:async';

import 'package:flutter/scheduler.dart';

import 'voice_recognizer_webview.dart';
import 'voice_transcript.dart';

const kVoicePrepareTimeout = Duration(seconds: 8);

class VoiceInputController {
  VoiceInputController({
    required this.lang,
    this.onStart,
    this.onStop,
    this.onPreparing,
    this.onTranscript,
    this.onFinalTranscript,
    this.onError,
  }) {
    _recognizer = VoiceRecognizerWebView(
      onStart: () {
        _prepareTimeoutCancel();
        _preparingSet(false);
        _isListening = true;
        _listeningEmit(true);
        onStart?.call();
      },
      onEnd: () {
        _prepareTimeoutCancel();
        _preparingSet(false);
        _isListening = false;
        _listeningEmit(false);
        if (_errored) {
          _errored = false;
          return;
        }
        onStop?.call();
      },
      onInit: () {},
      onTranscript: (t) => onTranscript?.call(t),
      onTranscriptFinal: (t) => onFinalTranscript?.call(t),
      onError: (e) {
        _errored = true;
        _prepareTimeoutCancel();
        _preparingSet(false);
        _isListening = false;
        _listeningEmit(false);
        onError?.call(e);
      },
    );
    _recognizerSub = _recognizer.isListeningStream.listen((v) {
      if (_isListening == v) return;
      _isListening = v;
      _listeningEmit(v);
    });
  }

  final String lang;
  final void Function()? onStart;
  final void Function()? onStop;
  final void Function(bool preparing)? onPreparing;
  final void Function(VoiceTranscript t)? onTranscript;
  final void Function(VoiceTranscript t)? onFinalTranscript;
  final void Function(Object e)? onError;

  late final VoiceRecognizerWebView _recognizer;
  StreamSubscription<bool>? _recognizerSub;
  final _listeningCtrl = StreamController<bool>.broadcast();
  final _preparingCtrl = StreamController<bool>.broadcast();
  var _isListening = false;
  var _preparing = false;
  var _errored = false;
  Timer? _prepareTimeout;

  Stream<bool> get isListeningStream => _listeningCtrl.stream;
  bool get isListening => _isListening;
  bool get preparing => _preparing;

  void _listeningEmit(bool v) {
    if (_listeningCtrl.isClosed) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_listeningCtrl.isClosed) return;
      _listeningCtrl.add(v);
    });
  }

  void _prepareTimeoutCancel() {
    _prepareTimeout?.cancel();
    _prepareTimeout = null;
  }

  void _preparingSet(bool v) {
    if (_preparing == v) return;
    _preparing = v;
    _preparingCtrl.add(v);
    onPreparing?.call(v);
  }

  void _prepareTimeoutArm() {
    _prepareTimeoutCancel();
    _prepareTimeout = Timer(kVoicePrepareTimeout, () {
      if (!_preparing) return;
      _preparingSet(false);
      _isListening = false;
      _listeningEmit(false);
      unawaited(_recognizer.stop());
      onError?.call(
        Exception(
          'Speech recognition did not start. Try Cloud engine in speech settings, or check microphone permission.',
        ),
      );
    });
  }

  Future<void> start() async {
    if (_isListening || _preparing) return;
    _preparingSet(true);
    _prepareTimeoutArm();
    try {
      await _recognizer.start(lang);
    } catch (e) {
      _prepareTimeoutCancel();
      _preparingSet(false);
      _isListening = false;
      _listeningEmit(false);
      rethrow;
    }
  }

  Future<void> stop() async {
    _prepareTimeoutCancel();
    final wasPreparing = _preparing;
    _preparingSet(false);
    if (!_isListening && !wasPreparing) return;
    try {
      await _recognizer.stop();
    } catch (_) {}
    if (_isListening || wasPreparing) {
      _isListening = false;
      _listeningEmit(false);
      if (wasPreparing) onStop?.call();
    }
  }

  void dispose() {
    _prepareTimeoutCancel();
    _recognizerSub?.cancel();
    _recognizerSub = null;
    _recognizer.dispose();
    _listeningCtrl.close();
    _preparingCtrl.close();
  }
}
