import 'package:shared_preferences/shared_preferences.dart';

class AiDisclaimerPrefs {
  AiDisclaimerPrefs._();

  static final AiDisclaimerPrefs instance = AiDisclaimerPrefs._();

  static const _keyAcknowledged = 'legal_ai_disclaimer_ack_v1';

  SharedPreferences? _prefs;

  Future<bool> get acknowledged async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(_keyAcknowledged) ?? false;
  }

  Future<void> acknowledgePut() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyAcknowledged, true);
  }
}
