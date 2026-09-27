import 'dart:async';

import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:alienai_c35/widgets/devices/in_device_prompt_composer.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _panel = Color(0xFF111114);
const _zinc100 = Color(0xFFF4F4F5);
const _zinc400 = Color(0xFFA1A1AA);
const _zinc500 = Color(0xFF71717A);
const _amber = Color(0xFFF59E0B);

Future<void> showDevicePromptSheet(BuildContext context, DevicePromptContextStore store, {required String deviceName}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _panel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) => UiDevicePromptSheet(store: store, deviceName: deviceName),
  );
}

class UiDevicePromptSheet extends StatefulWidget {
  const UiDevicePromptSheet({super.key, required this.store, required this.deviceName});

  final DevicePromptContextStore store;
  final String deviceName;

  @override
  State<UiDevicePromptSheet> createState() => _UiDevicePromptSheetState();
}

class _UiDevicePromptSheetState extends State<UiDevicePromptSheet> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    widget.store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _scroll.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) {
      setState(() {});
      if (widget.store.streaming) _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
  }

  String _roleLabel(ChatMsg m) => switch (m.role) {
        ChatMsgRole.CHAT_MSG_ROLE_USER => 'You',
        ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT => 'AI',
        _ => m.role.name,
      };

  String _formatTime(Int64 ts) {
    if (ts <= Int64.ZERO) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.activeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _zinc100)),
                      Text('Device prompt history', style: const TextStyle(fontSize: 11, color: _zinc500)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'New context',
                  onPressed: store.loading ? null : () => unawaited(store.contextCreate()),
                  icon: const Icon(Icons.add_rounded, color: _amber),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: _zinc400),
                ),
              ],
            ),
          ),
          if (store.contexts.length > 1)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: store.contexts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final c = store.contexts[i];
                  final id = c.id.toInt();
                  final selected = id == store.activeChatId;
                  final archived = (store.membersByChatId[id]?.archivedTsMs ?? Int64.ZERO) > Int64.ZERO;
                  return ChoiceChip(
                    label: Text(c.title.isNotEmpty ? c.title : widget.deviceName, style: TextStyle(fontSize: 11, color: selected ? _zinc100 : _zinc400)),
                    selected: selected,
                    onSelected: store.loading ? null : (_) => unawaited(store.contextSelect(id)),
                    selectedColor: _amber.withValues(alpha: 0.2),
                    backgroundColor: const Color(0xFF18181B),
                    side: BorderSide(color: selected ? _amber : _border),
                    avatar: archived ? const Icon(Icons.inventory_2_outlined, size: 14, color: _zinc500) : null,
                  );
                },
              ),
            ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: store.messagesLoading && store.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: store.messages.length + (store.messagesCanLoadMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (store.messagesCanLoadMore && i == 0) {
                        return TextButton(
                          onPressed: () => unawaited(store.messagesReload(loadMore: true)),
                          child: const Text('Load older', style: TextStyle(fontSize: 12, color: _zinc400)),
                        );
                      }
                      final idx = store.messagesCanLoadMore ? i - 1 : i;
                      final m = store.messages[idx];
                      final preview = m.content.trim().isNotEmpty ? m.content.trim() : (m.errorText.isNotEmpty ? m.errorText : '…');
                      final streamingRow = store.streaming && idx == store.messages.length - 1 && m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 44,
                              child: Text(_roleLabel(m), style: TextStyle(fontSize: 10, color: m.role == ChatMsgRole.CHAT_MSG_ROLE_USER ? _amber : _zinc400)),
                            ),
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: m.errorText.isNotEmpty ? const Color(0xFFFCA5A5) : _zinc100),
                              ),
                            ),
                            if (streamingRow)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: _amber)),
                              )
                            else
                              Text(_formatTime(m.createdTsMs), style: const TextStyle(fontSize: 10, color: _zinc500)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: _border),
          InDevicePromptComposer(store: store, deviceName: widget.deviceName, dense: true),
          SizedBox(height: bottom),
        ],
      ),
    );
  }
}
