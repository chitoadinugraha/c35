import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:win32/win32.dart';

import 'remote_trackpad_cursor_lock_stub.dart';

class RemoteTrackpadCursorLockWin extends RemoteTrackpadCursorLock {
  var _active = false;
  var _lockX = 0;
  var _lockY = 0;
  var _hideOps = 0;

  @override
  void engage(Offset screenPosition) {
    if (!Platform.isWindows) return;
    if (!_active) {
      _lockX = screenPosition.dx.round();
      _lockY = screenPosition.dy.round();
      SetCursorPos(_lockX, _lockY);
      var ops = 0;
      while (ShowCursor(FALSE) >= 0) {
        ops++;
      }
      _hideOps = ops;
      _active = true;
    }
    SetCursorPos(_lockX, _lockY);
  }

  @override
  void sustain() {
    if (!_active || !Platform.isWindows) return;
    SetCursorPos(_lockX, _lockY);
  }

  @override
  void release() {
    if (!_active || !Platform.isWindows) return;
    for (var i = 0; i < _hideOps; i++) {
      ShowCursor(TRUE);
    }
    _hideOps = 0;
    _active = false;
  }
}

RemoteTrackpadCursorLock createRemoteTrackpadCursorLock() =>
    Platform.isWindows ? RemoteTrackpadCursorLockWin() : RemoteTrackpadCursorLock();