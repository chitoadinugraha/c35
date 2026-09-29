import 'dart:typed_data';

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/widgets/ai/composer_attachment_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StagedMedia img() => StagedMedia(
        id: 'a',
        name: 'x.png',
        bytes: Uint8List.fromList([1, 2, 3]),
        mime: 'image/png',
        type: MediaType.image,
        size: 3,
      );

  test('undo after stage removes attachment; redo restores', () {
    final h = ComposerAttachmentHistory();
    expect(h.current, isEmpty);
    h.record();
    h.apply([img()]);
    expect(h.current, hasLength(1));
    expect(h.undo(), isTrue);
    expect(h.current, isEmpty);
    expect(h.redo(), isTrue);
    expect(h.current, hasLength(1));
  });
}