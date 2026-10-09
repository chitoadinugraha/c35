import 'dart:io' show Platform;

import 'package:alienai_c35/c/hardware/thermal_bluetooth_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Android Bluetooth Classic transport for raw ESC/POS bytes.
class ThermalPrinterBluetooth {
  const ThermalPrinterBluetooth._();

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<bool> ensureReady() async {
    if (!isSupported) return false;
    if (!await thermalBluetoothPermissionEnsure()) return false;
    if (!await PrintBluetoothThermal.bluetoothEnabled) return false;
    return await PrintBluetoothThermal.isPermissionBluetoothGranted;
  }

  static Future<List<BluetoothInfo>> pairedDevices() async {
    if (!isSupported) return [];
    if (!await ensureReady()) return [];
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<bool> printBytes(List<int> bytes, {required String macAddress}) async {
    if (!isSupported) return false;
    final mac = macAddress.trim();
    if (mac.isEmpty) return false;
    if (!await ensureReady()) return false;
    try {
      final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!connected) return false;
      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('ThermalPrinterBluetooth printBytes error: $e');
      return false;
    }
  }
}
