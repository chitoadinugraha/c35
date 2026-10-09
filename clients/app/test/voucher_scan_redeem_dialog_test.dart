import 'dart:io';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/api/wire.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/widgets/referral/ui_billing_package_redeem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Live prepaid credit voucher issued for this check. Face value Rp 100,000.
const _code = 'V100K202610090507';

void main() {
  testWidgets('scan opens the redeem dialog and waits for Redeem', (tester) async {
    final payload = voucherPublicUrl(_code);
    final scanned = voucherCodeFromScan(payload);
    expect(scanned, _code, reason: 'QR payload should yield the voucher code');

    final qrPath = 'build/voucher_100k_qr.png';
    Directory('build').createSync(recursive: true);
    File(qrPath).writeAsBytesSync(_qrPng(payload));
    expect(File(qrPath).lengthSync(), greaterThan(100));

    var previewCount = 0;
    var redeemCount = 0;
    final conn = ReferralConn(
      uid: 99000,
      invoke: ({List<int> body = const [], String path = '', String method = ''}) async {
        final req = InvokeReq.fromBuffer(body);
        if (req.hasBillingPackagePreview()) {
          previewCount++;
          expect(req.billingPackagePreview.code, _code);
          return AuthInvokeRes(
            statusCode: 200,
            body: InvokeRes(
              billingPackagePreview: ResBillingPackagePreview(
                packageName: 'Test 100k',
                amountIdr: 100000,
                planTier: 'credit',
                commission: ResReferralCommissionSimulate(),
              ),
            ).writeToBuffer(),
          );
        }
        if (req.hasBillingPackageRedeem()) {
          redeemCount++;
          expect(req.billingPackageRedeem.code, _code);
          return AuthInvokeRes(
            statusCode: 200,
            body: InvokeRes(
              billingPackageRedeem: ResBillingPackageRedeem(packageName: 'Test 100k', amountIdr: 0),
            ).writeToBuffer(),
          );
        }
        return const AuthInvokeRes(statusCode: 500, error: 'unexpected invoke');
      },
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => billingPackageRedeemDialog(context, conn: conn, initialCode: scanned!),
            child: const Text('after scan'),
          ),
        ),
      ),
    ));

    expect(redeemCount, 0);
    await tester.tap(find.text('after scan'));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    expect(find.text('Redeem package'), findsOneWidget);
    expect(find.text('Test 100k'), findsOneWidget);
    expect(find.textContaining('100,000'), findsWidgets);
    expect(previewCount, 1);
    expect(redeemCount, 0, reason: 'scan must not claim until Redeem is pressed');

    final redeem = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Redeem'));
    expect(redeem.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
    await tester.pump();
    await tester.pump();

    expect(redeemCount, 1);
    expect(find.text('Redeemed Test 100k'), findsOneWidget);
  });
}

List<int> _qrPng(String data) {
  final qrCode = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L);
  final qrImage = QrImage(qrCode);
  const scale = 8;
  const border = 4;
  final count = qrImage.moduleCount;
  final size = (count + border * 2) * scale;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < count; y++) {
    for (var x = 0; x < count; x++) {
      if (!qrImage.isDark(y, x)) continue;
      img.fillRect(
        image,
        x1: (x + border) * scale,
        y1: (y + border) * scale,
        x2: (x + border + 1) * scale,
        y2: (y + border + 1) * scale,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
  return img.encodePng(image);
}
