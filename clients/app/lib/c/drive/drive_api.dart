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
  if (limitBytes <= 0) return driveBytesHuman(usedBytes);
  return '${driveBytesHuman(usedBytes)} / ${driveBytesHuman(limitBytes)}';
}

String driveBytesHuman(int bytes) {
  if (bytes < 0) bytes = 0;
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var n = bytes.toDouble();
  var i = 0;
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024;
    i++;
  }
  final digits = i == 0 ? 0 : (n >= 100 ? 0 : (n >= 10 ? 1 : 2));
  return '${n.toStringAsFixed(digits)} ${units[i]}';
}