import 'overlay_effect_instance.dart';
import 'overlay_effect_param_read.dart';
import 'overlay_effect_preset.dart';

SiteOverlayEffectDraft? overlayEffectNormalize(SiteOverlayEffectDraft effect, OverlayEffectPreset preset) {
  final params = <String, Object?>{...preset.defaultParams()};
  for (final param in preset.parameters) {
    final raw = effect.params[param.key];
    if (raw == null) continue;
    params[param.key] = _coerceParam(param, raw);
  }
  return SiteOverlayEffectDraft(
    id: effect.id.isNotEmpty ? effect.id : overlayEffectInstanceNewId(effect.presetId),
    presetId: effect.presetId,
    params: params,
    active: effect.active,
  );
}

Object? _coerceParam(OverlayEffectParamDef param, Object? raw) => switch (param.type) {
      OverlayEffectParamType.boolean => raw is bool
          ? raw
          : raw == true || raw == 'true' || raw == 1 || raw == '1',
      OverlayEffectParamType.color => raw is String ? raw : param.defaultValue,
      OverlayEffectParamType.number => _coerceNumber(param, raw),
    };

num _coerceNumber(OverlayEffectParamDef param, Object? raw) {
  if (raw is bool) return overlayEffectParamNum(param.defaultValue, fallback: 0);
  final n = switch (raw) {
    num v => v.toDouble(),
    String v => double.tryParse(v) ?? overlayEffectParamNum(param.defaultValue, fallback: 0).toDouble(),
    _ => overlayEffectParamNum(param.defaultValue, fallback: 0).toDouble(),
  };
  final min = param.min;
  final max = param.max;
  if (min != null && n < min) return min;
  if (max != null && n > max) return max;
  return n;
}

SiteOverlayEffectDraft overlayEffectCreate(String presetId, OverlayEffectPreset preset, {String? id}) =>
    overlayEffectNormalize(
      SiteOverlayEffectDraft(
        id: id ?? overlayEffectInstanceNewId(presetId),
        presetId: presetId,
        params: const {},
      ),
      preset,
    )!;
