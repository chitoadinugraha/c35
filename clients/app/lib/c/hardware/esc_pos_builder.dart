import 'dart:convert';
import 'dart:typed_data';

import 'package:alienai_c35/c/hardware/esc_pos_raster.dart';

/// Text alignment modes for ESC/POS printers.
enum EscPosAlign {
  left,
  center,
  right,
}

/// A lightweight, robust builder for generating standard raw ESC/POS byte sequences.
///
/// Supports 58mm (standard 32 characters) and 80mm (standard 48 characters) thermal receipt printers,
/// including alignment, font sizing, bold formatting, paper feeding, cash drawer kicking,
/// and paper cutting commands.
class EscPosBuilder {
  final BytesBuilder _buffer = BytesBuilder();

  int _currentWidth = 1;
  int _currentHeight = 1;

  /// Clears all buffered bytes and resets sizing state.
  void clear() {
    _buffer.clear();
    _currentWidth = 1;
    _currentHeight = 1;
  }

  /// Appends raw byte list directly to buffer.
  EscPosBuilder raw(List<int> bytes) {
    _buffer.add(bytes);
    return this;
  }

  /// ESC @: Hardware reset / initialize printer.
  EscPosBuilder reset() {
    _buffer.add(const [0x1B, 0x40]);
    _currentWidth = 1;
    _currentHeight = 1;
    return this;
  }

  /// ESC a 0: Align text to left margin.
  EscPosBuilder alignLeft() => setAlign(EscPosAlign.left);

  /// ESC a 1: Align text to center.
  EscPosBuilder alignCenter() => setAlign(EscPosAlign.center);

  /// ESC a 2: Align text to right margin.
  EscPosBuilder alignRight() => setAlign(EscPosAlign.right);

  /// ESC a n: Set text alignment.
  EscPosBuilder setAlign(EscPosAlign align) {
    final n = switch (align) {
      EscPosAlign.left => 0x00,
      EscPosAlign.center => 0x01,
      EscPosAlign.right => 0x02,
    };
    _buffer.add([0x1B, 0x61, n]);
    return this;
  }

  /// ESC E n: Turn emphasized (bold) mode on or off.
  EscPosBuilder bold(bool enabled) {
    _buffer.add([0x1B, 0x45, enabled ? 0x01 : 0x00]);
    return this;
  }

  /// GS ! n: Select character size (magnification from 1x to 8x).
  EscPosBuilder size({int width = 1, int height = 1}) {
    _currentWidth = width.clamp(1, 8);
    _currentHeight = height.clamp(1, 8);
    final n = ((_currentWidth - 1) << 4) | (_currentHeight - 1);
    _buffer.add([0x1D, 0x21, n]);
    return this;
  }

  /// Double height shortcut.
  EscPosBuilder doubleHeight(bool enabled) =>
      size(width: _currentWidth, height: enabled ? 2 : 1);

  /// Double width shortcut.
  EscPosBuilder doubleWidth(bool enabled) =>
      size(width: enabled ? 2 : 1, height: _currentHeight);

  /// ESC d n: Print and feed paper by [lines] line feeds.
  EscPosBuilder feed([int lines = 1]) {
    if (lines <= 0) return this;
    _buffer.add([0x1B, 0x64, lines.clamp(1, 255)]);
    return this;
  }

  /// GS V n: Cut paper.
  ///
  /// Uses Function A standard [0x1D, 0x56, n] where 0 is full cut, 1 is partial cut.
  /// When [functionB] is true, uses Function B [0x1D, 0x56, 0x41/0x42, 0x00].
  EscPosBuilder cutPaper({bool partial = false, bool functionB = false}) {
    if (functionB) {
      _buffer.add([0x1D, 0x56, partial ? 0x42 : 0x41, 0x00]);
    } else {
      _buffer.add([0x1D, 0x56, partial ? 0x01 : 0x00]);
    }
    return this;
  }

  /// ESC p m t1 t2: Generate pulse to open cash drawer.
  ///
  /// Standard pulse timing: t1 = 25 (50ms on), t2 = 250 (500ms off).
  /// [pin] 0 selects drawer kick-out pin 2 (0x00), pin 1 selects pin 5 (0x01).
  EscPosBuilder kickCashDrawer({int pin = 0}) {
    _buffer.add([0x1B, 0x70, pin == 0 ? 0x00 : 0x01, 0x19, 0xFA]);
    return this;
  }

