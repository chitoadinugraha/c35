import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/hint/hint_chip_theme.dart';
import 'package:alienai_c35/c/live/live_call_ui.dart';
import 'package:alienai_c35/c/live/live_offer.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/widgets/ai/ui_hint_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_live_offer_icon.dart';
import 'package:flutter/material.dart';

const _chipText = Color(0xFFE4E4E7);
const _muted = Color(0xFF71717A);

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
          final anyEnabled = menu.any((o) => o.enabled);
          final showMenu = menu.length > 1 || menu.any((o) => !o.enabled);
          final defaultOffer = liveCallDefaultOffer(menu, composerModel) ?? menu.first;
          final primaryChipLabel = anyEnabled
              ? liveOfferLabel(defaultOffer)
              : '${liveOfferLabel(defaultOffer)} (${liveOfferSoonTag()})';
          const theme = HintChipTheme.liveCall;

          void start(LiveOffer offer) {
            if (!offer.enabled) return;
            onStart(offer);
          }

          if (!showMenu) {
            return UiHintChip(
              theme: theme,
              leading: UiLiveOfferIcon(offer: defaultOffer, size: 16, dimmed: !defaultOffer.enabled),
              enabled: defaultOffer.enabled,
              label: Text(primaryChipLabel),
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
              theme: theme,
              leading: UiLiveOfferIcon(offer: defaultOffer, size: 16, dimmed: !anyEnabled),
              enabled: anyEnabled,
              showChevron: true,
              label: Text(primaryChipLabel),
              onPressed: anyEnabled
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
