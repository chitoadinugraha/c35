import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/c/consumption/consumption_glance.dart';
import 'package:alienai_c35/c/expense/expense_api.dart';
import 'package:alienai_c35/c/expense/expense_glance.dart';
import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_food_card.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_glance_card.dart';
import 'package:alienai_c35/widgets/ai/ui_expense_glance_card.dart';
import 'package:alienai_c35/widgets/ai/ui_attach_chips.dart';
import 'package:alienai_c35/widgets/ai/ui_expense_receipt_card.dart';
import 'package:flutter/material.dart';

typedef ConsumptionBlockSaved = void Function(int msgId, ChatBlock block);
typedef ExpenseBlockSaved = void Function(int msgId, ChatBlock block);
typedef BlockCollapsedChanged = void Function(int msgId, int blockIndex, bool collapsed);

class UiMsgBlocks extends StatelessWidget {
  const UiMsgBlocks({
    super.key,
    required this.msgId,
    required this.blocks,
    this.consumptionApi,
    this.expenseApi,
    this.locale = 'en-US',
    this.onConsumptionSaved,
    this.onExpenseSaved,
    this.onBlockCollapsedChanged,
    this.onImageUpgradeHd,
    this.primary = false,
  });

  final int msgId;
  final List<ChatBlock> blocks;
  final ConsumptionApi? consumptionApi;
  final ExpenseApi? expenseApi;
  final String locale;
  final ConsumptionBlockSaved? onConsumptionSaved;
  final ExpenseBlockSaved? onExpenseSaved;
  final BlockCollapsedChanged? onBlockCollapsedChanged;
  final void Function(ChatBlock block)? onImageUpgradeHd;
  final bool primary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < blocks.length; i++) _block(context, blocks[i], i)],
      );

  Widget _block(BuildContext context, ChatBlock b, int blockIndex) {
    switch (b.kind) {
      case 'consumption.food':
        final card = ConsumptionFoodCard.fromBlockBody(b.body);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiConsumptionFoodCard(
            card: card,
            collapsed: b.collapsed && !primary,
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
            onDelete: card.editable && consumptionApi != null
                ? () async {
                    final id = int.tryParse(card.consumptionId) ?? 0;
                    if (id == 0) return;
                    await consumptionApi!.delete(consumptionId: id);
                  }
                : null,
            onCollapsedChanged: onBlockCollapsedChanged == null
                ? null
                : (collapsed) => onBlockCollapsedChanged!(msgId, blockIndex, collapsed),
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
      case 'expense.receipt':
        final card = ExpenseReceiptCard.fromBlockBody(b.body);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiExpenseReceiptCard(
            card: card,
            collapsed: b.collapsed && !primary,
            locale: locale,
            onSave: card.editable && expenseApi != null
                ? (items) async {
                    final id = int.tryParse(card.txId) ?? 0;
                    if (id == 0) return;
                    final res = await expenseApi!.update(txId: id, items: items, locale: locale);
                    final block = res['block'];
                    if (block is Map<String, dynamic>) {
                      onExpenseSaved?.call(msgId, ChatBlock.fromJson(block));
                    }
                  }
                : null,
            onDelete: card.editable && expenseApi != null
                ? () async {
                    final id = int.tryParse(card.txId) ?? 0;
                    if (id == 0) return;
                    await expenseApi!.delete(txId: id);
                  }
                : null,
          ),
        );
      case 'expense.glance':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiExpenseGlanceCard(
            card: ExpenseGlanceCard.fromBlockBody(b.body),
            collapsed: b.collapsed,
            locale: locale,
          ),
        );
      case 'image':
        final hash = b.body['hash']?.toString() ?? '';
        final url = b.body['url']?.toString() ?? '';
        if (hash.isEmpty && url.isEmpty) return const SizedBox.shrink();
        final mime = b.body['mime']?.toString() ?? 'image/png';
        final prompt = b.body['prompt']?.toString().trim() ?? '';
        final name = prompt.isNotEmpty ? prompt : 'image.png';
        final canUpgrade = onImageUpgradeHd != null && !ChatBlock.imageIsHd(b);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiAttachChips(
            attachments: [MsgAttachment(hash: hash, name: name, mime: mime, url: url)],
            showUpgradeHd: canUpgrade,
            onUpgradeHd: canUpgrade ? () => onImageUpgradeHd!(b) : null,
          ),
        );
      case 'file':
      case 'attachment':
        final hash = b.body['hash']?.toString() ?? '';
        final url = b.body['url']?.toString() ?? '';
        if (hash.isEmpty && url.isEmpty) return const SizedBox.shrink();
        final mime = b.body['mime']?.toString() ?? 'application/octet-stream';
        final name = b.body['name']?.toString().trim() ?? (b.body['filename']?.toString().trim() ?? 'file');
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiAttachChips(
            attachments: [MsgAttachment(hash: hash, name: name, mime: mime, url: url)],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
