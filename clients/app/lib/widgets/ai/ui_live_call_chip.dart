import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/live/live_call_ui.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_hint_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_live_offer_icon.dart';
import 'package:flutter/material.dart';

const _chipText = Color(0xFFE4E4E7);
const _muted = Color(0xFF71717A);

class _UiLiveCallChipLabel extends StatelessWidget {
  const _UiLiveCallChipLabel({this.offer, required this.enabled, this.soonSuffix, this.text});

  final LiveOffer? offer;
  final bool enabled;
  final String? soonSuffix;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? _chipText : _muted;
    final style = TextStyle(color: textColor, fontSize: 13);
    final title = text ?? liveOfferActionTitle(offer!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: style),
        if (soonSuffix != null && soonSuffix!.isNotEmpty)
          Text(' ($soonSuffix)', style: TextStyle(color: _muted, fontSize: 13)),
      ],
    );
  }
}

class UiLiveCallChip extends StatelessWidget {
  const UiLiveCallChip({
    super.key,
    required this.composerModel,
    required this.offers,
    required this.onStart,
  });

  final AgentModel composerModel;
  final List<LiveOffer> offers;
  final ValueChanged<LiveOffer> onStart;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: catalogTranslationTick,
        builder: (context, _) {
          final menu = liveCallMenuOffers(offers, composerModel);
          if (menu.isEmpty) return const SizedBox.shrink();
          final genericChip = liveCallChipUsesGenericLabel(composerModel, offers);
          final anyEnabled = menu.any((o) => o.enabled);
          final showMenu = genericChip || menu.length > 1 || menu.any((o) => !o.enabled);
          final defaultOffer = liveCallDefaultOffer(menu, composerModel) ?? menu.first;
          final chipEnabled = showMenu ? anyEnabled : defaultOffer.enabled;
          final soonSuffix = chipEnabled ? null : liveOfferSoonTag();
          final chipTitle = genericChip ? liveCallGenericChipTitle() : null;

          void start(LiveOffer offer) {
            if (!offer.enabled) return;
            onStart(offer);
          }

          Widget chipLabel({LiveOffer? offer, required bool enabled, String? suffix, String? title}) =>
              _UiLiveCallChipLabel(offer: offer, enabled: enabled, soonSuffix: suffix, text: title);

          if (!showMenu) {
            return UiHintChip(
              icon: Icons.call_rounded,
              enabled: defaultOffer.enabled,
              label: chipLabel(offer: defaultOffer, enabled: defaultOffer.enabled, suffix: soonSuffix),
              onPressed: defaultOffer.enabled ? () => start(defaultOffer) : null,
            );
          }

          return MenuAnchor(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Color(0xFF18181B)),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              elevation: const WidgetStatePropertyAll(8),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
            ),
            menuChildren: [
              for (final o in menu)
                MenuItemButton(
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  ),
                  onPressed: o.enabled ? () => start(o) : null,
                  child: Row(
                    children: [
                      UiLiveOfferIcon(offer: o, size: 18, dimmed: !o.enabled),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          liveOfferMenuLabel(o),
                          style: TextStyle(color: o.enabled ? _chipText : _muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            builder: (context, controller, child) => UiHintChip(
              icon: Icons.call_rounded,
              enabled: chipEnabled,
              showChevron: true,
              label: chipLabel(
                offer: genericChip ? null : defaultOffer,
                enabled: chipEnabled,
                suffix: soonSuffix,
                title: chipTitle,
              ),
              onPressed: chipEnabled
                  ? () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    }
                  : null,
            ),
          );
        },
      );
}
