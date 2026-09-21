import 'dart:async';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;
  var _initialized = false;
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  final ValueNotifier<String> speakingLang = ValueNotifier(kSpeechLangFallback);

  Future<void> _init() async {
    if (_initialized) return;
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          isSpeaking.value = true;
        } else if (state == PlayerState.completed || state == PlayerState.stopped) {
          isSpeaking.value = false;
        }
      });
      _audioPlayer!.onPlayerComplete.listen((_) => isSpeaking.value = false);
    } catch (e) {
      debugPrint('[TtsService] AudioPlayer init failed: $e');
    }

    try {
      _flutterTts = FlutterTts();
      _flutterTts!.setStartHandler(() => isSpeaking.value = true);
      _flutterTts!.setCompletionHandler(() => isSpeaking.value = false);
      _flutterTts!.setCancelHandler(() => isSpeaking.value = false);
      _flutterTts!.setErrorHandler((msg) {
        debugPrint('[TtsService] FlutterTts error: $msg');
        isSpeaking.value = false;
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

  Future<void> speak(String text, {String? lang}) async {
    final clean = speechTextClean(text);
    if (clean.isEmpty) return;
    await _init();
    final spoken = speechTextCap(clean);
    final prefs = VoicePrefs.instance;
    final localePref = (lang != null && lang != kSpeechLangAuto) ? lang : prefs.speechLang;
    final effectiveLang = (lang != null && lang != kSpeechLangAuto)
        ? lang
        : speechLangResolve(clean, last: prefs.lastLang, locale: localePref);
    unawaited(prefs.setLastLang(effectiveLang));
    await stop();
    final engine = prefs.ttsEngine;
    if (engine == 'web' || engine == 'cloud') {
      try {
        final shortLang = speechLangTtsCode(effectiveLang);
        final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$shortLang&client=tw-ob&q=${Uri.encodeComponent(spoken)}';
        final res = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
        }).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty && _audioPlayer != null) {
          speakingLang.value = effectiveLang;
          isSpeaking.value = true;
          await _audioPlayer!.setPlaybackRate(prefs.speechRate);
          await _audioPlayer!.play(BytesSource(res.bodyBytes));
          return;
        }
      } catch (e) {
        debugPrint('[TtsService] Web TTS error, falling back to local: $e');
      }
    }
    if (_flutterTts == null) return;
    try {
      speakingLang.value = effectiveLang;
      await _flutterTts!.setLanguage(effectiveLang);
      await _flutterTts!.setSpeechRate((0.5 * prefs.speechRate).clamp(0.1, 1.0));
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
      isSpeaking.value = true;
      await _flutterTts!.speak(spoken);
    } catch (e) {
      debugPrint('[TtsService] Local Speak error: $e');
      isSpeaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      debugPrint('[TtsService] AudioPlayer stop error: $e');
    }
    try {
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('[TtsService] FlutterTts stop error: $e');
    }
    isSpeaking.value = false;
  }
}
