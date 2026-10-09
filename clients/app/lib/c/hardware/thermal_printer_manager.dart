import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_bluetooth.dart';

enum ThermalPrinterType {
  network,
  bluetooth,
  pdfPreview,
}

class ThermalPrinterManager extends ChangeNotifier {
  ThermalPrinterManager._();
  static final ThermalPrinterManager instance = ThermalPrinterManager._();

  ThermalPrinterType printerType = ThermalPrinterType.pdfPreview;
  String networkIp = '192.168.1.200';
  int networkPort = 9100;
  int paperWidth = 32; // 32 for 58mm, 48 for 80mm
  bool autoKickDrawer = true;
  bool autoPrintReceipt = false;
  String bluetoothMac = '';
  String bluetoothName = '';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Sends raw ESC/POS (network or Bluetooth). PDF preview uses the printing package instead.
  bool get usesRawEscPos =>
      printerType == ThermalPrinterType.network ||
      printerType == ThermalPrinterType.bluetooth;

  static ThermalPrinterType printerTypeFromPref(String? typeStr) {
    switch (typeStr) {
      case 'network':
        return ThermalPrinterType.network;
      case 'bluetooth':
        return ThermalPrinterType.bluetooth;
      default:
        return ThermalPrinterType.pdfPreview;
    }
  }

  static String printerTypeToPref(ThermalPrinterType type) {
    switch (type) {
      case ThermalPrinterType.network:
        return 'network';
      case ThermalPrinterType.bluetooth:
        return 'bluetooth';
      case ThermalPrinterType.pdfPreview:
        return 'pdfPreview';
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) {
      await load();
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      printerType = printerTypeFromPref(prefs.getString('thermal_printer_type'));
      networkIp = prefs.getString('thermal_printer_ip') ?? '192.168.1.200';
      networkPort = prefs.getInt('thermal_printer_port') ?? 9100;
      paperWidth = prefs.getInt('thermal_printer_width') ?? 32;
      autoKickDrawer = prefs.getBool('thermal_printer_auto_kick') ?? true;
      autoPrintReceipt = prefs.getBool('thermal_printer_auto_print') ?? false;
      bluetoothMac = prefs.getString('thermal_printer_bt_mac') ?? '';
      bluetoothName = prefs.getString('thermal_printer_bt_name') ?? '';
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThermalPrinterManager load error: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('thermal_printer_type', printerTypeToPref(printerType));
      await prefs.setString('thermal_printer_ip', networkIp);
      await prefs.setInt('thermal_printer_port', networkPort);
      await prefs.setInt('thermal_printer_width', paperWidth);
      await prefs.setBool('thermal_printer_auto_kick', autoKickDrawer);
      await prefs.setBool('thermal_printer_auto_print', autoPrintReceipt);
      await prefs.setString('thermal_printer_bt_mac', bluetoothMac);
      await prefs.setString('thermal_printer_bt_name', bluetoothName);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThermalPrinterManager save error: $e');
    }
  }

  Future<bool> printRaw(Uint8List bytes) async {
    switch (printerType) {
      case ThermalPrinterType.network:
        return _printRawNetwork(bytes);
      case ThermalPrinterType.bluetooth:
        return ThermalPrinterBluetooth.printBytes(bytes, macAddress: bluetoothMac);
      case ThermalPrinterType.pdfPreview:
        return false;
    }
  }

  Future<bool> _printRawNetwork(Uint8List bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        networkIp,
        networkPort,
        timeout: const Duration(seconds: 4),
      );
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('Thermal printer printRaw error: $e');
      socket?.destroy();
      return false;
    }
  }

  Future<bool> kickCashDrawer() async {
    if (!usesRawEscPos) {
      return false;
    }
    return printRaw(Uint8List.fromList(const [0x1B, 0x70, 0x00, 0x19, 0xFA]));
  }

  String get _modeLabel {
    switch (printerType) {
      case ThermalPrinterType.network:
        return 'ESC/POS Net';
      case ThermalPrinterType.bluetooth:
        return 'ESC/POS BT';
      case ThermalPrinterType.pdfPreview:
        return 'PDF Preview';
    }
  }

  Future<bool> testPrint() async {
    final builder = EscPosBuilder();
    builder.reset();
    builder.alignCenter();
    builder.textLine(
      '=== TEST PRINT ===',
      bold: true,
      align: EscPosAlign.center,
      size: 2,
    );
    builder.feed(1);
    builder.textLine('Thermal Printer Ready');
    builder.textLine(DateTime.now().toLocal().toString().split('.').first);
    builder.hr(totalWidth: paperWidth);
    builder.row('Mode', _modeLabel, totalWidth: paperWidth);
    if (printerType == ThermalPrinterType.bluetooth && bluetoothName.isNotEmpty) {
      builder.row('Printer', bluetoothName, totalWidth: paperWidth);
    }
    builder.row('Width', '$paperWidth columns', totalWidth: paperWidth);
    builder.row(
      'Drawer Kick',
      autoKickDrawer ? 'Enabled' : 'Disabled',
      totalWidth: paperWidth,
    );
    builder.hr(totalWidth: paperWidth);
    builder.feed(3);
    builder.cutPaper();
    return printRaw(builder.bytes());
  }
}
