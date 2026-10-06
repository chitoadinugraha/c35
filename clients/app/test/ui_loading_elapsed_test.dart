import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiLoadingElapsedLabel compact shows centiseconds after 1s', () {
    expect(uiLoadingElapsedLabel(500, compact: true), '500ms');
    expect(uiLoadingElapsedLabel(1500, compact: true), '1.50s');
    expect(uiLoadingElapsedLabel(5234, compact: false), '5.234s');
  });
}
