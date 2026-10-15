import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiFmtDurationMs sub-minute', () {
    expect(uiFmtDurationMs(450), '450ms');
    expect(uiFmtDurationMs(1500), '1.5s');
    expect(uiFmtDurationMs(59000), '59s');
  });

  test('uiFmtDurationMs minute:second', () {
    expect(uiFmtDurationMs(60000), '1:00');
    expect(uiFmtDurationMs(63000), '1:03');
    expect(uiFmtDurationMs(90000), '1:30');
    expect(uiFmtDurationMs(3599000), '59:59');
  });

  test('uiFmtDurationMs hour:minute:second', () {
    expect(uiFmtDurationMs(3600000), '1:00:00');
    expect(uiFmtDurationMs(5404000), '1:30:04');
  });

  test('uiFmtDurationMs days', () {
    expect(uiFmtDurationMs(102625000), '1d 4:30:25');
  });
}
