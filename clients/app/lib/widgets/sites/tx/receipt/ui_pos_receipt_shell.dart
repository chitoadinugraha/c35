import 'dart:io' show Platform;

import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:alienai_c35/c/hardware/thermal_tx_print.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/dialog/transaksi_printer_settings_dialog.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_preview.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Nota page: receipt preview, thermal print, share — no system ESC/POS print sheet when thermal is configured.
class UiPosReceiptShell extends StatefulWidget {
  const UiPosReceiptShell({
    super.key,
    required this.tx,
    required this.config,
    required this.productNames,
    this.alienId,
    this.site,
    this.autoPrintThermalOnOpen = false,
    this.doneLabel = 'Selesai',
  });

  final Tx tx;
  final ReceiptConfig config;
  final Map<String, String> productNames;
  final String? alienId;
  final SiteRow? site;
  final bool autoPrintThermalOnOpen;
  final String doneLabel;

  @override
  State<UiPosReceiptShell> createState() => _UiPosReceiptShellState();
}

class _UiPosReceiptShellState extends State<UiPosReceiptShell> {
  var _printing = false;
  var _sharing = false;
  var _autoPrinted = false;
  String? _printError;

  bool get _androidPos => !kIsWeb && Platform.isAndroid;

  bool get _thermalReady {
    final mgr = ThermalPrinterManager.instance;
    return mgr.isRawEscPosConfigured;
  }

  @override
  void initState() {
    super.initState();
    ThermalPrinterManager.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {});
      if (widget.autoPrintThermalOnOpen) {
        _autoPrintOnce();
      }
    });
  }

  Future<void> _autoPrintOnce() async {
    if (_autoPrinted || !_thermalReady) return;
    _autoPrinted = true;
    await _printThermal(silent: true);
  }

  Future<void> _printThermal({bool silent = false}) async {
    setState(() {
      _printing = true;
      if (!silent) _printError = null;
    });
    final ok = await printTxToThermalPrinter(
      tx: widget.tx,
      site: widget.site,
      productNames: widget.productNames,
      config: widget.config,
      alienId: widget.alienId,
    );
    if (!mounted) return;
    setState(() {
      _printing = false;
      if (!ok) {
        _printError = 'Gagal cetak ke printer thermal. Cek Bluetooth/Wi‑Fi di Printer settings.';
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_printError!), behavior: SnackBarBehavior.floating),
          );
        }
      } else if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota dikirim ke printer thermal'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await shareReceiptPdf(
        tx: widget.tx,
        config: widget.config,
        productNames: widget.productNames,
        alienId: widget.alienId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hideSystemPrint = _androidPos && _thermalReady;

    return Scaffold(
      backgroundColor: const Color(0xFF121215),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Nota', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: _sharing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_outlined),
            onPressed: _sharing ? null : _share,
          ),
          IconButton(
            tooltip: 'Printer settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showTransaksiPrinterSettingsDialog(context: context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_printError != null && _thermalReady)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _printError!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ),
          Expanded(
            child: ReceiptPdfPreview(
              tx: widget.tx,
              config: widget.config,
              productNames: widget.productNames,
              alienId: widget.alienId,
              embedded: true,
              allowSystemPrint: !hideSystemPrint,
              showPreviewActions: false,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_thermalReady) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printing ? null : () => _printThermal(),
                    icon: _printing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF4F4F5),
                      side: const BorderSide(color: Color(0xFF3F3F46)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      foregroundColor: const Color(0xFF052E1B),
                    ),
                    child: Text(
                      widget.doneLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
