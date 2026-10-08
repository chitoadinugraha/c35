import 'dart:ffi' hide Size;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

import 'remote_trackpad_cursor_clip.dart';

class RemoteTrackpadCursorClipWin implements RemoteTrackpadCursorClip {
  bool _confined = false;

  @override
  bool get isConfined => _confined;

  @override
  void confine({
    required Offset localPointerPos,
    required Size surfaceSize,
    required double devicePixelRatio,
  }) {
    if (!Platform.isWindows) return;
    if (surfaceSize.width <= 0 || surfaceSize.height <= 0) return;

    final pt = calloc<POINT>();
    final rect = calloc<RECT>();
    try {
      if (GetCursorPos(pt) == 0) return;

      final dpr = devicePixelRatio > 0 ? devicePixelRatio : 1.0;
      final int screenLeft = (pt.ref.x - localPointerPos.dx * dpr).round();
      final int screenTop = (pt.ref.y - localPointerPos.dy * dpr).round();
      final int screenWidth = (surfaceSize.width * dpr).round();
      final int screenHeight = (surfaceSize.height * dpr).round();

      rect.ref.left = screenLeft;
      rect.ref.top = screenTop;
      rect.ref.right = screenLeft + screenWidth;
      rect.ref.bottom = screenTop + screenHeight;

      if (ClipCursor(rect) != 0) {
        _confined = true;
      }
    } finally {
      calloc.free(pt);
      calloc.free(rect);
    }
  }

  @override
  void release() {
    if (!Platform.isWindows) return;
    if (_confined) {
      ClipCursor(nullptr);
      _confined = false;
    }
  }
}

RemoteTrackpadCursorClip createRemoteTrackpadCursorClip() =>
    Platform.isWindows ? RemoteTrackpadCursorClipWin() : RemoteTrackpadCursorClipStub();

class RemoteTrackpadCursorClipStub implements RemoteTrackpadCursorClip {
  @override
  bool get isConfined => false;

  @override
  void confine({
    required Offset localPointerPos,
    required Size surfaceSize,
    required double devicePixelRatio,
  }) {}

  @override
  void release() {}
}
