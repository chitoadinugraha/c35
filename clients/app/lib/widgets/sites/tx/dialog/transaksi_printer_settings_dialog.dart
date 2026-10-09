import 'dart:io' show Platform;

import 'package:alienai_c35/c/hardware/thermal_printer_bluetooth.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<void> showTransaksiPrinterSettingsDialog({
  required BuildContext context,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => const TransaksiPrinterSettingsDialog(),
    );

class TransaksiPrinterSettingsDialog extends StatefulWidget {
  const TransaksiPrinterSettingsDialog({super.key});

  @override
  State<TransaksiPrinterSettingsDialog> createState() =>
      _TransaksiPrinterSettingsDialogState();
}

class _TransaksiPrinterSettingsDialogState
    extends State<TransaksiPrinterSettingsDialog> {
  late ThermalPrinterType _printerType;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _portCtrl;
  late int _paperWidth;
  late bool _autoKickDrawer;
  late bool _autoPrintReceipt;

  var _testingPrint = false;
  var _testingDrawer = false;
  String? _statusMsg;
  bool _statusSuccess = false;
  List<ThermalBluetoothDevice> _pairedBt = [];
  var _loadingBt = false;
  String _bluetoothMac = '';
  String _bluetoothName = '';

  bool get _bluetoothModeAvailable => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    final mgr = ThermalPrinterManager.instance;
    _printerType = mgr.printerType;
    _ipCtrl = TextEditingController(text: mgr.networkIp);
    _portCtrl = TextEditingController(text: mgr.networkPort.toString());
    _paperWidth = mgr.paperWidth;
    _autoKickDrawer = mgr.autoKickDrawer;
    _autoPrintReceipt = mgr.autoPrintReceipt;
    _bluetoothMac = mgr.bluetoothMac;
    _bluetoothName = mgr.bluetoothName;
    if (_bluetoothModeAvailable && _printerType == ThermalPrinterType.bluetooth) {
      _refreshPairedBluetooth();
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _applyToManager() {
    final mgr = ThermalPrinterManager.instance;
    mgr.printerType = _printerType;
    mgr.networkIp = _ipCtrl.text.trim();
    final parsedPort = int.tryParse(_portCtrl.text.trim());
    if (parsedPort != null && parsedPort > 0) {
      mgr.networkPort = parsedPort;
    }
    mgr.paperWidth = _paperWidth;
    mgr.autoKickDrawer = _autoKickDrawer;
    mgr.autoPrintReceipt = _autoPrintReceipt;
    mgr.bluetoothMac = _bluetoothMac;
    mgr.bluetoothName = _bluetoothName;
  }

  Future<void> _refreshPairedBluetooth() async {
    if (!_bluetoothModeAvailable) return;
    setState(() => _loadingBt = true);
    final list = await ThermalPrinterBluetooth.pairedDevices();
    if (!mounted) return;
    setState(() {
      _loadingBt = false;
      _pairedBt = list;
      if (_bluetoothMac.isNotEmpty &&
          !list.any((d) => d.macAddress == _bluetoothMac)) {
        if (list.isNotEmpty) {
          _bluetoothMac = list.first.macAddress;
          _bluetoothName = list.first.name;
        }
      } else if (_bluetoothMac.isEmpty && list.isNotEmpty) {
        _bluetoothMac = list.first.macAddress;
        _bluetoothName = list.first.name;
      }
    });
  }

  Future<void> _testPrint() async {
    _applyToManager();
    setState(() {
      _testingPrint = true;
      _statusMsg = null;
    });
    final ok = await ThermalPrinterManager.instance.testPrint();
    if (mounted) {
      setState(() {
        _testingPrint = false;
        _statusSuccess = ok;
        _statusMsg = ok
            ? 'Test print sent successfully!'
            : (_printerType == ThermalPrinterType.bluetooth
                ? 'Failed to print via Bluetooth (${_bluetoothMac.isEmpty ? 'no printer selected' : _bluetoothMac})'
                : 'Failed to connect to printer at ${_ipCtrl.text.trim()}:${_portCtrl.text.trim()}');
      });
    }
  }

  Future<void> _testDrawer() async {
    _applyToManager();
    setState(() {
      _testingDrawer = true;
      _statusMsg = null;
    });
    final ok = await ThermalPrinterManager.instance.kickCashDrawer();
    if (mounted) {
      setState(() {
        _testingDrawer = false;
        _statusSuccess = ok;
        _statusMsg = ok
            ? 'Cash drawer pulse sent!'
            : (_printerType == ThermalPrinterType.bluetooth
                ? 'Failed to open drawer via Bluetooth'
                : 'Failed to trigger drawer at ${_ipCtrl.text.trim()}:${_portCtrl.text.trim()}');
      });
    }
  }

  Future<void> _saveAndClose() async {
    _applyToManager();
    await ThermalPrinterManager.instance.save();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = _printerType == ThermalPrinterType.network;
    final isBluetooth = _printerType == ThermalPrinterType.bluetooth;
    final isRawEscPos = isNetwork || isBluetooth;

    return AlertDialog(
      backgroundColor: const Color(0xFF121215),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.print_outlined, color: _accent, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Printer Settings',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _muted, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Selector
              const Text(
                'Printing Mode',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _modeOption(
                      title: 'Network ESC/POS',
                      subtitle: 'Raw socket 9100',
                      selected: isNetwork,
                      onTap: () => setState(
                          () => _printerType = ThermalPrinterType.network),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeOption(
                      title: 'System / PDF',
                      subtitle: 'Preview & system print',
                      selected: _printerType == ThermalPrinterType.pdfPreview,
                      onTap: () => setState(
                          () => _printerType = ThermalPrinterType.pdfPreview),
                    ),
                  ),
                ],
              ),
              if (_bluetoothModeAvailable) ...[
                const SizedBox(height: 8),
                _modeOption(
                  title: 'Bluetooth ESC/POS',
                  subtitle: 'Paired thermal printer (Android)',
                  selected: isBluetooth,
                  onTap: () {
                    setState(() => _printerType = ThermalPrinterType.bluetooth);
                    _refreshPairedBluetooth();
                  },
                ),
              ],
              const SizedBox(height: 16),

              if (isBluetooth) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Paired printer',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadingBt ? null : _refreshPairedBluetooth,
                      icon: _loadingBt
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_pairedBt.isEmpty)
                  Text(
                    _loadingBt
                        ? 'Loading paired devices…'
                        : 'No paired printers. Pair in Android Settings → Bluetooth, then tap Refresh.',
                    style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 11),
                  )
                else
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use — controlled selection updates on refresh
                    value: _bluetoothMac.isNotEmpty ? _bluetoothMac : null,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(color: _text, fontSize: 13),
                    decoration: _inputDecoration('Select printer'),
                    items: _pairedBt
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.macAddress,
                            child: Text(
                              d.name.isNotEmpty ? '${d.name} (${d.macAddress})' : d.macAddress,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (mac) {
                      if (mac == null) return;
                      final match = _pairedBt.where((d) => d.macAddress == mac).toList();
                      setState(() {
                        _bluetoothMac = mac;
                        _bluetoothName = match.isNotEmpty ? match.first.name : '';
                      });
                    },
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Paper Width',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _choiceChip(
                        label: '58 mm (32 col)',
                        selected: _paperWidth == 32,
                        onTap: () => setState(() => _paperWidth = 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceChip(
                        label: '80 mm (48 col)',
                        selected: _paperWidth == 48,
                        onTap: () => setState(() => _paperWidth = 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Network inputs (if network selected)
              if (isNetwork) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Printer IP Address',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ipCtrl,
                            style: const TextStyle(color: _text, fontSize: 13),
                            decoration: _inputDecoration('192.168.1.200'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Port',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _portCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: _text, fontSize: 13),
                            decoration: _inputDecoration('9100'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Paper Width selector
                const Text(
                  'Paper Width',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _choiceChip(
                        label: '58 mm (32 col)',
                        selected: _paperWidth == 32,
                        onTap: () => setState(() => _paperWidth = 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceChip(
                        label: '80 mm (48 col)',
                        selected: _paperWidth == 48,
                        onTap: () => setState(() => _paperWidth = 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Toggles
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _toggleRow(
                      title: 'Auto-kick cash drawer on cash sale',
                      subtitle: 'Sends pulse to cash drawer on cash payment',
                      value: _autoKickDrawer,
                      onChanged: (v) => setState(() => _autoKickDrawer = v),
                    ),
                    const Divider(height: 1, color: _border),
                    _toggleRow(
                      title: 'Auto-print on save',
                      subtitle: 'Immediately print receipt when sale is saved',
                      value: _autoPrintReceipt,
                      onChanged: (v) => setState(() => _autoPrintReceipt = v),
                    ),
                  ],
                ),
              ),

              // Test Buttons (raw ESC/POS)
              if (isRawEscPos) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingPrint ? null : _testPrint,
                        icon: _testingPrint
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _accent,
                                ),
                              )
                            : const Icon(Icons.print, size: 16),
                        label: const Text('Test Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingDrawer ? null : _testDrawer,
                        icon: _testingDrawer
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF59E0B),
                                ),
                              )
                            : const Icon(Icons.point_of_sale, size: 16),
                        label: const Text('Test Open Drawer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Status message feedback
              if (_statusMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _statusSuccess
                        ? _accent.withValues(alpha: 0.15)
                        : Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusSuccess ? _accent : Colors.redAccent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusSuccess
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 16,
                        color: _statusSuccess ? _accent : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMsg!,
                          style: TextStyle(
                            color: _statusSuccess ? _accent : Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: _muted)),
        ),
        FilledButton(
          onPressed: _saveAndClose,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: const Color(0xFF052E1B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Settings'),
        ),
      ],
    );
  }

  Widget _modeOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.1)
                : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _accent : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 16,
                    color: selected ? _accent : _muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: selected ? _text : _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: _muted.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.15)
                : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? _accent : _border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _accent : _muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _muted.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: _accent,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF27272A).withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent),
        ),
      );
}
