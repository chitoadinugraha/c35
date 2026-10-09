import 'package:alienai_c35/c/media/media_disk_cache.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

class ReceiptBusinessInfo {
  static final Map<String, Uint8List?> _processedLogoCache = {};
  static final Map<String, Future<Uint8List?>> _logoInflight = {};

  @visibleForTesting
  static void clearLogoCacheForTest() {
    _processedLogoCache.clear();
    _logoInflight.clear();
  }
  static pw.Widget build(ReceiptConfig config, {Uint8List? logoData}) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoData != null && logoData.isNotEmpty) ...[
            pw.Image(
              pw.MemoryImage(logoData),
              width: config.logoSizePx.toDouble(),
              fit: pw.BoxFit.contain,
            ),
            pw.SizedBox(height: 8),
          ],
          if (config.showSiteName && config.projectName.isNotEmpty)
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

  /// Warm disk cache for [path] (site icon). Safe to call before opening receipt / print.
  static Future<void> prefetchLogo(String? path) async {
    final loadPath = path?.trim() ?? '';
    if (loadPath.isEmpty) return;
    if (loadPath.toLowerCase().endsWith('.svg') || loadPath.startsWith('iconify://')) return;
    await _loadLogoRawBytes(loadPath);
  }

  static Future<Uint8List?> loadLogo([String? path]) async {
    final loadPath = path?.trim() ?? '';
    if (loadPath.isEmpty) return null;
    if (loadPath.toLowerCase().endsWith('.svg') || loadPath.startsWith('iconify://')) return null;

    final cached = _processedLogoCache[loadPath];
    if (cached != null) return cached.isEmpty ? null : cached;
    if (_processedLogoCache.containsKey(loadPath)) return null;

    final inflight = _logoInflight[loadPath];
    if (inflight != null) return inflight;

    final future = _loadLogoOnce(loadPath);
    _logoInflight[loadPath] = future;
    try {
      final out = await future;
      _processedLogoCache[loadPath] = out ?? Uint8List(0);
      return out;
    } finally {
      _logoInflight.remove(loadPath);
    }
  }

  static Future<Uint8List?> _loadLogoOnce(String loadPath) async {
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
      final raw = await _loadLogoRawBytes(loadPath);
      if (raw == null) return null;
      return _pdfSafeImageBytes(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _loadLogoRawBytes(String loadPath) async {
    final file = await mediaDiskCacheFetch(loadPath);
    if (file != null) return file.readAsBytes();
    final guest = guestSitePicUrl(loadPath);
    if (guest.isEmpty || guest == mediaUrlResolve(loadPath)) return null;
    final guestFile = await mediaDiskCacheFetch(guest);
    return guestFile?.readAsBytes();
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
