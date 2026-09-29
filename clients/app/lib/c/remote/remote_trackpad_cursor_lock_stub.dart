import 'package:flutter/material.dart';

class RemoteTrackpadCursorLock {
  void engage(Offset screenPosition) {}
  void sustain() {}
  void release() {}
}

RemoteTrackpadCursorLock createRemoteTrackpadCursorLock() =>
    RemoteTrackpadCursorLock();