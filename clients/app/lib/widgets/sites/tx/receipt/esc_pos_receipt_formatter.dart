import 'dart:convert';
import 'dart:typed_data';

import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';
import 'package:alienai_c35/c/hardware/esc_pos_raster.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_business_info.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/esc_pos_receipt_branding.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config_of.dart';
import 'package:fixnum/fixnum.dart';

/// Thermal receipt formatter producing standard raw ESC/POS byte streams.
///
/// Designed for 58mm (32 chars) and 80mm (48 chars) thermal receipt printers.
class EscPosReceiptFormatter {
  const EscPosReceiptFormatter();

  /// Formats a transaction into raw ESC/POS printer bytes.
  Future<Uint8List> format(
    Tx tx, {
    ReceiptConfig? config,
    SiteRow? site,
    Map<String, String>? productNames,
    int paperWidth = 32,
    bool kickDrawer = false,
    String? watermark,
  }) =>
      formatReceipt(
        tx,
        config: config,
        site: site,
        productNames: productNames,
        paperWidth: paperWidth,
        kickDrawer: kickDrawer,
        watermark: watermark,
      );

  /// Formats a transaction [tx] into raw ESC/POS bytes.
  ///
  /// Can be invoked statically via [EscPosReceiptFormatter.formatReceipt].
  static Future<Uint8List> formatReceipt(
    Tx tx, {
    ReceiptConfig? config,
    SiteRow? site,
    Map<String, String>? productNames,
    int paperWidth = 32,
    bool kickDrawer = false,
    String? watermark,
  }) async {
    final builder = EscPosBuilder();
    builder.reset();

    // 0. Cash drawer pulse (if enabled, kick drawer at start of printing)
    if (kickDrawer) {
      builder.kickCashDrawer();
    }

    final cfg = config ?? receiptConfigOf(site);
    final businessName = cfg.projectName.isNotEmpty
        ? cfg.projectName
        : (site?.name.isNotEmpty == true ? site!.name : 'Toko');

    // 1. Header Section
    if (cfg.receiptHeader.isNotEmpty) {
      builder.textLine(cfg.receiptHeader, align: EscPosAlign.center);
    }

    final logoPath = cfg.projectLogo.trim();
    if (logoPath.isNotEmpty) {
      final logoBytes = await ReceiptBusinessInfo.loadLogo(logoPath);
      if (logoBytes != null) {
        final raster = escPosRasterFromImageBytes(
          logoBytes,
          maxWidthDots: escPosMaxWidthDots(paperWidth),
        );
        if (raster != null) {
          builder.rasterBitImage(raster);
          builder.feed(1);
        }
      }
    }

    if (cfg.showSiteName) {
      builder.textLine(
        businessName,
        bold: true,
        align: EscPosAlign.center,
        size: 2,
      );
    }

    // Business Address & Contact
    if (cfg.projectAddress.isNotEmpty) {
      builder.textLine(cfg.projectAddress, align: EscPosAlign.center);
    }
    if (cfg.projectContact.isNotEmpty) {
      builder.textLine(cfg.projectContact, align: EscPosAlign.center);
    }

    builder.hr(totalWidth: paperWidth);

    // 2. Transaction Info Section
    final id = txReceiptId(tx);
    final receiptId = id.isNotEmpty ? '#$id' : 'Nota Baru';
    builder.row('No. Nota', receiptId, totalWidth: paperWidth);

    final timeStr = tx.hasCreatedTsMs()
        ? receiptFmtTs(tx.createdTsMs)
        : (tx.hasTimeTsMs() ? receiptFmtTs(tx.timeTsMs) : '');
    if (timeStr.isNotEmpty) {
      builder.row('Waktu', timeStr, totalWidth: paperWidth);
    }

    if (tx.cashierName.isNotEmpty) {
      builder.row('Kasir', tx.cashierName, totalWidth: paperWidth);
    }
    if (tx.subjectName.isNotEmpty) {
      builder.row('Pelanggan', tx.subjectName, totalWidth: paperWidth);
    }

    builder.hr(totalWidth: paperWidth);

    // 3. Items Section
    final validItems = tx.items.where((i) => i.qty > 0).toList();
    for (final item in validItems) {
      final name = _resolveItemName(item, productNames);
      final lineNet = receiptItemLineTotal(item);
      final unitPrice = item.price.toInt();

      builder.textLine(name);
      final qtyPrice = '  ${item.qty} x ${receiptMoney(unitPrice)}';
      builder.row(qtyPrice, receiptMoney(lineNet), totalWidth: paperWidth);

      if (item.totalDiscount > Int64.ZERO) {
        builder.row(
          '    (Diskon)',
          '-${receiptMoney(item.totalDiscount.toInt())}',
          totalWidth: paperWidth,
        );
      }
      if (item.note.isNotEmpty) {
        builder.textLine('    ${item.note}');
      }
    }

    builder.hr(totalWidth: paperWidth);

    // 4. Totals Section
    final totals = ReceiptTxTotals.fromTx(tx);
    builder.row('Subtotal', receiptMoney(totals.subtotal), totalWidth: paperWidth);

    for (final d in tx.discounts) {
      final label = d.note.isNotEmpty ? d.note : 'Diskon';
      builder.row(label, '-${receiptMoney(d.amount.toInt())}', totalWidth: paperWidth);
    }

    for (final t in tx.taxes) {
      final label = t.taxType.isNotEmpty ? t.taxType : 'Pajak';
      builder.row(label, receiptMoney(t.amount.toInt()), totalWidth: paperWidth);
    }

    builder.hr(char: '=', totalWidth: paperWidth);
    builder.bold(true);
    builder.row('Total', receiptMoney(totals.total), totalWidth: paperWidth);
    builder.bold(false);
    builder.hr(totalWidth: paperWidth);

    // 5. Payments Breakdown
    int totalChange = 0;
    bool hasTenderedData = false;

    for (final p in tx.payments) {
      final methodLabel = txPaymentMethodLabel(p.method);
      int? tendered;
      int? change;

      if (p.paymentJson.isNotEmpty) {
        try {
          final parsed = jsonDecode(p.paymentJson);
          if (parsed is Map) {
            if (parsed['tendered'] is num) {
              tendered = (parsed['tendered'] as num).toInt();
            }
            if (parsed['change'] is num) {
              change = (parsed['change'] as num).toInt();
            }
          }
        } catch (_) {}
      }

      if (tendered != null && tendered > 0) {
        hasTenderedData = true;
        if (change != null) totalChange += change;
        builder.row(
          'Bayar ($methodLabel)',
          receiptMoney(tendered),
          totalWidth: paperWidth,
        );
      } else {
        builder.row(
          'Bayar ($methodLabel)',
          receiptMoney(p.amount.toInt()),
          totalWidth: paperWidth,
        );
      }
    }

    // Change Due / Kembalian
    if (hasTenderedData && totalChange > 0) {
      builder.row('Kembalian', receiptMoney(totalChange), totalWidth: paperWidth);
    } else if (totals.paid > totals.total) {
      builder.row('Kembalian', receiptMoney(totals.paid - totals.total), totalWidth: paperWidth);
    }

    if (totals.due > 0) {
      builder.bold(true);
      builder.row('Belum Dibayar', receiptMoney(totals.due), totalWidth: paperWidth);
      builder.bold(false);
    }

    // Payment status (matches PDF ReceiptStatus)
    final isPaid = totals.paid >= totals.total;
    builder.feed(1);
    builder.bold(true);
    builder.textLine(
      isPaid ? 'LUNAS' : 'BELUM LUNAS',
      align: EscPosAlign.center,
      size: 2,
    );
    builder.bold(false);
    builder.feed(1);

    // 6. Footer Section
    if (cfg.receiptFooter.isNotEmpty) {
      builder.textLine(cfg.receiptFooter, align: EscPosAlign.center);
    } else {
      builder.textLine('Terima Kasih atas Kunjungan Anda', align: EscPosAlign.center);
    }

    if (watermark != null && watermark!.trim().isNotEmpty) {
      builder.textLine(watermark!.trim(), align: EscPosAlign.center);
    }

    await escPosAppendPoweredFooter(builder, paperWidth: paperWidth);

    // 7. Feed & Cut
    builder.feed(4);
    builder.cutPaper();

    return builder.bytes();
  }

  static String _resolveItemName(TxItem item, Map<String, String>? productNames) {
    if (item.productId <= Int64.ZERO) {
      return item.note.isNotEmpty ? item.note : 'Item';
    }
    final pid = item.productId.toString();
    return productNames?[pid] ?? (item.note.isNotEmpty ? item.note : 'Item #$pid');
  }
}
