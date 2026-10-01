import 'package:flutter/services.dart';

MouseCursor remoteCursorFromShape(String shape) => switch (shape) {
      'text' => SystemMouseCursors.text,
      'click' => SystemMouseCursors.click,
      'wait' => SystemMouseCursors.wait,
      'progress' => SystemMouseCursors.progress,
      'help' => SystemMouseCursors.help,
      'forbidden' => SystemMouseCursors.forbidden,
      'move' => SystemMouseCursors.move,
      'precise' => SystemMouseCursors.precise,
      'resize_ns' => SystemMouseCursors.resizeUpDown,
      'resize_ew' => SystemMouseCursors.resizeLeftRight,
      'resize_nwse' => SystemMouseCursors.resizeUpLeftDownRight,
      'resize_nesw' => SystemMouseCursors.resizeUpRightDownLeft,
      _ => SystemMouseCursors.basic,
    };
