import 'package:alienai_c35/c/hardware/esc_pos_raster.dart';
import 'package:alienai_c35/c/hardware/thermal_printer_manager.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/esc_pos_receipt_formatter.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/esc_pos_receipt_from_pdf.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_pdf_generator.dart';

ReceiptConfig _thermalReceiptConfig(ReceiptConfig cfg, int paperWidthMm) => ReceiptConfig(
      projectName: cfg.projectName,
      projectLogo: cfg.projectLogo,
      receiptHeader: cfg.receiptHeader,
      receiptFooter: cfg.receiptFooter,
      projectAddress: cfg.projectAddress,
      projectContact: cfg.projectContact,
      showQrLink: cfg.showQrLink,
      showSiteName: cfg.showSiteName,
      marginMm: 0,
      paperWidthMm: paperWidthMm,
      logoSizePx: cfg.logoSizePx,
    );

/// Prints a sale receipt as raw ESC/POS when network or Bluetooth mode is configured.
///
/// Uses the receipt PDF rasterized to bitmap (same layout as preview). Falls back to
/// text ESC/POS only if rasterization fails.
Future<bool> printTxToThermalPrinter({
  required Tx tx,
  SiteRow? site,
  Map<String, String>? productNames,
  ReceiptConfig? config,
  String? alienId,
}) async {
  final mgr = ThermalPrinterManager.instance;
  await mgr.ensureLoaded();
  if (!mgr.isRawEscPosConfigured) return false;

  final baseCfg = config ?? receiptConfigOf(site);
  final paperMm = thermalPaperWidthMmFromChars(mgr.paperWidth);
  final cfg = _thermalReceiptConfig(baseCfg, paperMm);

  final pdf = await ReceiptPdfGenerator.generate(
    tx,
    cfg,
    productNames: productNames ?? const {},
    alienId: alienId,
  );

  final fromPdf = await tryEscPosBytesFromReceiptPdf(
    pdfBytes: pdf,
    paperWidthMm: paperMm,
    kickDrawer: mgr.autoKickDrawer,
  );

  final bytes = fromPdf ??
      await EscPosReceiptFormatter.formatReceipt(
        tx,
        site: site,
        productNames: productNames,
        paperWidth: mgr.paperWidth,
        config: cfg,
        kickDrawer: mgr.autoKickDrawer,
      );

  return mgr.printRaw(bytes);
}
