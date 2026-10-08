import 'package:flutter/foundation.dart';

/// Device-class throttle for overlay effect sim + draw.
///
/// Tier probe via device_info_plus is omitted so this port does not add a dependency.
/// [provisional] picks a tier from the current platform.
enum OverlayEffectTier { low, mid, high }

class OverlayEffectThrottle {
  OverlayEffectThrottle._(this.tier, this.densityScale, this.targetFps, this.simplifyShapes);

  final OverlayEffectTier tier;
  final double densityScale;
  final int targetFps;
  final bool simplifyShapes;

  static Future<OverlayEffectThrottle> resolve() async => provisional();

  /// Sync fallback before async probe finishes.
  static OverlayEffectThrottle provisional() {
    if (kIsWeb) return OverlayEffectThrottle._(OverlayEffectTier.high, 1.0, 60, false);
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return OverlayEffectThrottle._(OverlayEffectTier.mid, 0.7, 30, false);
    }
    return OverlayEffectThrottle._(OverlayEffectTier.high, 1.0, 60, false);
  }

  Duration get frameInterval => Duration(microseconds: (1000000 / targetFps).round());
}
