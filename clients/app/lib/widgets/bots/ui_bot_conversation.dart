import 'dart:async';

import 'package:alienai_c35/c/bot/bot_meta.dart';
import 'package:alienai_c35/c/bot/bot_store.dart';
import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/expense/expense_api.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ai/in_composer.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_user_bubble.dart';
import 'package:alienai_c35/widgets/bots/ui_bot_peer_avatar.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:alienai_c35/widgets/chat/ui_chat_timeline.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const _bg = Color(0xFF08080A);
const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _bubbleMaxW = 520.0;
const _botBubbleBg = Color(0xFF1A1625);
const _botBubbleBorder = Color(0xFF5B21B6);
const _msgAvatarSize = 32.0;

Widget _msgTimeLabel(int createdAtMs, {required bool leading}) => createdAtMs > 0
    ? Padding(
        padding: leading ? const EdgeInsets.only(right: 6, bottom: 2) : const EdgeInsets.only(left: 6, bottom: 2),
        child: Text(chatMsgTimeLabel(createdAtMs), style: UiMsgUsage.style),
      )
    : const SizedBox.shrink();

class UiBotConversation extends StatefulWidget {
  const UiBotConversation({
    super.key,
    required this.store,
    required this.chatId,
    this.showTitleBar = true,
  });

  final BotStore store;
  final String chatId;
  final bool showTitleBar;

  @override
  State<UiBotConversation> createState() => _UiBotConversationState();
}

class _UiBotConversationState extends State<UiBotConversation> {
  late final _composerCtrl = TextEditingController();
  late final _composerFocus = FocusNode();
  late final _timeline = UiChatTimelineController();
  final _consumptionApi = ConsumptionApi();
  final _expenseApi = ExpenseApi();
  var _menuMsgIndex = 0;
  String? _selectedPlain;
  var _retrying = false;

  @override
  void initState() {
    super.initState();
    _timeline.attach();
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    _composerFocus.dispose();
    _timeline.dispose();
    super.dispose();
  }

  Future<void> _sendFromComposer(String text, List<MsgAttachment> attachments) async {
    try {
      if (widget.store.chatIsApp(widget.chatId)) {
        await widget.store.chatAppSend(widget.chatId, text, attachments: attachments);
      } else {
        await widget.store.chatSend(widget.chatId, text, attachments: attachments);
      }
      if (mounted) _timeline.scrollToBottom(force: true);
    } catch (_) {}
  }

  Future<void> _toggleStop() async {
    try {
      await widget.store.chatStopToggle(widget.chatId);
    } catch (_) {}
  }

  String _plainForMsg(MsgRow m) {
    final parts = <String>[];
    final content = msgDisplayContent(m).trim();
    if (content.isNotEmpty) parts.add(content);
    if (m.role == 'assistant' && m.thought.trim().isNotEmpty) parts.add(msgThoughtStripPlaceholders(m.thought));
    return parts.join('\n\n');
  }

