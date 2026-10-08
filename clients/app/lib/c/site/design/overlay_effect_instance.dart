class SiteOverlayEffectDraft {
  const SiteOverlayEffectDraft({
    required this.id,
    required this.presetId,
    this.params = const {},
    this.active = true,
  });

  final String id;
  final String presetId;
  final Map<String, Object?> params;
  final bool active;

  SiteOverlayEffectDraft copyWith({
    String? id,
    String? presetId,
    Map<String, Object?>? params,
    bool? active,
  }) =>
      SiteOverlayEffectDraft(
        id: id ?? this.id,
        presetId: presetId ?? this.presetId,
        params: params ?? this.params,
        active: active ?? this.active,
      );
}

const runnableOverlayEffectPresetIds = {
  'rain-shower',
  'falling-hearts',
  'snow-fall',
  'floating-bubbles',
  'thunderstorm',
  'fireworks',
  'starry-night',
  'drifting-clouds',
  'matrix-rain',
  'sakura-petals',
  'moonlight',
  'autumn-leaves',
};

/// Presets.json uses hyphen ids (`rain-shower`). Callers may also pass underscores (`rain_shower`).
String overlayEffectPresetCanonical(String presetId) {
  if (runnableOverlayEffectPresetIds.contains(presetId)) return presetId;
  final dashed = presetId.replaceAll('_', '-');
  if (runnableOverlayEffectPresetIds.contains(dashed)) return dashed;
  return presetId;
}

bool overlayEffectPresetRunnable(String presetId) =>
    runnableOverlayEffectPresetIds.contains(overlayEffectPresetCanonical(presetId));

String overlayEffectInstanceNewId(String presetId) =>
    'effect-$presetId-${DateTime.now().microsecondsSinceEpoch}';
