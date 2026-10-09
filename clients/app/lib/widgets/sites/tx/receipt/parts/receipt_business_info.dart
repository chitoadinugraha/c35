import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

class ReceiptBusinessInfo {
  static pw.Widget build(ReceiptConfig config, {Uint8List? logoData}) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoData != null && logoData.isNotEmpty) ...[
            pw.Image(pw.MemoryImage(logoData), width: 60, height: 60),
            pw.SizedBox(height: 8),
          ],
          if (config.projectName.isNotEmpty)
            pw.Text(
              config.projectName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          if (config.projectAddress.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(config.projectAddress, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
          ],
          if (config.projectContact.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(config.projectContact, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(height: 1, thickness: 0.5),
          pw.SizedBox(height: 12),
        ],
      );

  static Future<Uint8List?> loadLogo([String? path]) async {
    final loadPath = path?.trim() ?? '';
    if (loadPath.isEmpty) return null;
    if (loadPath.toLowerCase().endsWith('.svg') || loadPath.startsWith('iconify://')) return null;
    if (!loadPath.startsWith('http://') &&
        !loadPath.startsWith('https://') &&
        !loadPath.startsWith('/fs/') &&
        !loadPath.startsWith('fs/')) {
      try {
        final data = await rootBundle.load(loadPath);
        return _pdfSafeImageBytes(data.buffer.asUint8List());
      } catch (_) {
        return null;
      }
    }
    try {
      final file = await mediaDiskCacheFetch(loadPath);
      if (file == null) return null;
      return _pdfSafeImageBytes(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static Uint8List? pdfSafeImageBytesForReceipt(Uint8List raw) => _pdfSafeImageBytes(raw);

  /// PDF `MemoryImage` mishandles PNG alpha (logo prints as a black square).
  static Uint8List? _pdfSafeImageBytes(Uint8List raw) {
    if (raw.isEmpty) return null;
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final flat = img.Image(width: decoded.width, height: decoded.height);
    img.fill(flat, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(flat, decoded);
    return Uint8List.fromList(img.encodeJpg(flat, quality: 92));
  }
}
