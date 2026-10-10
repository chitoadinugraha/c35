import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';
import 'package:alienai_c35/c/hardware/esc_pos_raster.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/parts/receipt_branding.dart';
import 'package:alienai_c35/widgets/sites/ui_powered_by_alien.dart';

/// Centered "Powered by" + Alien icon + "alienai.id" on text-mode thermal receipts (matches PDF).
Future<void> escPosAppendPoweredFooter(EscPosBuilder builder, {int paperWidth = 32}) async {
  builder.feed(1);
  builder.textLine('Powered by', align: EscPosAlign.center);
  final icon = await ReceiptBranding.loadAlienIcon();
  if (icon != null && icon.isNotEmpty) {
    final raster = escPosRasterFromImageBytes(
      icon,
      maxWidthDots: paperWidth <= 32 ? 28 : 36,
    );
    if (raster != null) {
      builder.rasterBitImage(raster, align: EscPosAlign.center);
      builder.feed(1);
    }
  }
  builder.textLine(UiPoweredByAlien.brandLabel, align: EscPosAlign.center, bold: true);
}
