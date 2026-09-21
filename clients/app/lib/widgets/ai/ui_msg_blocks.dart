import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/c/consumption/consumption_glance.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_food_card.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_glance_card.dart';
import 'package:flutter/material.dart';

typedef ConsumptionBlockSaved = void Function(int msgId, ChatBlock block);

class UiMsgBlocks extends StatelessWidget {
  const UiMsgBlocks({super.key, required this.msgId, required this.blocks, this.consumptionApi, this.locale = 'en-US', this.onConsumptionSaved});

  final int msgId;
  final List<ChatBlock> blocks;
  final ConsumptionApi? consumptionApi;
  final String locale;
  final ConsumptionBlockSaved? onConsumptionSaved;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in blocks) _block(context, b)],
      );

  Widget _block(BuildContext context, ChatBlock b) {
    switch (b.kind) {
      case 'consumption.food':
        final card = ConsumptionFoodCard.fromBlockBody(b.body);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiConsumptionFoodCard(
            card: card,
            collapsed: b.collapsed,
            locale: locale,
            onSave: card.editable && consumptionApi != null
                ? (items) async {
                    final id = int.tryParse(card.consumptionId) ?? 0;
                    if (id == 0) return;
                    final res = await consumptionApi!.update(consumptionId: id, items: items, locale: locale);
                    final block = res['block'];
                    if (block is Map<String, dynamic>) {
                      onConsumptionSaved?.call(msgId, ChatBlock.fromJson(block));
                    }
                  }
                : null,
          ),
        );
      case 'consumption.glance':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiConsumptionGlanceCard(
            card: ConsumptionGlanceCard.fromBlockBody(b.body),
            collapsed: b.collapsed,
            locale: locale,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
