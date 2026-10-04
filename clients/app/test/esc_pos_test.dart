import 'dart:convert';
import 'package:alienai_c35/c/hardware/esc_pos_builder.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/esc_pos_receipt_formatter.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EscPosBuilder Command Constants and Bytes', () {
    test('reset emits ESC @ ([0x1B, 0x40])', () {
      final builder = EscPosBuilder()..reset();
      expect(builder.bytes(), equals([0x1B, 0x40]));
    });

    test('align commands emit ESC a n', () {
      final left = EscPosBuilder()..alignLeft();
      expect(left.bytes(), equals([0x1B, 0x61, 0x00]));

      final center = EscPosBuilder()..alignCenter();
      expect(center.bytes(), equals([0x1B, 0x61, 0x01]));

      final right = EscPosBuilder()..alignRight();
      expect(right.bytes(), equals([0x1B, 0x61, 0x02]));
    });

    test('bold commands emit ESC E n', () {
      final on = EscPosBuilder()..bold(true);
      expect(on.bytes(), equals([0x1B, 0x45, 0x01]));

      final off = EscPosBuilder()..bold(false);
      expect(off.bytes(), equals([0x1B, 0x45, 0x00]));
    });

    test('size and magnification commands emit GS ! n', () {
      final normal = EscPosBuilder()..size(width: 1, height: 1);
      expect(normal.bytes(), equals([0x1D, 0x21, 0x00]));

      final doubleBoth = EscPosBuilder()..size(width: 2, height: 2);
      expect(doubleBoth.bytes(), equals([0x1D, 0x21, 0x11]));

      final doubleW = EscPosBuilder()..doubleWidth(true);
      expect(doubleW.bytes(), equals([0x1D, 0x21, 0x10]));

      final doubleH = EscPosBuilder()..doubleHeight(true);
      expect(doubleH.bytes(), equals([0x1D, 0x21, 0x01]));
    });

    test('feed paper emits ESC d n', () {
      final feed = EscPosBuilder()..feed(4);
      expect(feed.bytes(), equals([0x1B, 0x64, 0x04]));
    });

    test('cut paper emits GS V n', () {
      final fullCut = EscPosBuilder()..cutPaper(partial: false);
      expect(fullCut.bytes(), equals([0x1D, 0x56, 0x00]));

      final partialCut = EscPosBuilder()..cutPaper(partial: true);
      expect(partialCut.bytes(), equals([0x1D, 0x56, 0x01]));

      final funcBCut = EscPosBuilder()..cutPaper(partial: true, functionB: true);
      expect(funcBCut.bytes(), equals([0x1D, 0x56, 0x42, 0x00]));
    });

    test('kick cash drawer emits ESC p m t1 t2 pulse bytes', () {
      final pin0 = EscPosBuilder()..kickCashDrawer(pin: 0);
      expect(pin0.bytes(), equals([0x1B, 0x70, 0x00, 0x19, 0xFA]));

      final pin1 = EscPosBuilder()..kickCashDrawer(pin: 1);
      expect(pin1.bytes(), equals([0x1B, 0x70, 0x01, 0x19, 0xFA]));
    });
  });

  group('EscPosBuilder Layout and Padding', () {
    test('row formats two columns for 32 chars (58mm)', () {
      final builder = EscPosBuilder()..row('Coffee', 'Rp 25.000', totalWidth: 32);
      final raw = utf8.decode(builder.bytes());
      final lines = raw.split('\n');

      expect(lines.first.length, equals(32));
      expect(lines.first.startsWith('Coffee'), isTrue);
      expect(lines.first.endsWith('Rp 25.000'), isTrue);
      expect(lines.first, equals('Coffee                 Rp 25.000'));
    });

    test('row formats two columns for 48 chars (80mm)', () {
      final builder = EscPosBuilder()..row('Coffee', 'Rp 25.000', totalWidth: 48);
      final raw = utf8.decode(builder.bytes());
      final lines = raw.split('\n');

      expect(lines.first.length, equals(48));
      expect(lines.first.startsWith('Coffee'), isTrue);
      expect(lines.first.endsWith('Rp 25.000'), isTrue);
      expect(lines.first, equals('Coffee                                 Rp 25.000'));
    });

    test('threeCol formats three columns within line width', () {
      final b32 = EscPosBuilder()..threeCol('Item', 'Qty', 'Total', totalWidth: 32);
      final raw32 = utf8.decode(b32.bytes()).split('\n').first;
      expect(raw32.length, equals(32));

      final b48 = EscPosBuilder()..threeCol('Item', 'Qty', 'Total', totalWidth: 48);
      final raw48 = utf8.decode(b48.bytes()).split('\n').first;
      expect(raw48.length, equals(48));
    });

    test('hr formats divider line with exact character length', () {
      final h32 = EscPosBuilder()..hr(char: '-', totalWidth: 32);
      final line32 = utf8.decode(h32.bytes()).split('\n').first;
      expect(line32.length, equals(32));
      expect(line32, equals('-' * 32));

      final h48 = EscPosBuilder()..hr(char: '=', totalWidth: 48);
      final line48 = utf8.decode(h48.bytes()).split('\n').first;
      expect(line48.length, equals(48));
      expect(line48, equals('=' * 48));
    });
  });

  group('EscPosReceiptFormatter Thermal Receipt Generation', () {
    test('formats complete 58mm (32 chars) receipt with cash drawer kick and payments', () {
      final tx = Tx(
        txId: Int64(1001),
        cashierName: 'Budi',
        subjectName: 'Dewi',
        createdTsMs: Int64(DateTime(2026, 10, 2, 14, 30).millisecondsSinceEpoch),
        items: [
          TxItem(
            productId: Int64(10),
            price: Int64(25000),
            qty: 2,
            totalNet: Int64(50000),
          ),
          TxItem(
            productId: Int64(20),
            price: Int64(15000),
            qty: 1,
            totalNet: Int64(15000),
            note: 'Less ice',
          ),
        ],
        discounts: [
          TxDiscount(amount: Int64(5000), note: 'Promo Opening'),
        ],
        taxes: [
          TxTax(amount: Int64(6000), taxType: 'PB1 10%'),
        ],
        total: Int64(66000),
        payments: [
          TxPayment(
            method: TxPaymentMethod.TX_PAYMENT_METHOD_CASH,
            amount: Int64(66000),
            paymentJson: jsonEncode({'tendered': 100000, 'change': 34000}),
          ),
        ],
      );

      const config = ReceiptConfig(
        projectName: 'Alien Coffee & Roastery',
        projectAddress: 'Jl. Merdeka No. 45',
        projectContact: '0812-3456-7890',
        receiptHeader: 'Selamat Datang!',
        receiptFooter: 'Terima Kasih atas Kunjungan Anda',
      );

      final productNames = {
        '10': 'Latte Special',
        '20': 'Ice Americano',
      };

      final bytes = EscPosReceiptFormatter.formatReceipt(
        tx,
        config: config,
        productNames: productNames,
        paperWidth: 32,
        kickDrawer: true,
      );

      expect(bytes, isNotEmpty);

      // Verify reset command ESC @
      expect(bytes[0], equals(0x1B));
      expect(bytes[1], equals(0x40));

      // Verify cash drawer kick pulse command ESC p 0 25 250
      expect(bytes.sublist(2, 7), equals([0x1B, 0x70, 0x00, 0x19, 0xFA]));

      // Verify cut command at the end
      expect(bytes.sublist(bytes.length - 3), equals([0x1D, 0x56, 0x00]));

      // Decode bytes ignoring non-printable ESC commands to verify text contents
      final receiptText = String.fromCharCodes(bytes.where((b) => b >= 32 || b == 10));

      expect(receiptText.contains('Alien Coffee & Roastery'), isTrue);
      expect(receiptText.contains('Jl. Merdeka No. 45'), isTrue);
      expect(receiptText.contains('0812-3456-7890'), isTrue);
      expect(receiptText.contains('No. Nota'), isTrue);
      expect(receiptText.contains('#1001'), isTrue);
      expect(receiptText.contains('Kasir'), isTrue);
      expect(receiptText.contains('Budi'), isTrue);
      expect(receiptText.contains('Pelanggan'), isTrue);
      expect(receiptText.contains('Dewi'), isTrue);
      expect(receiptText.contains('Latte Special'), isTrue);
      expect(receiptText.contains('Ice Americano'), isTrue);
      expect(receiptText.contains('Less ice'), isTrue);
      expect(receiptText.contains('Subtotal'), isTrue);
      expect(receiptText.contains('Promo Opening'), isTrue);
      expect(receiptText.contains('PB1 10%'), isTrue);
      expect(receiptText.contains('Total'), isTrue);
      expect(receiptText.contains('Bayar (Cash)'), isTrue);
      expect(receiptText.contains('Kembalian'), isTrue);
      expect(receiptText.contains('34.000'), isTrue);
      expect(receiptText.contains('Terima Kasih atas Kunjungan Anda'), isTrue);
    });

    test('formats 80mm (48 chars) receipt without drawer kick', () {
      final tx = Tx(
        txId: Int64(2002),
        items: [
          TxItem(productId: Int64(1), price: Int64(10000), qty: 1, totalNet: Int64(10000)),
        ],
        total: Int64(10000),
        payments: [
          TxPayment(
            method: TxPaymentMethod.TX_PAYMENT_METHOD_QRIS,
            amount: Int64(10000),
          ),
        ],
      );

      final bytes = EscPosReceiptFormatter.formatReceipt(
        tx,
        paperWidth: 48,
        kickDrawer: false,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 2), equals([0x1B, 0x40]));
      // Cash drawer kick command (ESC p = [0x1B, 0x70]) should NOT follow reset
      expect(bytes.sublist(2, 4), isNot(equals([0x1B, 0x70])));

      final receiptText = String.fromCharCodes(bytes.where((b) => b >= 32 || b == 10));
      expect(receiptText.contains('#2002'), isTrue);
      expect(receiptText.contains('Bayar (QRIS)'), isTrue);
      expect(receiptText.contains('Total'), isTrue);
    });
  });
}
