import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiBotAddMenu extends StatelessWidget {
  const UiBotAddMenu({super.key, required this.store});

  final BotStore store;

  Future<void> _onNewChatBot(BuildContext context) async {
    final created = await store.showCreateBot(context);
    if (created == null || !context.mounted) return;
    await store.botCreatedSelect(created);
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: uiPopupMenuTooltipText('Add bot'),
        color: const Color(0xFF18181B),
        onSelected: (v) => switch (v) {
          'chat' => _onNewChatBot(context),
          _ => null,
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'chat',
            child: ListTile(
              leading: Icon(Icons.smart_toy_outlined, color: Color(0xFFF4F4F5)),
              title: Text('New Chat Bot'),
              subtitle: Text('Telegram, WhatsApp, and more'),
            ),
          ),
        ],
        child: uiPopupMenuChild(tooltip: 'Add bot', child: const Icon(Icons.add, color: Color(0xFFF4F4F5))),
      );
}
