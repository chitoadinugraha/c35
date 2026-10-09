import 'dart:io' show Platform;

import 'package:alienai_c35/c/hardware/thermal_bluetooth_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ThermalBluetoothDevice {
  const ThermalBluetoothDevice({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}

/// Android Bluetooth Classic transport for raw ESC/POS bytes (in-app; no third-party plugin).
class ThermalPrinterBluetooth {
  const ThermalPrinterBluetooth._();

  static const MethodChannel _channel = MethodChannel('id.alienai/thermal_bluetooth');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<bool> ensureReady() async {
    if (!isSupported) return false;
    if (!await thermalBluetoothPermissionEnsure()) return false;
    if (!await bluetoothEnabled) return false;
    return true;
  }

  static Future<bool> get bluetoothEnabled async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('bluetoothEnabled') ?? false;
    } catch (e) {
      debugPrint('ThermalPrinterBluetooth bluetoothEnabled error: $e');
      return false;
    }
  }

  static Future<List<ThermalBluetoothDevice>> pairedDevices() async {
    if (!isSupported) return [];
    if (!await ensureReady()) return [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('pairedDevices');
      if (raw == null) return [];
      return raw.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return ThermalBluetoothDevice(
          name: map['name']?.toString() ?? '',
          macAddress: map['mac']?.toString() ?? '',
        );
      }).where((d) => d.macAddress.isNotEmpty).toList();
    } catch (e) {
      debugPrint('ThermalPrinterBluetooth pairedDevices error: $e');
      return [];
    }
  }

  static Future<bool> printBytes(List<int> bytes, {required String macAddress}) async {
    if (!isSupported) return false;
    final mac = macAddress.trim();
    if (mac.isEmpty) return false;
    if (!await ensureReady()) return false;
    try {
      return await _channel.invokeMethod<bool>('printBytes', {
            'mac': mac,
            'bytes': bytes,
          }) ??
          false;
    } catch (e) {
      debugPrint('ThermalPrinterBluetooth printBytes error: $e');
      return false;
    }
  }
}
