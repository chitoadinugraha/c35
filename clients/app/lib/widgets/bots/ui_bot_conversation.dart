import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ai/ui_user_bubble.dart';
import 'package:alienai_c35/widgets/chat/ui_chat_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const _bg = Color(0xFF08080A);
const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiBotConversation extends StatefulWidget {
  const UiBotConversation({
    super.key,
    required this.store,
    required this.chatId,
  });

  final BotStore store;
  final String chatId;

  @override
  State<UiBotConversation> createState() => _UiBotConversationState();
}

class _UiBotConversationState extends State<UiBotConversation> {
  late final _composer = TextEditingController();
  late final _timeline = UiChatTimelineController();
  final _consumptionApi = ConsumptionApi();

  @override
  void initState() {
    super.initState();
    _timeline.attach();
  }

  @override
  void dispose() {
    _composer.dispose();
    _timeline.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text;
    _composer.clear();
    try {
      await widget.store.chatSend(widget.chatId, text);
      if (mounted) _timeline.scrollToBottom(force: true);
    } catch (_) {}
  }

  Future<void> _toggleStop() async {
    try {
      await widget.store.chatStopToggle(widget.chatId);
    } catch (_) {}
  }

  Widget _msgTile(MsgRow m, {required int i, required int count}) {
    final isUser = m.role == 'user';
    final copyPrefix = msgCopyPrefix(role: m.role, userName: m.role == 'user' ? 'User' : 'Staff', createdAtMs: m.createdAtMs);

    Widget body;
    if (isUser) {
      body = UiUserBubble(content: m.content, copyPrefix: copyPrefix, attachments: m.attachments);
    } else {
      final thoughtView = msgThoughtView(thought: m.thought, content: m.content, thinking: false);
      final blocks = ChatBlock.decodeList(m.blocksJson);
      body = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF141417),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiMsgCopyPrefix(text: copyPrefix),
                if (thoughtView.thought != null) UiMsgThought(text: thoughtView.thought!, thinking: false),
                if (m.reqId.isNotEmpty) UiMsgTraceLoader(conn: widget.store.conn, reqId: m.reqId),
                if (m.content.trim().isNotEmpty)
                  MarkdownBody(
                    data: m.content,
                    selectable: false,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: _text, fontSize: 15, height: 1.45),
                      code: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Consolas', backgroundColor: Color(0xFF1A1A1D)),
                    ),
                  ),
                if (blocks.isNotEmpty)
                  UiMsgBlocks(
                    msgId: m.id,
                    blocks: blocks,
                    consumptionApi: _consumptionApi,
                    locale: 'en',
                    onConsumptionSaved: (_, __) {},
                  ),
                UiMsgUsage(msg: m, streaming: false),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: body),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final peer = widget.store.peerById(widget.chatId);
          final msgs = widget.store.msgsFor(widget.chatId);
          final name = peer?.peerName.isNotEmpty == true ? peer!.peerName : (peer?.title ?? 'Conversation');
          final stopped = peer != null && !peer.aiReplyEnabled;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (msgs.isNotEmpty) _timeline.scrollToBottom();
          });

          return ColoredBox(
            color: _bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(color: _bg, border: Border(bottom: BorderSide(color: _border))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        TextButton.icon(
                          onPressed: peer == null ? null : _toggleStop,
                          icon: Icon(stopped ? Icons.play_arrow_rounded : Icons.stop_circle_outlined, size: 18, color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                          label: Text(stopped ? 'Resume' : 'Stop', style: TextStyle(color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: widget.store.loadingMsgs && msgs.isEmpty
                      ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)))
                      : msgs.isEmpty
                          ? const Center(child: Text('No messages yet', style: TextStyle(color: _muted, fontSize: 13)))
                          : UiChatTimeline(
                              controller: _timeline,
                              itemCount: msgs.length,
                              itemBuilder: (context, i) => _msgTile(msgs[i], i: i, count: msgs.length),
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _composer,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(color: _text, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Send as staff…',
                            hintStyle: const TextStyle(color: _muted),
                            filled: true,
                            fillColor: const Color(0xFF18181B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF34D399))),
                          ),
                          onSubmitted: widget.store.sending ? null : (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: widget.store.sending ? null : _send,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: Colors.black, minimumSize: const Size(44, 44), padding: EdgeInsets.zero),
                        child: widget.store.sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}
