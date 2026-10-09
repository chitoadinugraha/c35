import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';

bool voucherCameraScan() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<String?> voucherScanCode(BuildContext context) {
  if (voucherCameraScan()) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const _VoucherScanDialog(),
    );
  }
  return _scanFromImage();
}

Future<String?> _scanFromImage() async {
  final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true, lockParentWindow: !kIsWeb);
  if (picked == null || picked.files.isEmpty) return null;
  final bytes = picked.files.first.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  final raw = voucherQrTextFromImage(bytes);
  if (raw == null) return null;
  return voucherCodeFromScan(raw);
}

/// Reads a QR image (png/jpg) and returns the payload text.
String? voucherQrTextFromImage(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) return null;
  if (image.width > 900) {
    image = img.copyResize(image, width: 900);
  }
  final pixels = Int32List(image.width * image.height);
  var i = 0;
  for (final p in image) {
    pixels[i++] = (p.a.toInt() << 24) | (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();
  }
  final source = RGBLuminanceSource(image.width, image.height, pixels);
  try {
    return QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source))).text;
  } catch (_) {
    return null;
  }
}

class _VoucherScanDialog extends StatefulWidget {
  const _VoucherScanDialog();

  @override
  State<_VoucherScanDialog> createState() => _VoucherScanDialogState();
}

class _VoucherScanDialogState extends State<_VoucherScanDialog> {
  var _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done || !mounted) return;
    for (final bar in capture.barcodes) {
      final raw = bar.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final code = voucherCodeFromScan(raw);
      if (code == null) continue;
      _done = true;
      Navigator.pop(context, code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3F3F46))),
      child: SizedBox(
        width: 320,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Scan voucher', style: TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFFA1A1AA)),
                ),
              ],
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Camera unavailable. Allow camera access and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFA1A1AA), height: 1.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