  Future<void> _retryLastTurn() async {
    if (_retrying || !widget.store.chatIsApp(widget.chatId)) return;
    ContextMenuController.removeAny();
    setState(() => _retrying = true);
    try {
      await widget.store.chatAppRetryLastTurn(widget.chatId);
      if (mounted) _timeline.scrollToBottom(force: true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Widget _messageContextMenu(BuildContext ctx, SelectableRegionState state, List<MsgRow> msgs) {
    if (msgs.isEmpty) return const SizedBox.shrink();
    final i = _menuMsgIndex.clamp(0, msgs.length - 1);
    final m = msgs[i];
    final isAssistant = m.role == 'assistant' && m.source != 'staff';
    final plain = _plainForMsg(m);
    final lastUserIdx = msgs.lastIndexWhere((x) => x.role == 'user');
    final lastAssistantIdx = msgs.lastIndexWhere((x) => x.role == 'assistant');
    final isApp = widget.store.chatIsApp(widget.chatId);
    final showRetry = isApp && !widget.store.composerBusy && !_retrying && (i == lastUserIdx || i == lastAssistantIdx);
    return msgBubbleContextMenu(
      ctx,
      state,
      plainText: plain,
      selectedText: _selectedPlain,
      viewerIsRoot: sessionViewerIsRoot(),
      isAssistant: isAssistant,
      reqId: m.reqId,
      msgId: m.id > 0 ? m.id : 0,
      showRetry: showRetry,
      onRetryLastTurn: showRetry ? _retryLastTurn : null,
      conn: widget.store.conn,
    );
  }

  /// App chat preview: end-user sent (peer) on the right, bot on the left. Channel inbox: customer left, bot right. Staff always sent (right).
  bool _msgAlignEnd({required bool isPeerSide, bool isStaff = false}) {
    if (isStaff) return true;
    return widget.store.chatIsApp(widget.chatId) ? isPeerSide : !isPeerSide;
  }

  Widget _msgTile(MsgRow m, {required int i, required int count}) {
    final peer = widget.store.peerById(widget.chatId);
    final platform = widget.store.peerChannelPlatform(peer);
    final peerName = peer?.peerName.isNotEmpty == true ? peer!.peerName : (peer?.title ?? 'Customer');
    final peerPic = widget.store.peerDisplayPic(peer);
    final bot = widget.store.botById(widget.store.selectedBotId);
    final botName = bot?.identity.name.isNotEmpty == true ? bot!.identity.name : 'Bot';
    final botPic = bot?.identity.pic ?? '';
    final isCustomer = m.role == 'user';
    final isStaff = m.source == 'staff';
    final isBotAi = m.role == 'assistant' && !isStaff;
    final staffName = Session.instance.name.trim().isNotEmpty ? Session.instance.name : 'Staff';
    final copyPrefix = msgCopyPrefix(
      role: m.role,
      userName: isCustomer ? peerName : (isStaff ? staffName : (isBotAi ? botName : 'Staff')),
      createdAtMs: m.createdAtMs,
    );

    Widget bubble;
    if (isCustomer || isStaff) {
      bubble = UiUserBubble(content: m.content, copyPrefix: copyPrefix, attachments: m.attachments);
    } else {
      final thoughtView = msgThoughtView(thought: m.thought, content: m.content, thinking: false);
      final blocks = ChatBlock.decodeList(m.blocksJson);
      bubble = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _bubbleMaxW),
        child: IntrinsicWidth(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _botBubbleBg,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
              border: Border.all(color: _botBubbleBorder.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiMsgCopyPrefix(text: copyPrefix),
                  if (thoughtView.thought != null) UiMsgThought(text: thoughtView.thought!, thinking: false),
                  if (m.reqId.isNotEmpty)
                    UiMsgTraceLoader(conn: widget.store.conn, reqId: m.reqId, part: MsgTracePart.chips),
                  if (m.content.trim().isNotEmpty)
                    UiMarkdownBody(
                      data: m.content,
                      selectable: false,
                      styleSheet: uiMarkdownChatStyleSheet(
                        p: const TextStyle(color: _text, fontSize: 15, height: 1.45),
                        code: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Consolas', backgroundColor: Color(0xFF1A1A1D)),
                      ),
                    ),
                  if (m.reqId.isNotEmpty) UiMsgTraceLoader(conn: widget.store.conn, reqId: m.reqId, part: MsgTracePart.citations),
                  if (blocks.isNotEmpty)
                    UiMsgBlocks(
                      msgId: m.id,
                      blocks: blocks,
                      consumptionApi: _consumptionApi,
                      expenseApi: _expenseApi,
                      locale: 'en',
                      onConsumptionSaved: (_, __) {},
                    ),
                  if (isBotAi)
                    UiMsgUsageWithTrace(
                      conn: widget.store.conn,
                      msg: m.model.isNotEmpty ? m : m.copyWith(model: peer?.model ?? ''),
                      showTimestamp: false,
                      alwaysShow: true,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final alignEnd = _msgAlignEnd(isPeerSide: isCustomer, isStaff: isStaff);
    final peerAvatar = UiBotPeerAvatar(name: peerName, pic: peerPic, platform: platform, size: _msgAvatarSize);
    final botAvatar = UiUserAvatar(name: botName, pic: botPic, size: _msgAvatarSize);
    final staffAvatar = UiUserAvatar(
      name: staffName,
      pic: Session.instance.pic,
      email: Session.instance.email,
      handle: Session.instance.handle,
      size: _msgAvatarSize,
    );
    final avatar = isCustomer ? peerAvatar : (isStaff ? staffAvatar : botAvatar);
    final time = _msgTimeLabel(m.createdAtMs, leading: alignEnd);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: alignEnd
          ? [
              time,
              Flexible(child: bubble),
              const SizedBox(width: 8),
              avatar,
            ]
          : [
              avatar,
              const SizedBox(width: 8),
              Flexible(child: bubble),
              _msgTimeLabel(m.createdAtMs, leading: false),
            ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft, child: row),
    );
  }

  Widget _typingRow(String party) {
    final isPeer = party == 'peer';
    final peer = widget.store.peerById(widget.chatId);
    final platform = widget.store.peerChannelPlatform(peer);
    final peerName = peer?.peerName.isNotEmpty == true ? peer!.peerName : (peer?.title ?? 'Customer');
    final peerPic = widget.store.peerDisplayPic(peer);
    final bot = widget.store.botById(widget.store.selectedBotId);
    final botName = bot?.identity.name.isNotEmpty == true ? bot!.identity.name : 'Bot';
    final botPic = bot?.identity.pic ?? '';
    final label = isPeer ? 'bots.typingPeer'.tr() : 'bots.typingBot'.tr();

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _bubbleMaxW),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isPeer ? const Color(0xFF27272A) : _botBubbleBg,
          borderRadius: isPeer
              ? const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4))
              : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
          border: Border.all(color: isPeer ? _border.withValues(alpha: 0.85) : _botBubbleBorder.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: UiThinkingDots(color: isPeer ? const Color(0xFFA1A1AA) : const Color(0xFFA78BFA), size: 4, spacing: 3),
        ),
      ),
    );

    final alignEnd = _msgAlignEnd(isPeerSide: isPeer);
    final peerAvatar = UiBotPeerAvatar(name: peerName, pic: peerPic, platform: platform, size: _msgAvatarSize);
    final botAvatar = UiUserAvatar(name: botName, pic: botPic, size: _msgAvatarSize);
    final avatar = isPeer ? peerAvatar : botAvatar;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: alignEnd
          ? [bubble, const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), bubble],
    );

    return Semantics(
      label: label,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Align(alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft, child: row),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([widget.store, AppStore.instance]),
        builder: (context, _) {
          final peer = widget.store.peerById(widget.chatId);
          final msgs = widget.store.msgsFor(widget.chatId);
          final name = peer?.peerName.isNotEmpty == true ? peer!.peerName : (peer?.title ?? 'Conversation');
          final stopped = peer != null && !peer.aiReplyEnabled;
          final isApp = widget.store.chatIsApp(widget.chatId);
          final typingParty = widget.store.chatTypingParty(widget.chatId) ?? (isApp && widget.store.composerBusy ? 'bot' : null);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (msgs.isNotEmpty || typingParty != null) _timeline.scrollToBottom(force: typingParty != null);
          });

          return ColoredBox(
            color: _bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showTitleBar)
                  DecoratedBox(
                    decoration: const BoxDecoration(color: _bg, border: Border(bottom: BorderSide(color: _border))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          if (peer != null && !botPeerIsApp(peer))
                            TextButton.icon(
                              onPressed: _toggleStop,
                              icon: Icon(stopped ? Icons.play_arrow_rounded : Icons.stop_circle_outlined, size: 18, color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                              label: Text(stopped ? 'bots.resumeAi'.tr() : 'bots.stopAi'.tr(), style: TextStyle(color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 13)),
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
                          : SelectionArea(
                              onSelectionChanged: (c) => _selectedPlain = c?.plainText,
                              contextMenuBuilder: (ctx, state) => _messageContextMenu(ctx, state, msgs),
                              child: UiChatTimeline(
                                controller: _timeline,
                                itemCount: msgs.length,
                                itemBuilder: (context, i) => Listener(
                                  onPointerDown: (_) => _menuMsgIndex = i,
                                  child: KeyedSubtree(
                                    key: ValueKey(msgTileKey(msgs[i])),
                                    child: _msgTile(msgs[i], i: i, count: msgs.length),
                                  ),
                                ),
                              ),
                            ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: typingParty == null
                      ? const SizedBox.shrink()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(key: ValueKey(typingParty), child: _typingRow(typingParty)),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, uiSafeBottomInset(context, 12)),
                  child: InComposer(
                    key: ValueKey(widget.chatId),
                    compact: true,
                    controller: _composerCtrl,
                    focusNode: _composerFocus,
                    hint: isApp ? 'bots.messageHint'.tr() : 'bots.staffHint'.tr(),
                    model: AgentModel.alien,
                    models: const [AgentModel.alien],
                    onModel: (_) {},
                    enabled: peer != null,
                    busy: widget.store.composerBusy,
                    showSpeakIndicator: false,
                    onSend: (text, atts, {toolMode, mentionIds, displayContent}) => _sendFromComposer(text, atts),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class UiBotChatHeaderActions extends StatelessWidget {
  const UiBotChatHeaderActions({super.key, required this.store, required this.chatId});

  final BotStore store;
  final String chatId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final peer = store.peerById(chatId);
          if (peer == null || botPeerIsApp(peer)) return const SizedBox.shrink();
          final stopped = !peer.aiReplyEnabled;
          return TextButton.icon(
            onPressed: () => store.chatStopToggle(chatId),
            icon: Icon(stopped ? Icons.play_arrow_rounded : Icons.stop_circle_outlined, size: 18, color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            label: Text(stopped ? 'bots.resumeAi'.tr() : 'bots.stopAi'.tr(), style: TextStyle(color: stopped ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 13)),
          );
        },
      );
}
