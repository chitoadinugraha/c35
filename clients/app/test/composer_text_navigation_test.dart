import 'package:alienai_c35/widgets/ai/composer_text_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line start and end offsets', () {
    const text = 'alpha\nbeta\ngamma';
    expect(composerTextLineStart(text, 0), 0);
    expect(composerTextLineEnd(text, 0), 5);
    expect(composerTextLineStart(text, 6), 6);
    expect(composerTextLineEnd(text, 6), 10);
    expect(composerTextLineStart(text, 12), 11);
    expect(composerTextLineEnd(text, 12), text.length);
  });

  test('shift+home extends to line start only', () {
    const text = 'line one\nline two';
    final sel = composerTextSelectionAfterHorizontalLineMove(
      selection: const TextSelection.collapsed(offset: 14),
      text: text,
      toLineStart: true,
      extend: true,
    );
    expect(sel.baseOffset, 14);
    expect(sel.extentOffset, 9);
  });

  test('home without shift collapses to line start', () {
    const text = 'line one\nline two';
    final sel = composerTextSelectionAfterHorizontalLineMove(
      selection: const TextSelection.collapsed(offset: 14),
      text: text,
      toLineStart: true,
      extend: false,
    );
    expect(sel.isCollapsed, isTrue);
    expect(sel.extentOffset, 9);
  });

  test('shift+end extends to line end only', () {
    const text = 'line one\nline two';
    final sel = composerTextSelectionAfterHorizontalLineMove(
      selection: const TextSelection.collapsed(offset: 9),
      text: text,
      toLineStart: false,
      extend: true,
    );
    expect(sel.baseOffset, 9);
    expect(sel.extentOffset, 17);
  });
}