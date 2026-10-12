import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiFriendlyError maps rpc timeout to friendly message', () {
    expect(
      uiFriendlyError('TimeoutException: rpc timeout: b637ceb0-78a5-4ee3-9b50-806df901ab21'),
      'Request timed out. Check your internet and try again.',
    );
  });
}
