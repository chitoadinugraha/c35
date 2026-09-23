import 'package:alienai_c35/c/canvas/canvas_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCanvasDiff', () {
    test('identical text returns all unchanged lines', () {
      const text = 'line 1\nline 2\nline 3';
      final diff = computeCanvasDiff(text, text);
      expect(diff, hasLength(3));
      expect(diff.every((l) => l.type == CanvasDiffType.unchanged), isTrue);
      expect(diff.hasDifferences, isFalse);
      expect(diff.addedCount, 0);
      expect(diff.removedCount, 0);
      expect(diff[0].oldLine, 1);
      expect(diff[0].newLine, 1);
    });

    test('additions only', () {
      const oldText = 'line 1\nline 3';
      const newText = 'line 1\nline 2\nline 3';
      final diff = computeCanvasDiff(oldText, newText);
      expect(diff, hasLength(3));
      expect(diff[0].type, CanvasDiffType.unchanged);
      expect(diff[1].type, CanvasDiffType.added);
      expect(diff[1].text, 'line 2');
      expect(diff[1].oldLine, isNull);
      expect(diff[1].newLine, 2);
      expect(diff[2].type, CanvasDiffType.unchanged);
      expect(diff.addedCount, 1);
      expect(diff.removedCount, 0);
      expect(diff.hasDifferences, isTrue);
    });

    test('deletions only', () {
      const oldText = 'alpha\nbeta\ngamma';
      const newText = 'alpha\ngamma';
      final diff = computeCanvasDiff(oldText, newText);
      expect(diff, hasLength(3));
      expect(diff[0].text, 'alpha');
      expect(diff[0].type, CanvasDiffType.unchanged);
      expect(diff[1].text, 'beta');
      expect(diff[1].type, CanvasDiffType.removed);
      expect(diff[1].oldLine, 2);
      expect(diff[1].newLine, isNull);
      expect(diff[2].text, 'gamma');
      expect(diff[2].type, CanvasDiffType.unchanged);
      expect(diff.addedCount, 0);
      expect(diff.removedCount, 1);
    });

    test('empty old text means all added', () {
      const newText = 'hello\nworld';
      final diff = computeCanvasDiff('', newText);
      expect(diff, hasLength(2));
      expect(diff.every((l) => l.type == CanvasDiffType.added), isTrue);
      expect(diff.addedCount, 2);
      expect(diff.removedCount, 0);
    });

    test('empty new text means all removed', () {
      const oldText = 'hello\nworld';
      final diff = computeCanvasDiff(oldText, '');
      expect(diff, hasLength(2));
      expect(diff.every((l) => l.type == CanvasDiffType.removed), isTrue);
      expect(diff.addedCount, 0);
      expect(diff.removedCount, 2);
    });

    test('both empty returns empty diff', () {
      final diff = computeCanvasDiff('', '');
      expect(diff, isEmpty);
      expect(diff.hasDifferences, isFalse);
    });
  });
}
