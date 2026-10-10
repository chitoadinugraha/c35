import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/consumption/consumption_food.dart';
import 'package:alienai_c35/c/consumption/consumption_glance.dart';
import 'package:alienai_c35/c/expense/expense_api.dart';
import 'package:alienai_c35/c/expense/expense_glance.dart';
import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/c/presentation/slide_deck_theme_prefs.dart';
import 'package:alienai_c35/c/generation/media_provider_labels.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_food_card.dart';
import 'package:alienai_c35/widgets/ai/ui_consumption_glance_card.dart';
import 'package:alienai_c35/widgets/ai/ui_expense_glance_card.dart';
import 'package:alienai_c35/widgets/ai/ui_attach_chips.dart';
import 'package:alienai_c35/widgets/ai/ui_expense_receipt_card.dart';
import 'package:alienai_c35/widgets/ai/ui_media_provider_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_media_provider_sheet.dart';
import 'package:alienai_c35/widgets/ai/ui_slide_deck_card.dart';
import 'package:alienai_c35/widgets/ai/ui_site_preview_card.dart';
import 'package:alienai_c35/widgets/ai/ui_stock_report_card.dart';
import 'package:alienai_c35/widgets/ai/ui_report_summary_card.dart';
import 'package:alienai_c35/widgets/ai/ui_tx_list_card.dart';
import 'package:flutter/material.dart';

typedef ConsumptionBlockSaved = void Function(int msgId, ChatBlock block);
typedef ExpenseBlockSaved = void Function(int msgId, ChatBlock block);
typedef BlockCollapsedChanged = void Function(int msgId, int blockIndex, bool collapsed);
typedef MediaRegenerateHandler = Future<void> Function(int msgId, int blockIndex, ChatBlock block, String provider, {required bool setDefault});

class UiMsgBlocks extends StatelessWidget {
  const UiMsgBlocks({
    super.key,
    required this.msgId,
    required this.blocks,
    this.chatId = 0,
    this.presentationDeckPrior,
    this.consumptionApi,
    this.expenseApi,
    this.locale = 'en-US',
    this.onConsumptionSaved,
    this.onExpenseSaved,
    this.onBlockCollapsedChanged,
    this.onImageUpgradeHd,
    this.onMediaRegenerate,
    this.primary = false,
    this.chatConn,
  });

  final int msgId;
  final List<ChatBlock> blocks;
  final int chatId;
  final SlideDeckData? presentationDeckPrior;
  final ConsumptionApi? consumptionApi;
  final ExpenseApi? expenseApi;
  final String locale;
  final ConsumptionBlockSaved? onConsumptionSaved;
  final ExpenseBlockSaved? onExpenseSaved;
  final BlockCollapsedChanged? onBlockCollapsedChanged;
  final void Function(ChatBlock block)? onImageUpgradeHd;
  final MediaRegenerateHandler? onMediaRegenerate;
  final bool primary;
  final ChatConn? chatConn;

  @override
  Widget build(BuildContext context) {
    var presentationDeck = presentationDeckPrior;
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      children.add(_block(context, b, i, presentationDeck: presentationDeck, onPresentationDeck: (d) => presentationDeck = d));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _block(
    BuildContext context,
    ChatBlock b,
    int blockIndex, {
    SlideDeckData? presentationDeck,
    void Function(SlideDeckData deck)? onPresentationDeck,
  }) {
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
        return _mediaAttachmentBlock(context, b, blockIndex, defaultMime: 'image/png', defaultName: 'image.png', showUpgradeHd: true);
      case 'video':
        return _mediaAttachmentBlock(context, b, blockIndex, defaultMime: 'video/mp4', defaultName: 'video.mp4');
      case 'music':
      case 'audio':
        return _mediaAttachmentBlock(context, b, blockIndex, defaultMime: 'audio/mpeg', defaultName: 'audio.mp3');
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
      case 'site.stock_report':
        return UiStockReportCard(body: b.body);
      case 'site.tx_list':
        return UiTxListCard(body: b.body, locale: locale);
      case 'site.report_summary':
        return UiReportSummaryCard(body: b.body, locale: locale);
      case 'presentation.deck':
      case 'slide.deck':
      case 'presentation':
        final deck = SlideDeckData.fromBlockBody(b.body, presentationDeck);
        final themeOverride = SlideDeckThemePrefs.instance.themeFor(chatId);
        if (themeOverride != null) deck.theme = themeOverride;
        onPresentationDeck?.call(deck);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiSlideDeckCard(
            deck: deck,
            chatId: chatId,
            initiallyExpanded: !b.collapsed || primary,
          ),
        );
      case 'site.preview':
      case 'site.builder':
      case 'site.deck':
        final data = SitePreviewData.fromJson(b.body);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: UiSitePreviewCard(
            data: data,
            conn: chatConn,
            initiallyExpanded: !b.collapsed || primary,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _mediaAttachmentBlock(
    BuildContext context,
    ChatBlock b,
    int blockIndex, {
    required String defaultMime,
    required String defaultName,
    bool showUpgradeHd = false,
  }) {
    final hash = b.body['hash']?.toString() ?? '';
    final url = b.body['url']?.toString() ?? '';
    if (hash.isEmpty && url.isEmpty && !ChatBlock.mediaHasProviderChip(b)) return const SizedBox.shrink();
    final mime = b.body['mime']?.toString() ?? defaultMime;
    final prompt = b.body['prompt']?.toString().trim() ?? '';
    final name = prompt.isNotEmpty ? prompt : defaultName;
    final canUpgrade = showUpgradeHd && onImageUpgradeHd != null && !ChatBlock.imageIsHd(b);
    final kind = mediaBlockKind(b.kind);
    final provider = ChatBlock.mediaProvider(b);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hash.isNotEmpty || url.isNotEmpty)
            UiAttachChips(
              attachments: [MsgAttachment(hash: hash, name: name, mime: mime, url: url)],
              showUpgradeHd: canUpgrade,
              onUpgradeHd: canUpgrade ? () => onImageUpgradeHd!(b) : null,
            ),
          if (provider.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: UiMediaProviderChip(
                kind: kind,
                providerId: provider,
                onTap: onMediaRegenerate == null
                    ? null
                    : () => uiMediaProviderSheetShow(
                          context,
                          blockKind: b.kind,
                          block: b,
                          onRegenerate: (p, {required setDefault}) => onMediaRegenerate!(msgId, blockIndex, b, p, setDefault: setDefault),
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
