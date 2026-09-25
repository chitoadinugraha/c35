import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocationPrefs extends ChangeNotifier {
  UserLocationPrefs._();

  static final UserLocationPrefs instance = UserLocationPrefs._();

  static const _keyAsked = 'user_location_asked';
  static const _keyUseDevice = 'user_location_use_device';
  static const _keySource = 'user_location_source';

  SharedPreferences? _prefs;
  var _asked = false;
  var _useDevice = false;
  var _locationSource = '';

  bool get asked => _asked;
  bool get useDevice => _useDevice;
  String get locationSource => _locationSource;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _asked = _prefs!.getBool(_keyAsked) ?? false;
    _useDevice = _prefs!.getBool(_keyUseDevice) ?? false;
    _locationSource = _prefs!.getString(_keySource) ?? '';
    notifyListeners();
  }

  Future<void> put({bool? asked, bool? useDevice, String? locationSource}) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (asked != null) {
      _asked = asked;
      await _prefs!.setBool(_keyAsked, _asked);
    }
    if (useDevice != null) {
      _useDevice = useDevice;
      await _prefs!.setBool(_keyUseDevice, _useDevice);
    }
    if (locationSource != null) {
      _locationSource = locationSource.trim();
      await _prefs!.setString(_keySource, _locationSource);
    }
    notifyListeners();
  }

  /// Wire value for ReqSessionInit when syncing location fields.
  String sessionSourceForWire({required bool hasLocationFields}) {
    if (!hasLocationFields) return '';
    if (_locationSource.isNotEmpty) return _locationSource;
    return _useDevice ? 'device' : 'user';
  }
}
