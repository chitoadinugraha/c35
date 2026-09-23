import 'package:flutter_test/flutter_test.dart';
import 'package:alienai_c35/core/format/fraction.dart';

void main() {
  group('fraction utils', () {
    test('fractionFromQty handles whole numbers and common culinary fractions', () {
      expect(fractionFromQty(1.0), (num: 1, den: 1));
      expect(fractionFromQty(2.0), (num: 2, den: 1));
      expect(fractionFromQty(0.5), (num: 1, den: 2));
      expect(fractionFromQty(0.25), (num: 1, den: 4));
      expect(fractionFromQty(0.75), (num: 3, den: 4));
    });

    test('fractionPartsFromQty separates whole and fraction', () {
      final p1 = fractionPartsFromQty(1.0);
      expect(p1.whole, 1);
      expect(p1.fracNum, 0);

      final pHalf = fractionPartsFromQty(0.5);
      expect(pHalf.whole, 0);
      expect(pHalf.fracNum, 1);
      expect(pHalf.fracDen, 2);

      final pOneAndQuarter = fractionPartsFromQty(1.25);
      expect(pOneAndQuarter.whole, 1);
      expect(pOneAndQuarter.fracNum, 1);
      expect(pOneAndQuarter.fracDen, 4);
    });

    test('fractionLabel formats unicode fractions', () {
      expect(fractionLabel(1.0), '1');
      expect(fractionLabel(0.5), '½');
      expect(fractionLabel(1.5), '1 ½');
      expect(fractionLabel(0.25), '¼');
      expect(fractionLabel(0.75), '¾');
      expect(fractionLabel(2.0), '2');
    });

    test('fractionPartsToQty reconstructs accurate double', () {
      expect(fractionPartsToQty(1, 0, 1), 1.0);
      expect(fractionPartsToQty(0, 1, 2), 0.5);
      expect(fractionPartsToQty(1, 1, 4), 1.25);
    });
  });
}
