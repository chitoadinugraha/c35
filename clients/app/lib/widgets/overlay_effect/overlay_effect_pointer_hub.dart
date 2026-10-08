import 'package:flutter/material.dart';

import 'overlay_effect_pointer_frame.dart';

/// Active touch points forwarded to overlay effect sims (below UI chrome).
class OverlayEffectPointerHub extends ChangeNotifier {
  final _pointers = <int, Offset>{};
  final _prev = <int, Offset>{};
  final _downs = <Offset>[];
  final _ups = <Offset>[];

  Map<int, Offset> get pointers => Map.unmodifiable(_pointers);

  List<Offset> get downs => List.unmodifiable(_downs);

  List<Offset> get ups => List.unmodifiable(_ups);

  /// Snapshot active pointers + edge events, then clear downs/ups for the next frame.
  OverlayEffectPointerFrame snapshotAndClear() {
    final frame = OverlayEffectPointerFrame(
      pointers: Map<int, Offset>.from(_pointers),
      downs: List<Offset>.from(_downs),
      ups: List<Offset>.from(_ups),
    );
    frameEventsConsume();
    return frame;
  }

  Offset pointerDelta(int id) {
    final cur = _pointers[id];
    final prev = _prev[id];
    if (cur == null || prev == null) return Offset.zero;
    return cur - prev;
  }

  void pointerDown(PointerDownEvent event) {
    final pos = event.localPosition;
    _pointers[event.pointer] = pos;
    _prev[event.pointer] = pos;
    _downs.add(pos);
    notifyListeners();
  }

  void pointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _prev[event.pointer] = _pointers[event.pointer]!;
    _pointers[event.pointer] = event.localPosition;
    notifyListeners();
  }

  void pointerUp(PointerUpEvent event) {
    final pos = _pointers[event.pointer];
    if (_pointers.remove(event.pointer) != null) {
      _prev.remove(event.pointer);
      if (pos != null) _ups.add(pos);
      notifyListeners();
    }
  }

  void pointerCancel(PointerCancelEvent event) {
    final pos = _pointers[event.pointer];
    if (_pointers.remove(event.pointer) != null) {
      _prev.remove(event.pointer);
      if (pos != null) _ups.add(pos);
      notifyListeners();
    }
  }

  void frameEventsConsume() {
    _downs.clear();
    _ups.clear();
  }
}
