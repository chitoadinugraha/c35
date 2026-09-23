import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_calc.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

const _qrScale = 2;
const _qrNote = 'Scan untuk lihat progress / cek keaslian nota';

class ReceiptQr {
  static Future<Uint8List?> _qrCodeToPng(String url) async {
    try {
      final qrCode = QrCode.fromData(data: url, errorCorrectLevel: QrErrorCorrectLevel.L);
      final qrImage = QrImage(qrCode);
      final count = qrImage.moduleCount;
      final size = count * _qrScale;
      final image = img.Image(width: size, height: size);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      for (var y = 0; y < count; y++) {
        for (var x = 0; x < count; x++) {
          if (qrImage.isDark(y, x)) {
            img.fillRect(
              image,
              x1: x * _qrScale,
              y1: y * _qrScale,
              x2: (x + 1) * _qrScale,
              y2: (y + 1) * _qrScale,
              color: img.ColorRgb8(0, 0, 0),
            );
          }
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Widget?> build(Tx tx, ReceiptConfig config, {String? alienId}) async {
    if (!config.showQrLink) return null;
    final txId = txReceiptId(tx);
    final siteId = alienId?.trim() ?? '';
    if (txId.isEmpty || siteId.isEmpty) return null;
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    final url = '$origin/$siteId/tx/$txId';
    final qrBytes = await _qrCodeToPng(url);
    if (qrBytes == null) return null;
    return pw.Center(
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Image(pw.MemoryImage(qrBytes), width: 60, height: 60),
          pw.SizedBox(height: 4),
          pw.Text(_qrNote, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }
}
