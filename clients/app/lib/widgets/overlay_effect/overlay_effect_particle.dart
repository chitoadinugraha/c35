import 'dart:ui';

const effectParticleStride = 8;
const effectKindLine = 0.0;
const effectKindGlyph = 1.0;
const effectKindEllipse = 2.0;
const effectKindEllipseFilled = 3.0;
const effectKindSakura = 4.0;
const effectKindLeaf = 5.0;
const effectKindMoon = 6.0;

double effectColorToWire(Color c) {
  final argb = c.toARGB32();
  final r = (argb >> 16) & 0xff;
  final g = (argb >> 8) & 0xff;
  final b = argb & 0xff;
  return r * 65536.0 + g * 256.0 + b;
}

void effectEmit(
  List<double> out, {
  required double kind,
  required double x,
  required double y,
  required double a,
  required double b,
  required double rot,
  required double opacity,
  required Color color,
}) {
  out.add(kind);
  out.add(x);
  out.add(y);
  out.add(a);
  out.add(b);
  out.add(rot);
  out.add(opacity);
  out.add(effectColorToWire(color));
}
