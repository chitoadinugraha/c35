import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';

enum ThermalPrinterType {
  network,
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

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (!_loaded) {
      await load();
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeStr = prefs.getString('thermal_printer_type');
      if (typeStr == 'network') {
        printerType = ThermalPrinterType.network;
      } else {
        printerType = ThermalPrinterType.pdfPreview;
      }
      networkIp = prefs.getString('thermal_printer_ip') ?? '192.168.1.200';
      networkPort = prefs.getInt('thermal_printer_port') ?? 9100;
      paperWidth = prefs.getInt('thermal_printer_width') ?? 32;
      autoKickDrawer = prefs.getBool('thermal_printer_auto_kick') ?? true;
      autoPrintReceipt = prefs.getBool('thermal_printer_auto_print') ?? false;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThermalPrinterManager load error: $e');
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'thermal_printer_type',
        printerType == ThermalPrinterType.network ? 'network' : 'pdfPreview',
      );
      await prefs.setString('thermal_printer_ip', networkIp);
      await prefs.setInt('thermal_printer_port', networkPort);
      await prefs.setInt('thermal_printer_width', paperWidth);
      await prefs.setBool('thermal_printer_auto_kick', autoKickDrawer);
      await prefs.setBool('thermal_printer_auto_print', autoPrintReceipt);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThermalPrinterManager save error: $e');
    }
  }

  Future<bool> printRaw(Uint8List bytes) async {
    if (printerType != ThermalPrinterType.network) {
      return false;
    }
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
    if (printerType != ThermalPrinterType.network) {
      return false;
    }
    return printRaw(Uint8List.fromList(const [0x1B, 0x70, 0x00, 0x19, 0xFA]));
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
    builder.row(
      'Mode',
      printerType == ThermalPrinterType.network ? 'ESC/POS Net' : 'PDF Preview',
      totalWidth: paperWidth,
    );
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
