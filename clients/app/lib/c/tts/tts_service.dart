import 'dart:async';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  VoiceApi? _voiceApi;

  void bindVoiceApi(VoiceApi? api) => _voiceApi = api;

  @visibleForTesting
  static String ttsEngineRoute(String engine) {
    switch (engine) {
      case 'web':
      case 'local':
      case 'cloud':
        return engine;
      default:
        return 'cloud';
    }
  }

  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;
  var _initialized = false;
  var _speakGen = 0;
  var _playGen = -1;
  TtsStreamQueue? _activeQueue;
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<String> speakingLang = ValueNotifier(kSpeechLangFallback);
  String? lastSpeakError;

  void _attachQueue(TtsStreamQueue queue) {
    if (!identical(_activeQueue, queue)) _activeQueue?.halt();
    _activeQueue = queue;
  }

  void _detachQueue(TtsStreamQueue queue) {
    if (identical(_activeQueue, queue)) _activeQueue = null;
  }

  void _bindPlayer(AudioPlayer player) {
    player.onPlayerStateChanged.listen((state) {
      if (!identical(player, _audioPlayer)) return;
      if (_playGen != _speakGen) return;
      if (state == PlayerState.playing) {
        isSpeaking.value = true;
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        isSpeaking.value = false;
      }
    });
    player.onPlayerComplete.listen((_) {
      if (!identical(player, _audioPlayer)) return;
      if (_playGen != _speakGen) return;
      isSpeaking.value = false;
    });
  }

  Future<void> _ensurePlayer() async {
    if (_audioPlayer != null) return;
    try {
      final player = AudioPlayer();
      _bindPlayer(player);
      _audioPlayer = player;
    } catch (e) {
      debugPrint('[TtsService] AudioPlayer init failed: $e');
    }
  }

  Future<void> _init() async {
    if (_initialized) {
      await _ensurePlayer();
      return;
    }
    await _ensurePlayer();

    try {
      _flutterTts = FlutterTts();
      _flutterTts!.setStartHandler(() {
        if (_playGen == _speakGen) isSpeaking.value = true;
      });
      _flutterTts!.setCompletionHandler(() {
        if (_playGen == _speakGen) isSpeaking.value = false;
      });
      _flutterTts!.setCancelHandler(() {
        if (_playGen == _speakGen) isSpeaking.value = false;
      });
      _flutterTts!.setErrorHandler((msg) {
        debugPrint('[TtsService] FlutterTts error: $msg');
        if (_playGen == _speakGen) isSpeaking.value = false;
      });
      await _flutterTts!.setLanguage(kSpeechLangFallback);
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
    } catch (e) {
      debugPrint('[TtsService] FlutterTts init failed: $e');
    }
    _initialized = true;
  }

  /// Text passed to TTS engines after [speechTextClean] — full message, no sentence cap.
  @visibleForTesting
  static String speakPreparedText(String text) => speechTextClean(text);

  bool _genAlive(int gen) => gen == _speakGen;

  Future<void> speak(String text, {String? lang, bool fromQueue = false}) async {
    final spoken = speakPreparedText(text);
    if (spoken.isEmpty) return;
    if (!fromQueue) _activeQueue?.halt();
    final gen = ++_speakGen;
    await _silence(discardPlayer: true);
    if (!_genAlive(gen)) return;
    await _init();
    if (!_genAlive(gen)) return;
    final prefs = VoicePrefs.instance;
    final localePref = (lang != null && lang != kSpeechLangAuto) ? lang : prefs.speechLang;
    final effectiveLang = (lang != null && lang != kSpeechLangAuto)
        ? lang
        : speechLangResolve(spoken, last: prefs.lastLang, locale: localePref);
    unawaited(prefs.setLastLang(effectiveLang));
    lastSpeakError = null;
    speakingLang.value = effectiveLang;
    isSpeaking.value = true;
    final engine = ttsEngineRoute(prefs.ttsEngine);
    if (engine == 'cloud') {
      final played = await _speakCloud(spoken, effectiveLang, prefs.speechRate, gen);
      if (played || !_genAlive(gen)) return;
    } else if (engine == 'web') {
      final played = await _speakWeb(spoken, effectiveLang, prefs.speechRate, gen);
      if (played || !_genAlive(gen)) return;
    } else if (engine != 'local') {
      debugPrint('[TtsService] unknown tts engine "$engine", using local');
    }
    if (!_genAlive(gen) || _flutterTts == null) {
      if (_genAlive(gen)) isSpeaking.value = false;
      return;
    }
    try {
      if (!_genAlive(gen)) return;
      speakingLang.value = effectiveLang;
      await _flutterTts!.setLanguage(effectiveLang);
      await _flutterTts!.setSpeechRate((0.5 * prefs.speechRate).clamp(0.1, 1.0));
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(prefs.speechPitch.clamp(0.5, 2.0));
      final def = speechLangDef(effectiveLang);
      if (def != null && def.voiceNameHints.isNotEmpty) {
        try {
          final dynamic rawVoices = await _flutterTts!.getVoices;
          if (rawVoices is List) {
            for (final v in rawVoices) {
              if (v is Map) {
                final vLocale = (v['locale'] ?? '').toString().toLowerCase();
                final vName = (v['name'] ?? '').toString().toLowerCase();
                if (vLocale.startsWith(def.ttsTl) || def.voiceNameHints.any(vName.contains)) {
                  await _flutterTts!.setVoice({'name': v['name'].toString(), 'locale': v['locale'].toString()});
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }
      if (!_genAlive(gen)) return;
      _playGen = gen;
      isSpeaking.value = true;
      await _flutterTts!.speak(spoken);
      if (!_genAlive(gen) && _playGen == gen) {
        await _silence(discardPlayer: true);
        isSpeaking.value = false;
      }
    } catch (e) {
      debugPrint('[TtsService] Local Speak error: $e');
      if (_genAlive(gen)) isSpeaking.value = false;
    }
  }

  @visibleForTesting
  Future<bool> speakRouted({
    required String engine,
    required String spoken,
    required String effectiveLang,
    required double speechRate,
    int? gen,
    Future<({Uint8List bytes, String mime})?> Function({required String text, String? lang})? cloudSynthesize,
    Future<Uint8List?> Function(String spoken, String effectiveLang)? webFetch,
  }) async {
    bool alive() => gen == null || gen == _speakGen;
    if (engine == 'cloud') {
      if (_voiceApi == null && cloudSynthesize == null) return false;
      try {
        lastSpeakError = null;
        Future<({Uint8List bytes, String mime})?> synth() => cloudSynthesize != null
            ? cloudSynthesize(text: spoken, lang: effectiveLang)
            : _voiceApi!.ttsSynthesize(text: spoken, lang: effectiveLang);
        ({Uint8List bytes, String mime})? audio;
        try {
          audio = await synth();
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('balance') || msg.contains('top up') || msg.contains('quota')) rethrow;
          debugPrint('[TtsService] Cloud TTS failed once, retrying: $e');
          await Future<void>.delayed(const Duration(milliseconds: 400));
          audio = await synth();
        }
        if (!alive()) return false;
        if (audio != null && audio.bytes.isNotEmpty && _audioPlayer != null) {
          final player = _audioPlayer!;
          speakingLang.value = effectiveLang;
          _playGen = gen ?? _speakGen;
          isSpeaking.value = true;
          await player.setPlaybackRate(speechRate);
          if (!alive() || !identical(player, _audioPlayer)) return false;
          await player.play(BytesSource(audio.bytes));
          if (!alive() || !identical(player, _audioPlayer)) {
            if (_playGen == (gen ?? _speakGen)) {
              await _silence(discardPlayer: true);
              isSpeaking.value = false;
            }
            return false;
          }
          return true;
        }
      } catch (e) {
        lastSpeakError = uiFriendlyError(e, fallback: 'Cloud voice playback failed. Please try again.');
        debugPrint('[TtsService] Cloud TTS error: $e');
      }
      return false;
    }
    if (engine == 'web') {
      final bytes = webFetch != null
          ? await webFetch(spoken, effectiveLang)
          : await _fetchWebTtsBytes(spoken, effectiveLang);
      if (!alive()) return false;
      if (bytes != null && bytes.isNotEmpty && _audioPlayer != null) {
        final player = _audioPlayer!;
        speakingLang.value = effectiveLang;
        _playGen = gen ?? _speakGen;
        isSpeaking.value = true;
        await player.setPlaybackRate(speechRate);
        if (!alive() || !identical(player, _audioPlayer)) return false;
        await player.play(BytesSource(bytes));
        if (!alive() || !identical(player, _audioPlayer)) {
          if (_playGen == (gen ?? _speakGen)) {
            await _silence(discardPlayer: true);
            isSpeaking.value = false;
          }
          return false;
        }
        return true;
      }
      return false;
    }
    return false;
  }

  Future<bool> _speakCloud(String spoken, String effectiveLang, double speechRate, int gen) =>
      speakRouted(engine: 'cloud', spoken: spoken, effectiveLang: effectiveLang, speechRate: speechRate, gen: gen);

  Future<bool> _speakWeb(String spoken, String effectiveLang, double speechRate, int gen) =>
      speakRouted(engine: 'web', spoken: spoken, effectiveLang: effectiveLang, speechRate: speechRate, gen: gen);

  Future<Uint8List?> _fetchWebTtsBytes(String spoken, String effectiveLang) async {
    try {
      final shortLang = speechLangTtsCode(effectiveLang);
      final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$shortLang&client=tw-ob&q=${Uri.encodeComponent(spoken)}';
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return res.bodyBytes;
    } catch (e) {
      debugPrint('[TtsService] Web TTS error, falling back to local: $e');
    }
    return null;
  }

  Future<void> _silence({required bool discardPlayer}) async {
    final player = _audioPlayer;
    if (discardPlayer) _audioPlayer = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (e) {
        debugPrint('[TtsService] AudioPlayer stop error: $e');
      }
      if (discardPlayer) {
        try {
          await player.dispose();
        } catch (e) {
          debugPrint('[TtsService] AudioPlayer dispose error: $e');
        }
      }
    }
    try {
      await _flutterTts?.setVolume(0);
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('[TtsService] FlutterTts stop error: $e');
    }
  }

  Future<void> stop() async {
    _speakGen++;
    _playGen = -1;
    _activeQueue?.halt();
    isSpeaking.value = false;
    await _silence(discardPlayer: true);
    isSpeaking.value = false;
  }
}

/// Buffers streaming reply text and speaks it in clips.
/// List lines stay in one clip. [stop] drops anything not yet playing.
class TtsStreamQueue {
  TtsStreamQueue({
    Future<void> Function(String text)? speak,
    Future<void> Function()? onStop,
  }) : _speak = speak,
       _onStop = onStop,
       _ownsService = speak == null {
    if (_ownsService) TtsService.instance._attachQueue(this);
  }

  final Future<void> Function(String text)? _speak;
  final Future<void> Function()? _onStop;
  final bool _ownsService;
  final List<String> _pending = [];
  bool _running = false;
  String _currentBuffer = '';
  var _cancelled = false;

  bool get isHalted => _cancelled;

  void feedChunk(String chunk) {
    if (_cancelled || chunk.isEmpty) return;
    _currentBuffer += chunk;
    final pull = speechPullChunks(_currentBuffer);
    _currentBuffer = pull.rest;
    for (final piece in pull.ready) {
      _enqueue(piece);
    }
  }

  void flush() {
    if (_cancelled) return;
    final pull = speechPullChunks(_currentBuffer, flush: true);
    _currentBuffer = pull.rest;
    for (final piece in pull.ready) {
      _enqueue(piece);
    }
  }

  void _enqueue(String sentence) {
    _pending.add(sentence);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    while (_pending.isNotEmpty && !_cancelled) {
      final next = _pending.removeAt(0);
      if (_speak != null) {
        await _speak(next);
      } else {
        await TtsService.instance.speak(next, fromQueue: true);
      }
      if (_cancelled) break;
      while (_ownsService && TtsService.instance.isSpeaking.value && !_cancelled) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    _running = false;
  }

  void halt() {
    if (_cancelled) return;
    _cancelled = true;
    _pending.clear();
    _currentBuffer = '';
    _running = false;
    if (_ownsService) TtsService.instance._detachQueue(this);
  }

  void cancel() {
    halt();
    final stop = _onStop;
    if (stop != null) {
      unawaited(stop());
      return;
    }
    if (_ownsService) unawaited(TtsService.instance.stop());
  }
}
