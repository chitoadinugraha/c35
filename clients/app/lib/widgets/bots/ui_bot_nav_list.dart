import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);

class UiBotNavList extends StatelessWidget {
  const UiBotNavList({
    super.key,
    required this.store,
    required this.selectedBotId,
    required this.onSelect,
    this.emptyMessage = 'No bots yet',
    this.hideEmptyMessage = false,
  });

  final BotStore store;
  final String? selectedBotId;
  final ValueChanged<String?> onSelect;
  final String emptyMessage;
  final bool hideEmptyMessage;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final bots = store.bots;
          return ColoredBox(
            color: const Color(0xFF0C0C10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text('Bots', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                if (store.loadingBots)
                  const Expanded(child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))))
                else if (bots.isEmpty && !hideEmptyMessage)
                  Expanded(child: Center(child: Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13))))
                else if (bots.isEmpty)
                  const Spacer()
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      itemCount: bots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final row = bots[i];
                        final id = row.identity.iid.toString();
                        final selected = selectedBotId == id;
                        return Material(
                          color: selected ? const Color(0xFF18181B) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: selected ? const BorderSide(color: _border) : BorderSide.none),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => onSelect(id),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: Row(
                                children: [
                                  UiUserAvatar(name: row.identity.name, pic: row.identity.pic, size: 32),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      row.identity.name.isNotEmpty ? row.identity.name : row.identity.alienId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: selected ? const Color(0xFFF4F4F5) : const Color(0xFFA1A1AA), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
