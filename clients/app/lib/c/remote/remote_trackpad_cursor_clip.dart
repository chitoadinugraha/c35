import 'package:flutter/material.dart';

import 'remote_trackpad_cursor_clip_stub.dart'
    if (dart.library.io) 'remote_trackpad_cursor_clip_io.dart';

abstract class RemoteTrackpadCursorClip {
  factory RemoteTrackpadCursorClip() => createRemoteTrackpadCursorClip();

  /// Confines the OS cursor to the screen bounds of the given surface rectangle.
  void confine({
    required Offset localPointerPos,
    required Size surfaceSize,
    required double devicePixelRatio,
  });

  /// Releases cursor confinement, restoring normal OS cursor behavior.
  void release();

  /// Whether the cursor is currently confined.
  bool get isConfined;
}
