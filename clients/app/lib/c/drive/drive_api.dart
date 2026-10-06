import 'dart:convert';

import 'package:alienai_c35/c/api/settings_conn.dart';

class DriveStorage {
  const DriveStorage({required this.usedBytes, required this.limitBytes});

  final int usedBytes;
  final int limitBytes;

  static DriveStorage? fromJsonMap(Map<String, dynamic> json) {
    final used = _asInt(json['storage_used_bytes']);
    final limit = _asInt(json['storage_limit_bytes']);
    if (used == null || limit == null) return null;
    return DriveStorage(usedBytes: used, limitBytes: limit);
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

Future<DriveStorage?> driveStorageGet(SettingsConn conn) async {
  final res = await conn.authInvokeCall(path: '/v1/drive/storage', method: 'GET');
  if (res.statusCode >= 400 || res.body.isEmpty) return null;
  try {
    final json = jsonDecode(utf8.decode(res.body)) as Map<String, dynamic>;
    return DriveStorage.fromJsonMap(json);
  } catch (_) {
    return null;
  }
}

String driveStorageLabel(int usedBytes, int limitBytes) {
  if (limitBytes <= 0) return driveFormatAtScale(usedBytes, 0);
  final scale = driveStorageUnitIndex(limitBytes);
  return '${driveFormatAtScale(usedBytes, scale)} / ${driveFormatAtScale(limitBytes, scale)}';
}

double? driveStorageUsageFraction(int usedBytes, int limitBytes) {
  if (limitBytes <= 0) return null;
  return (usedBytes / limitBytes).clamp(0.0, 1.0);
}

bool driveStorageUsageHigh(int usedBytes, int limitBytes) =>
    limitBytes > 0 && usedBytes / limitBytes > 0.85;

int driveStorageUnitIndex(int limitBytes) {
  if (limitBytes <= 0) return 0;
  var i = 0;
  var n = limitBytes.toDouble();
  while (n >= 1024 && i < 4) {
    n /= 1024;
    i++;
  }
  return i;
}

String driveFormatAtScale(int bytes, int unitIndex) {
  if (bytes < 0) bytes = 0;
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final unit = units[unitIndex.clamp(0, units.length - 1)];
  if (unitIndex == 0) return '${_groupInteger(bytes)} $unit';
  final divisor = 1 << (10 * unitIndex);
  final n = bytes / divisor;
  final digits = n >= 100
      ? 0
      : (n >= 10 ? 1 : (n >= 1 ? 1 : (n > 0 && n < 0.01 && unitIndex >= 2 ? 4 : 2)));
  return '${_groupDecimal(n, digits)} $unit';
}

String driveBytesHuman(int bytes) {
  if (bytes < 0) bytes = 0;
  var i = 0;
  var n = bytes.toDouble();
  while (n >= 1024 && i < 4) {
    n /= 1024;
    i++;
  }
  return driveFormatAtScale(bytes, i);
}

String _groupInteger(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final buf = <String>[];
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.add(',');
    buf.add(s[i]);
  }
  return '${neg ? '-' : ''}${buf.join()}';
}

String _groupDecimal(double value, int decimals) {
  final sign = value < 0 ? '-' : '';
  final v = value.abs();
  final fixed = v.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = _groupInteger(int.parse(parts[0]));
  if (decimals == 0) return '$sign$intPart';
  return '$sign$intPart.${parts[1]}';
}