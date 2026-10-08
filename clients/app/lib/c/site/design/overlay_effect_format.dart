import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'package:alienai_c35/c/site/design/overlay_effect_preset.dart';

String overlayEffectFormatNumber(num value) {
  final negative = value < 0;
  final abs = value.abs();
  final whole = abs == abs.roundToDouble();
  final text = whole ? abs.round().toString() : abs.toStringAsFixed(1);
  return negative ? '-$text' : text;
}

String overlayEffectSubtitle({
  required List<SiteOverlayEffectDraft> effects,
  required OverlayEffectPresetCatalog catalog,
}) {
  final active = effects.where((e) => e.active).toList();
  if (active.isEmpty) return 'No effects';
  if (active.length == 1) {
    final preset = catalog.presetById(active.first.presetId);
    return preset?.name ?? active.first.presetId;
  }
  return '${active.length} active effects';
}
