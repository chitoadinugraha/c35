import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/task/task_trigger_cron.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocalePrefs extends ChangeNotifier {
  UserLocalePrefs._();

  static final UserLocalePrefs instance = UserLocalePrefs._();

  static const _keyTz = 'user_locale_tz';
  static const _keyCity = 'user_locale_city';
  static const _keyRegion = 'user_locale_region';
  static const _keyCountry = 'user_locale_country';
  static const _keyLocationSource = 'user_locale_location_source';

  SharedPreferences? _prefs;
  var _tz = '';
  var _locationCity = '';
  var _locationRegion = '';
  var _locationCountry = '';
  var _locationSource = '';

  String get tz => _tz;
  String get locationCity => _locationCity;
  String get locationRegion => _locationRegion;
  String get locationCountry => _locationCountry;
  String get locationSource => _locationSource;

  bool get locationManualLocked =>
      locationSource.trim().toLowerCase() == 'user' && locationCity.trim().isNotEmpty;

  String get locationPlaceSummary {
    final parts = [locationCity, locationRegion, locationCountry].map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  static String deviceTimezoneDetect() {
    final name = DateTime.now().timeZoneName;
    if (name == 'WIB') return 'Asia/Jakarta';
    if (name == 'WITA') return 'Asia/Makassar';
    if (name == 'WIT') return 'Asia/Jayapura';
    if (name == 'SGT') return 'Asia/Singapore';
    final o = DateTime.now().timeZoneOffset;
    if (o.inHours == 7) return 'Asia/Jakarta';
    if (o.inHours == 8) return 'Asia/Singapore';
    if (o.inHours == 9) return 'Asia/Tokyo';
    return taskTimezoneLocal();
  }

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _tz = _prefs!.getString(_keyTz) ?? deviceTimezoneDetect();
    _locationCity = _prefs!.getString(_keyCity) ?? '';
    _locationRegion = _prefs!.getString(_keyRegion) ?? '';
    _locationCountry = _prefs!.getString(_keyCountry) ?? '';
    _locationSource = _prefs!.getString(_keyLocationSource) ?? '';
    notifyListeners();
  }

  Future<void> put({
    String? tz,
    String? locationCity,
    String? locationRegion,
    String? locationCountry,
    String? locationSource,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (tz != null) {
      _tz = tz.trim();
      await _prefs!.setString(_keyTz, _tz);
    }
    if (locationCity != null) {
      _locationCity = locationCity.trim();
      await _prefs!.setString(_keyCity, _locationCity);
    }
    if (locationRegion != null) {
      _locationRegion = locationRegion.trim();
      await _prefs!.setString(_keyRegion, _locationRegion);
    }
    if (locationCountry != null) {
      _locationCountry = locationCountry.trim().toUpperCase();
      await _prefs!.setString(_keyCountry, _locationCountry);
    }
    if (locationSource != null) {
      _locationSource = locationSource.trim();
      await _prefs!.setString(_keyLocationSource, _locationSource);
    }
    notifyListeners();
  }

  Future<void> mergeFromProfile({
    String? tz,
    String? locationCity,
    String? locationRegion,
    String? locationCountry,
    String? locationSource,
  }) async {
    if (locationManualLocked) {
      if (tz != null && tz.isNotEmpty && _tz.isEmpty) await put(tz: tz);
      return;
    }
    await put(
      tz: tz != null && tz.isNotEmpty ? tz : null,
      locationCity: locationCity != null && locationCity.isNotEmpty ? locationCity : null,
      locationRegion: locationRegion != null && locationRegion.isNotEmpty ? locationRegion : null,
      locationCountry: locationCountry != null && locationCountry.isNotEmpty ? locationCountry : null,
      locationSource: locationSource != null && locationSource.isNotEmpty ? locationSource : null,
    );
    if (locationSource != null && locationSource.isNotEmpty) {
      await UserLocationPrefs.instance.put(locationSource: locationSource);
    }
  }
}
