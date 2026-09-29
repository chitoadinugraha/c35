import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class RemotePrefs {
  RemotePrefs._();

  static final RemotePrefs instance = RemotePrefs._();

  static const _keyShowStreamStats = 'remote_show_stream_stats';
  static const _keyInteractMode = 'remote_interact_mode';
  static const _keyStreamQuality = 'remote_stream_quality';

  String _teachHudKey(int deviceIid) => 'remote_teach_hud_${deviceIid}_dx';

  SharedPreferences? _prefs;
  var showStreamStats = false;
  var interactMode = 'control';
  var streamQuality = 80;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    showStreamStats = _prefs!.getBool(_keyShowStreamStats) ?? false;
    interactMode = _prefs!.getString(_keyInteractMode) ?? 'control';
    streamQuality = _prefs!.getInt(_keyStreamQuality) ?? 80;
    if (streamQuality < 40 || streamQuality > 95) streamQuality = 80;
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

  Future<void> setStreamQuality(int value) async {
    _prefs ??= await SharedPreferences.getInstance();
    streamQuality = value.clamp(40, 95);
    await _prefs!.setInt(_keyStreamQuality, streamQuality);
  }

  Offset? teachHudOffset(int deviceIid) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final dx = prefs.getDouble('${_teachHudKey(deviceIid)}');
    final dy = prefs.getDouble('remote_teach_hud_${deviceIid}_dy');
    if (dx == null || dy == null) return null;
    return Offset(dx, dy);
  }

  Future<void> setTeachHudOffset(int deviceIid, Offset offset) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_teachHudKey(deviceIid), offset.dx);
    await _prefs!.setDouble('remote_teach_hud_${deviceIid}_dy', offset.dy);
  }
}
