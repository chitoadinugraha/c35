import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiDurationTwoMajorParts uses days and hours above 24h', () {
    const d = Duration(hours: 1226, minutes: 14);
    final p = uiDurationTwoMajorParts(d);
    expect(p.firstUnit, UiDurationUnit.day);
    expect(p.first, 51);
    expect(p.secondUnit, UiDurationUnit.hour);
    expect(p.second, 2);
  });

  test('uiDurationTwoMajorParts uses hours and minutes under 24h', () {
    const d = Duration(hours: 4, minutes: 5);
    final p = uiDurationTwoMajorParts(d);
    expect(p.first, 4);
    expect(p.firstUnit, UiDurationUnit.hour);
    expect(p.second, 5);
    expect(p.secondUnit, UiDurationUnit.minute);
  });

  test('uiDurationTwoMajorParts uses months and days for long spans', () {
    const d = Duration(days: 95);
    final p = uiDurationTwoMajorParts(d);
    expect(p.firstUnit, UiDurationUnit.month);
    expect(p.first, 3);
    expect(p.secondUnit, UiDurationUnit.day);
    expect(p.second, 5);
  });
}
