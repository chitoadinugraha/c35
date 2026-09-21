import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoicePrefs extends ChangeNotifier {
  VoicePrefs._();

  static final VoicePrefs instance = VoicePrefs._();

  static const _keyLang = 'voice_speech_lang';
  static const _keyLastLang = 'voice_last_lang';
  static const _keyStt = 'voice_stt_engine';
  static const _keyTts = 'voice_tts_engine';
  static const _keySpeak = 'csai_voice_speak_enabled';
  static const speakEnabledDefault = false;
  static const _keyRate = 'voice_speech_rate';
  static const _keyPitch = 'voice_speech_pitch';

  SharedPreferences? _prefs;
  var _speechLang = kSpeechLangDefault;
  var _lastLang = '';
  var _sttEngine = 'web';
  var _ttsEngine = 'web';
  var _speakEnabled = speakEnabledDefault;
  var _speechRate = 1.4;
  var _speechPitch = 1.0;

  String get speechLang => _speechLang;
  String get lastLang => _lastLang;
  String get sttEngine => _sttEngine;
  String get ttsEngine => _ttsEngine;
  bool get speakEnabled => _speakEnabled;
  double get speechRate => _speechRate;
  double get speechPitch => _speechPitch;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _speechLang = _prefs!.getString(_keyLang) ?? kSpeechLangDefault;
    _lastLang = _prefs!.getString(_keyLastLang) ?? '';
    _sttEngine = _prefs!.getString(_keyStt) ?? 'web';
    if (_sttEngine == 'local') {
      _sttEngine = 'web';
      await _prefs!.setString(_keyStt, _sttEngine);
    }
    _ttsEngine = _prefs!.getString(_keyTts) ?? 'web';
    _speakEnabled = _prefs!.getBool(_keySpeak) ?? speakEnabledDefault;
    _speechRate = _prefs!.getDouble(_keyRate) ?? 1.4;
    _speechPitch = _prefs!.getDouble(_keyPitch) ?? 1.0;
    notifyListeners();
  }

  Future<void> setSpeechRate(double value) async {
    if (_speechRate == value) return;
    _speechRate = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_keyRate, value);
    notifyListeners();
  }

  Future<void> setSpeechPitch(double value) async {
    if (_speechPitch == value) return;
    _speechPitch = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_keyPitch, value);
    notifyListeners();
  }

  Future<void> setSpeakEnabled(bool value) async {
    if (_speakEnabled == value) return;
    _speakEnabled = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keySpeak, value);
    notifyListeners();
  }

  Future<void> setSpeechLang(String value) async {
    if (_speechLang == value) return;
    _speechLang = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyLang, value);
    notifyListeners();
  }

  Future<void> setLastLang(String value) async {
    if (value.isEmpty || _lastLang == value) return;
    _lastLang = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyLastLang, value);
    notifyListeners();
  }

  Future<void> setSttEngine(String value) async {
    if (_sttEngine == value) return;
    _sttEngine = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyStt, value);
    notifyListeners();
  }

  Future<void> setTtsEngine(String value) async {
    if (_ttsEngine == value) return;
    _ttsEngine = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyTts, value);
    notifyListeners();
  }
}