  /// Appends text with optional inline styling.
  /// Styling applied here is automatically restored to default after the text.
  EscPosBuilder text(
    String text, {
    bool bold = false,
    EscPosAlign align = EscPosAlign.left,
    int size = 1,
  }) {
    if (align != EscPosAlign.left) setAlign(align);
    if (bold) this.bold(true);
    if (size > 1) this.size(width: size, height: size);

    _buffer.add(utf8.encode(text));

    if (size > 1) this.size(width: 1, height: 1);
    if (bold) this.bold(false);
    if (align != EscPosAlign.left) alignLeft();
    return this;
  }

  /// Appends text followed by newline (`0x0A`).
  EscPosBuilder textLine(
    String text, {
    bool bold = false,
    EscPosAlign align = EscPosAlign.left,
    int size = 1,
  }) {
    if (text.isNotEmpty || bold || align != EscPosAlign.left || size > 1) {
      this.text(text, bold: bold, align: align, size: size);
    }
    _buffer.add(const [0x0A]);
    return this;
  }

  /// Appends an empty line (`0x0A`).
  EscPosBuilder emptyLine() {
    _buffer.add(const [0x0A]);
    return this;
  }

  /// Formats a two-column row with padding between [left] and [right].
  ///
  /// Example: 'Coffee                 Rp 25.000' (totalWidth = 32)
  EscPosBuilder row(
    String left,
    String right, {
    int totalWidth = 32,
    String fill = ' ',
  }) {
    final filler = fill.isNotEmpty ? fill[0] : ' ';
    if (left.length + right.length <= totalWidth) {
      final padCount = totalWidth - left.length - right.length;
      return textLine('$left${filler * padCount}$right');
    }

    final maxLeft = totalWidth - right.length - 1;
    if (maxLeft > 0) {
      final truncatedLeft = left.substring(0, maxLeft);
      return textLine('$truncatedLeft $right');
    }

    textLine(left);
    final padRight = totalWidth - right.length;
    if (padRight > 0) {
      return textLine('${filler * padRight}$right');
    }
    return textLine(right);
  }

  /// Formats a three-column row, e.g. for item name, quantity x price, and net total.
  ///
  /// Guaranteed to format nicely across [totalWidth] characters.
  EscPosBuilder threeCol(
    String col1,
    String col2,
    String col3, {
    int totalWidth = 32,
    int? width1,
    int? width2,
    int? width3,
  }) {
    final w3 = width3 ?? (totalWidth * 0.32).round();
    final w2 = width2 ?? (totalWidth * 0.28).round();
    final w1 = width1 ?? (totalWidth - w2 - w3);

    if (col1.length <= w1) {
      final c1 = col1.padRight(w1);
      final c2 = col2.padLeft(w2);
      final c3 = col3.padLeft(w3);
      return textLine('$c1$c2$c3');
    }

    textLine(col1);
    final c1 = ''.padRight(w1);
    final c2 = col2.padLeft(w2);
    final c3 = col3.padLeft(w3);
    return textLine('$c1$c2$c3');
  }

  /// GS v 0: print raster bit image (see [escPosRasterFromImageBytes]).
  EscPosBuilder rasterBitImage(EscPosRaster raster, {EscPosAlign align = EscPosAlign.center}) {
    if (raster.data.isEmpty || raster.height <= 0 || raster.widthBytes <= 0) return this;
    setAlign(align);
    final w = raster.widthBytes;
    final h = raster.height;
    _buffer.add([
      0x1D,
      0x76,
      0x30,
      0x00,
      w & 0xFF,
      (w >> 8) & 0xFF,
      h & 0xFF,
      (h >> 8) & 0xFF,
    ]);
    _buffer.add(raster.data);
    alignLeft();
    return this;
  }

  /// Appends a horizontal divider line of [totalWidth] characters.
  EscPosBuilder hr({String char = '-', int totalWidth = 32}) {
    final c = char.isNotEmpty ? char[0] : '-';
    return textLine(c * totalWidth);
  }

  /// Returns the complete generated raw ESC/POS byte sequence.
  Uint8List bytes() => _buffer.toBytes();
}
