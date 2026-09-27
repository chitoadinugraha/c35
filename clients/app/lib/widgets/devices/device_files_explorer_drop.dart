import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

/// Desktop-only drag-drop wrapper; pass [enabled] false on mobile (no DropTarget).
Widget deviceFilesExplorerDrop({
  required bool enabled,
  required bool isDragging,
  required Widget child,
  required VoidCallback onDragEntered,
  required VoidCallback onDragExited,
  required Future<void> Function(List<String> localPaths) onDragDone,
}) {
  if (!enabled) return child;
  return DropTarget(
    onDragEntered: (_) => onDragEntered(),
    onDragExited: (_) => onDragExited(),
    onDragDone: (detail) => onDragDone(
      detail.files.map((f) => f.path).where((p) => p.isNotEmpty).toList(),
    ),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        border: Border.all(color: isDragging ? const Color(0xFF34D399) : Colors.transparent, width: 1.5),
      ),
      child: child,
    ),
  );
}
