import 'dart:ui';

import 'package:alienai_c35/widgets/ai/ui_staged_shot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShotHistory erase removes stroke and undo restores', () {
    final h = ShotHistory();
    h.begin(const Offset(10, 10));
    h.append(const Offset(20, 20));
    h.begin(const Offset(50, 50));
    h.append(const Offset(60, 60));
    expect(h.strokes.length, 2);

    final erased = h.eraseAt(const Offset(15, 15), const Size(200, 200));
    expect(erased, isTrue);
    expect(h.strokes.length, 1);

    h.undo();
    expect(h.strokes.length, 2);

    h.redo();
    expect(h.strokes.length, 1);
  });
}
