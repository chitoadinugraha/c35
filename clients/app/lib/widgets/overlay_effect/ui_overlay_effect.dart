import 'package:flutter/material.dart';

import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'overlay_effect_pointer_hub.dart';
import 'ui_overlay_effect_stack.dart';

/// One enabled overlay effect layer — prefer [UiOverlayEffectStack] which hosts
/// all layers on a background isolate. Kept for call-site compatibility.
class UiOverlayEffect extends StatelessWidget {
  const UiOverlayEffect({super.key, required this.effect, this.pointerHub});

  final SiteOverlayEffectDraft effect;
  final OverlayEffectPointerHub? pointerHub;

  @override
  Widget build(BuildContext context) {
    if (!effect.active) return const SizedBox.shrink();
    return UiOverlayEffectStack(effects: [effect], pointerHub: pointerHub);
  }
}
