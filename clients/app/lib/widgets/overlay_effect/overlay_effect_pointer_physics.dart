import 'dart:math' as math;
import 'dart:ui';

bool overlayEffectBelowTouch(Offset center, double y, double margin) => y > center.dy + margin;

double overlayEffectDist2(Offset center, double x, double y) {
  final dx = center.dx - x;
  final dy = center.dy - y;
  return dx * dx + dy * dy;
}

/// Normalized proximity 0..1 within [radius], or null if outside / below touch.
double? overlayEffectTouchPullT(
  Offset center,
  double x,
  double y,
  double radius, {
  double belowMargin = 0,
}) {
  if (overlayEffectBelowTouch(center, y, belowMargin)) return null;
  final dist2 = overlayEffectDist2(center, x, y);
  final r2 = radius * radius;
  if (dist2 < 1 || dist2 > r2) return null;
  final dist = math.sqrt(dist2);
  return 1 - (dist / radius).clamp(0.0, 1.0);
}

void overlayEffectApplyRepulse({
  required double x,
  required double y,
  required void Function(double ax, double ay) apply,
  required Iterable<Offset> pointers,
  required double radius,
  required double strength,
  double belowMargin = 0,
}) {
  for (final center in pointers) {
    final pullT = overlayEffectTouchPullT(center, x, y, radius, belowMargin: belowMargin);
    if (pullT == null) continue;
    final dx = x - center.dx;
    final dy = y - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) continue;
    final nx = dx / dist;
    final ny = dy / dist;
    final amt = pullT * pullT * strength;
    apply(nx * amt, ny * amt);
  }
}

void overlayEffectApplyGust({
  required double x,
  required double y,
  required double Function() readDriftX,
  required void Function(double driftX) writeDriftX,
  required Iterable<Offset> pointers,
  required double radius,
  required double strength,
}) {
  for (final center in pointers) {
    final pullT = overlayEffectTouchPullT(center, x, y, radius);
    if (pullT == null) continue;
    final dir = center.dx >= x ? 1.0 : -1.0;
    writeDriftX(readDriftX() + dir * strength * pullT * 0.35);
  }
}

void overlayEffectApplySwirl({
  required double x,
  required double y,
  required void Function(double ax, double ay) apply,
  required Iterable<Offset> pointers,
  required double radius,
  required double strength,
  bool clockwise = true,
}) {
  final spin = clockwise ? 1.0 : -1.0;
  for (final center in pointers) {
    final pullT = overlayEffectTouchPullT(center, x, y, radius);
    if (pullT == null) continue;
    final dx = x - center.dx;
    final dy = y - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) continue;
    final tx = -dy / dist * spin;
    final ty = dx / dist * spin;
    final amt = pullT * strength;
    apply(tx * amt, ty * amt);
  }
}

bool overlayEffectNearTouch(
  Iterable<Offset> pointers,
  double x,
  double y,
  double radius, {
  double belowMargin = 0,
}) {
  for (final center in pointers) {
    if (overlayEffectTouchPullT(center, x, y, radius, belowMargin: belowMargin) != null) return true;
  }
  return false;
}
