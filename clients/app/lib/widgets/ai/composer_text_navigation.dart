import 'package:flutter/services.dart';

/// Start offset of the line containing [offset] in [text] (`\n`-delimited).
int composerTextLineStart(String text, int offset) {
  final clamped = offset.clamp(0, text.length);
  if (clamped == 0) return 0;
  final lastNewline = text.lastIndexOf('\n', clamped - 1);
  return lastNewline < 0 ? 0 : lastNewline + 1;
}

/// End offset of the line containing [offset] (index before `\n`, or [text.length]).
int composerTextLineEnd(String text, int offset) {
  final clamped = offset.clamp(0, text.length);
  final nextNewline = text.indexOf('\n', clamped);
  return nextNewline < 0 ? text.length : nextNewline;
}

/// IDE-style Home / End on a single logical line within a multiline field.
TextSelection composerTextSelectionAfterHorizontalLineMove({
  required TextSelection selection,
  required String text,
  required bool toLineStart,
  required bool extend,
}) {
  if (!selection.isValid) {
    final at = toLineStart ? composerTextLineStart(text, 0) : composerTextLineEnd(text, 0);
    return TextSelection.collapsed(offset: at);
  }
  final anchor = selection.extentOffset;
  final target = toLineStart ? composerTextLineStart(text, anchor) : composerTextLineEnd(text, anchor);
  if (!extend) return TextSelection.collapsed(offset: target);
  return TextSelection(baseOffset: selection.baseOffset, extentOffset: target);
}

/// Returns true when [event] is plain or Shift+Home/End (not Ctrl/Meta/Alt).
bool composerTextLineNavigationKey(KeyDownEvent event) {
  final key = event.logicalKey;
  if (key != LogicalKeyboardKey.home && key != LogicalKeyboardKey.end) return false;
  final kb = HardwareKeyboard.instance;
  return !kb.isControlPressed && !kb.isMetaPressed && !kb.isAltPressed;
}