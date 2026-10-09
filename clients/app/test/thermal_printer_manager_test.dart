import 'dart:typed_data';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThermalPrinterManager', () {
    final mgr = ThermalPrinterManager.instance;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await mgr.load();
    });

    test('default settings are correctly initialized', () {
      expect(mgr.printerType, ThermalPrinterType.pdfPreview);
      expect(mgr.networkIp, '192.168.1.200');
      expect(mgr.networkPort, 9100);
      expect(mgr.paperWidth, 32);
      expect(mgr.autoKickDrawer, isTrue);
      expect(mgr.autoPrintReceipt, isFalse);
    });

    test('save and load persistence works with SharedPreferences', () async {
      mgr.printerType = ThermalPrinterType.network;
      mgr.networkIp = '10.0.0.50';
      mgr.networkPort = 9101;
      mgr.paperWidth = 48;
      mgr.autoKickDrawer = false;
      mgr.autoPrintReceipt = true;

      await mgr.save();

      // Reset in memory to defaults and reload
      mgr.printerType = ThermalPrinterType.pdfPreview;
      mgr.networkIp = '192.168.1.200';
      mgr.networkPort = 9100;
      mgr.paperWidth = 32;
      mgr.autoKickDrawer = true;
      mgr.autoPrintReceipt = false;

      await mgr.load();

      expect(mgr.printerType, ThermalPrinterType.network);
      expect(mgr.networkIp, '10.0.0.50');
      expect(mgr.networkPort, 9101);
      expect(mgr.paperWidth, 48);
      expect(mgr.autoKickDrawer, isFalse);
      expect(mgr.autoPrintReceipt, isTrue);
    });

    test('kickCashDrawer returns false when not raw ESC/POS printer', () async {
      mgr.printerType = ThermalPrinterType.pdfPreview;
      final ok = await mgr.kickCashDrawer();
      expect(ok, isFalse);
    });

    test('printRaw returns false when pdf preview mode', () async {
      mgr.printerType = ThermalPrinterType.pdfPreview;
      final ok = await mgr.printRaw(Uint8List.fromList([0x1B, 0x40]));
      expect(ok, isFalse);
    });

    test('printRaw returns false for bluetooth without mac on test host', () async {
      mgr.printerType = ThermalPrinterType.bluetooth;
      mgr.bluetoothMac = '';
      final ok = await mgr.printRaw(Uint8List.fromList([0x1B, 0x40]));
      expect(ok, isFalse);
    });

    test('save and load persists bluetooth fields', () async {
      mgr.printerType = ThermalPrinterType.bluetooth;
      mgr.bluetoothMac = 'AA:BB:CC:DD:EE:FF';
      mgr.bluetoothName = 'Test Printer';
      await mgr.save();
      mgr.bluetoothMac = '';
      mgr.bluetoothName = '';
      await mgr.load();
      expect(mgr.printerType, ThermalPrinterType.bluetooth);
      expect(mgr.bluetoothMac, 'AA:BB:CC:DD:EE:FF');
      expect(mgr.bluetoothName, 'Test Printer');
    });

    test('printRaw handles unreachable socket gracefully without throwing', () async {
      mgr.printerType = ThermalPrinterType.network;
      mgr.networkIp = '127.0.0.1';
      mgr.networkPort = 65530; // Unbound port
      final ok = await mgr.printRaw(Uint8List.fromList([0x1B, 0x40]));
      expect(ok, isFalse);
    });
  });
}
