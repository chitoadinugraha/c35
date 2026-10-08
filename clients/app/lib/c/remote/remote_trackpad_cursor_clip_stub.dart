import 'package:flutter/material.dart';

import 'remote_trackpad_cursor_clip.dart';

RemoteTrackpadCursorClip createRemoteTrackpadCursorClip() =>
    RemoteTrackpadCursorClipStub();

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
