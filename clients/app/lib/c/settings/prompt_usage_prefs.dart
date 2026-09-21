import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client preference — show token counts and timing on AI replies.
class PromptUsagePrefs extends ChangeNotifier {
  PromptUsagePrefs._();

  static final PromptUsagePrefs instance = PromptUsagePrefs._();

  static const _key = 'prompt_show_usage_stats';

  SharedPreferences? _prefs;
  var _showUsageStats = true;

  bool get showUsageStats => _showUsageStats;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _showUsageStats = _prefs!.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> setShowUsageStats(bool value) async {
    if (_showUsageStats == value) return;
    _showUsageStats = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_key, value);
    notifyListeners();
  }
}
