import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moneyFmtIdrDetail shows decimals for small usage amounts', () {
    expect(moneyFmtIdrDetail(0.49), 'IDR 0.490');
    expect(moneyFmtIdrDetail(0.0049), 'IDR 0.0049');
    expect(moneyFmtIdrDetail(12.5), 'IDR 12.50');
    expect(moneyFmtIdrDetail(50000), 'IDR 50.000');
  });

  test('moneyCostLabel keeps sub-IDR costs visible', () {
    expect(moneyCostLabel(0.00000003), 'IDR 0.0005');
  });
}
