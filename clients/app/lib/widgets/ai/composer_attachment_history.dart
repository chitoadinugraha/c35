import 'dart:typed_data';

import 'package:alienai_c35/c/media/media_types.dart';

class ComposerAttachmentHistory {
  final _undo = <List<StagedMedia>>[];
  final _redo = <List<StagedMedia>>[];
  final List<StagedMedia> current = [];

  static const maxDepth = 48;

  static List<StagedMedia> snapshot(Iterable<StagedMedia> items) => [
        for (final m in items) m.copyWith(bytes: Uint8List.fromList(m.bytes)),
      ];

  void record() {
    _undo.add(snapshot(current));
    if (_undo.length > maxDepth) _undo.removeAt(0);
    _redo.clear();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    current.clear();
  }

  void apply(List<StagedMedia> next) {
    current
      ..clear()
      ..addAll(next);
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(snapshot(current));
    apply(_undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(snapshot(current));
    apply(_redo.removeLast());
    return true;
  }
}