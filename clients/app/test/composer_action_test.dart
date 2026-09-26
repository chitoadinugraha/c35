import 'package:alienai_c35/widgets/ai/composer_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('busy without text shows abort', () {
    expect(composerActionKind(streaming: true, recording: false, hasText: false), ComposerActionKind.abort);
  });

  test('busy with text shows send (queue)', () {
    expect(composerActionKind(streaming: true, recording: false, hasText: true), ComposerActionKind.send);
  });
}
