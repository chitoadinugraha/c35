import 'dart:async';

import 'package:alienai_c35/c/site/site_editor_flush_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debounce coalesces to one run with latest callback', () async {
    final coord = SiteEditorFlushCoordinator();
    var runs = 0;
    var last = 0;

    coord.schedule('k', const Duration(milliseconds: 40), () async {
      runs++;
      last = 2;
    });
    coord.schedule('k', const Duration(milliseconds: 40), () async {
      runs++;
      last = 3;
    });

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(runs, 1);
    expect(last, 3);
  });

  test('serializes overlapping runs for the same key', () async {
    final coord = SiteEditorFlushCoordinator();
    final gate = Completer<void>();
    var concurrent = 0;
    var maxConcurrent = 0;

    coord.schedule('k', Duration.zero, () async {
      concurrent++;
      maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
      await gate.future;
      concurrent--;
    });
    coord.schedule('k', Duration.zero, () async {
      concurrent++;
      maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
      concurrent--;
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(maxConcurrent, 1);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(maxConcurrent, 1);
  });
}
