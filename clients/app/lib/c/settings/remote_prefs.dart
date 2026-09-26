import 'package:shared_preferences/shared_preferences.dart';

class RemotePrefs {
  RemotePrefs._();

  static final RemotePrefs instance = RemotePrefs._();

  static const _keyShowStreamStats = 'remote_show_stream_stats';

  SharedPreferences? _prefs;
  var showStreamStats = false;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    showStreamStats = _prefs!.getBool(_keyShowStreamStats) ?? false;
  }

  Future<void> setShowStreamStats(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    showStreamStats = value;
    await _prefs!.setBool(_keyShowStreamStats, value);
  }
}
