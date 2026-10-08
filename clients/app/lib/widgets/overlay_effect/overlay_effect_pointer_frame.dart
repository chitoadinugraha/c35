import 'dart:ui';

class OverlayEffectPointerFrame {
  const OverlayEffectPointerFrame({
    this.pointers = const {},
    this.downs = const [],
    this.ups = const [],
  });

  final Map<int, Offset> pointers;
  final List<Offset> downs;
  final List<Offset> ups;

  bool get isEmpty => pointers.isEmpty && downs.isEmpty && ups.isEmpty;
}
