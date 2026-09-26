import 'package:shared_preferences/shared_preferences.dart';

class RemotePrefs {
  RemotePrefs._();

  static final RemotePrefs instance = RemotePrefs._();

  static const _keyShowStreamStats = 'remote_show_stream_stats';
  static const _keyInteractMode = 'remote_interact_mode';

  SharedPreferences? _prefs;
  var showStreamStats = false;
  var interactMode = 'control';

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    showStreamStats = _prefs!.getBool(_keyShowStreamStats) ?? false;
    interactMode = _prefs!.getString(_keyInteractMode) ?? 'control';
  }

  Future<void> setShowStreamStats(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    showStreamStats = value;
    await _prefs!.setBool(_keyShowStreamStats, value);
  }

  Future<void> setInteractMode(String mode) async {
    _prefs ??= await SharedPreferences.getInstance();
    interactMode = mode;
    await _prefs!.setString(_keyInteractMode, mode);
  }
}
