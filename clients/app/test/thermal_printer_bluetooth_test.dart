import 'package:alienai_c35/c/hardware/thermal_printer_bluetooth.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThermalPrinterManager bluetooth prefs', () {
    test('printerTypeFromPref maps bluetooth', () {
      expect(
        ThermalPrinterManager.printerTypeFromPref('bluetooth'),
        ThermalPrinterType.bluetooth,
      );
      expect(
        ThermalPrinterManager.printerTypeToPref(ThermalPrinterType.bluetooth),
        'bluetooth',
      );
    });

    test('usesRawEscPos includes network and bluetooth only', () {
      final mgr = ThermalPrinterManager.instance;
      mgr.printerType = ThermalPrinterType.pdfPreview;
      expect(mgr.usesRawEscPos, isFalse);
      mgr.printerType = ThermalPrinterType.network;
      expect(mgr.usesRawEscPos, isTrue);
      mgr.printerType = ThermalPrinterType.bluetooth;
      expect(mgr.usesRawEscPos, isTrue);
    });

    test('isRawEscPosConfigured requires bluetooth MAC', () {
      final mgr = ThermalPrinterManager.instance;
      mgr.printerType = ThermalPrinterType.bluetooth;
      mgr.bluetoothMac = '';
      expect(mgr.isRawEscPosConfigured, isFalse);
      mgr.bluetoothMac = 'AA:BB:CC:DD:EE:FF';
      expect(mgr.isRawEscPosConfigured, isTrue);
    });
  });

  group('ThermalPrinterBluetooth', () {
    test('isSupported is false in VM tests', () {
      expect(ThermalPrinterBluetooth.isSupported, isFalse);
    });
  });
}
