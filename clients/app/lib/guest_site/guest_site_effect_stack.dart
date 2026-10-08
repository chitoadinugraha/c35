import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'package:alienai_c35/widgets/overlay_effect/ui_overlay_effect_stack.dart';
import 'package:flutter/material.dart';

/// Theme `effects` rows (`id`, `presetId`, `params`, `active`) for the guest page.
List<Map<String, dynamic>> guestSiteThemeEffects(Map<String, dynamic> theme) {
  final raw = theme['effects'];
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map) out.add(item.map((k, v) => MapEntry(k.toString(), v)));
  }
  return out;
}

/// Paints active overlay presets under [child]. The parent already paints the backdrop.
class GuestSiteEffectStack extends StatelessWidget {
  const GuestSiteEffectStack({super.key, required this.effects, required this.child});

  final List<Map<String, dynamic>> effects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final drafts = <SiteOverlayEffectDraft>[];
    for (final raw in effects) {
      final draft = guestSiteEffectDraft(raw);
      if (draft != null) drafts.add(draft);
    }
    if (drafts.isEmpty) return child;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: UiOverlayEffectStack(effects: drafts),
          ),
        ),
        child,
      ],
    );
  }
}

/// Active rows with a known preset become a draft. Unknown ids are skipped.
SiteOverlayEffectDraft? guestSiteEffectDraft(Map<String, dynamic> raw) {
  final id = raw['id']?.toString().trim() ?? '';
  final presetId = raw['presetId']?.toString().trim() ?? '';
  if (id.isEmpty || presetId.isEmpty) return null;
  if (raw['active'] == false) return null;
  if (!overlayEffectPresetRunnable(presetId)) return null;
  final params = <String, Object?>{};
  final rawParams = raw['params'];
  if (rawParams is Map) {
    for (final e in rawParams.entries) {
      params[e.key.toString()] = e.value;
    }
  }
  return SiteOverlayEffectDraft(id: id, presetId: presetId, params: params, active: true);
}
