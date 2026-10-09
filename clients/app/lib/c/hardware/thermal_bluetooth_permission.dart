import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime Bluetooth permissions for thermal printing (Android 12+).
Future<bool> thermalBluetoothPermissionEnsure() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final connect = await Permission.bluetoothConnect.request();
    if (!connect.isGranted) return false;
    final scan = await Permission.bluetoothScan.request();
    return scan.isGranted;
  } catch (_) {
    return false;
  }
}

Future<bool> thermalBluetoothPermissionGranted() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final connect = await Permission.bluetoothConnect.status;
    final scan = await Permission.bluetoothScan.status;
    return connect.isGranted && scan.isGranted;
  } catch (_) {
    return false;
  }
}
