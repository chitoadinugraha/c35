import 'dart:async';

import 'package:uuid/uuid.dart';

import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/pages/page_bots.dart';
import 'package:alienai_c35/pages/page_devices.dart';
import 'package:alienai_c35/pages/page_nav_stub.dart';
import 'package:alienai_c35/pages/page_settings.dart';
import 'package:alienai_c35/pages/referral/page_referral_tree.dart';
import 'package:alienai_c35/widgets/ai/in_composer.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/c/tags/ask_tags.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_error_badge.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_history_sidebar.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_hints.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ai/ui_user_bubble.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_history_sheet.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_package_sheet.dart';
import 'package:alienai_c35/widgets/chat/ui_chat_timeline.dart';
import 'package:alienai_c35/widgets/ui/ui_account_menu.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class PageAIHome extends StatefulWidget {
  const PageAIHome({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PageAIHome> createState() => _PageAIHomeState();
}

class _PageAIHomeState extends State<PageAIHome> {
  static const _bg = Color(0xFF08080A);
  static const _border = Color(0xFF27272A);
  static const _muted = Color(0xFF71717A);
  static const _text = Color(0xFFF4F4F5);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _store = ChatStore();
  final _conn = ChatConn();
  final _consumptionApi = ConsumptionApi();
  final _timeline = UiChatTimelineController();
  final _mentionIds = <String>{};
  var _toolMode = 'agent';
  var _model = AgentModel.alien;
  var _mentions = <CatalogMention>[];
  var _catalogReady = false;
  StreamSubscription? _syncSub;
  StreamSubscription? _billingBalanceSub;
  StreamSubscription? _billingQuotaSub;
  StreamSubscription? _billingCommissionSub;
  var _menuMsgIndex = 0;
  String? _selectedPlain;

  @override
  void initState() {
    super.initState();
    if (Session.instance.modelId.isNotEmpty) _model = AgentModel.of(Session.instance.modelId, _store.models);
    _timeline.attach();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _billingBalanceSub?.cancel();
    _billingQuotaSub?.cancel();
    _billingCommissionSub?.cancel();
    _timeline.dispose();
    _conn.disconnect();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      await CatalogTranslationCache.instance.restore();
      await CatalogTranslationCache.instance.ensure('en');
      _mentions = await catalogMentionsFetch();
    } catch (e) {
      lError('catalog load: $e');
    }
    await PromptUsagePrefs.instance.load();
    if (mounted) setState(() => _catalogReady = true);
    try {
      final locale = CatalogTranslationCache.instance.lang;
      await _conn.connect(locale: locale);
      await _store.refreshFromConn(_conn, locale: locale);
      if (mounted) _model = AgentModel.of(Session.instance.modelId, _store.models);
      _syncSub = _conn.onSyncPush.listen(_onSyncPush);
      _billingBalanceSub = _conn.onBillingBalance.listen(AppStore.instance.billingBalancePush);
      _billingQuotaSub = _conn.onBillingQuota.listen(AppStore.instance.billingQuotaPush);
      _billingCommissionSub = _conn.onBillingCommission.listen(AppStore.instance.billingCommissionPush);
    } catch (e) {
      lError('chat boot: $e');
    }
  }

  void _onConsumptionBlockSaved(int msgId, ChatBlock block) {
    final rows = _store.activeMsgs;
    final i = rows.indexWhere((m) => m.id == msgId);
    if (i < 0) return;
    final blocks = ChatBlock.decodeList(rows[i].blocksJson);
    final cid = block.body['consumption_id']?.toString() ?? '';
    final p = blocks.indexWhere((b) => b.kind == 'consumption.food' && (b.body['consumption_id']?.toString() ?? '') == cid);
    if (p >= 0) {
      blocks[p] = block;
    } else {
      blocks.add(block);
    }
    _store.msgUpdate(id: msgId, blocksJson: ChatBlock.encodeList(blocks));
  }

  void _onSyncPush(SyncPush push) {
    if (push.hasChatMember()) {
      final m = push.chatMember;
      ChatRow? chat;
      for (final c in _store.chats) {
        if (c.id == m.chatId.toInt()) {
          chat = c;
          break;
        }
      }
      if (chat != null) {
        _store.chatPutFromServer(
          Chat(id: Int64(chat.id), title: chat.title, tags: chat.tags),
          m,
        );
      }
    }
    if (push.hasChatMsg()) {
      final m = push.chatMsg;
      _store.msgPutFromServer(m);
      final cid = m.chatId.toInt();
      if (m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT && _store.promptBusyFor(cid) && m.content.trim().isNotEmpty) {
        _store.promptBusyPut(false, chatId: cid);
      }
    }
  }

  void _newChat() {
    _store.chatNew();
    _timeline.scrollToBottom(force: true);
    if (MediaQuery.sizeOf(context).width < 720) _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _selectChat(int id) async {
    _store.chatSelect(id);
    try {
      final res = await _conn.chatMsgList(chatId: Int64(id));
      for (final m in res.messages) {
        _store.msgPutFromServer(m);
      }
    } catch (_) {}
    _timeline.scrollToBottom(force: true);
    if (!mounted) return;
    if (MediaQuery.sizeOf(context).width < 720) _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _chatTag(int id, List<String> current) async {
    final next = await askTags(
      context,
      title: 'Tag chat',
      initial: current,
      hints: (prefix) async => (await _conn.assetTagList(kind: 'chat', prefix: prefix)).hints,
    );
    if (next == null) return;
    await _store.chatTagsRemote(_conn, id, next);
  }

  Future<void> _chatDelete(int id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete chat?', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
        content: Text('"$title" will be permanently deleted.', style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await _store.chatDeleteRemote(_conn, id);
  }

  void _chatMenu(int id, Offset global) {
    ChatRow? row;
    for (final c in _store.chats) {
      if (c.id == id) {
        row = c;
        break;
      }
    }
    if (row == null) return;
    final below = _store.chatBelowIds(id);
    showChatListMenu(
      context: context,
      global: global,
      items: [
        ChatMessageMenuAction(
          label: row.tags.isEmpty ? 'Tag' : 'Edit tags',
          icon: Icons.tag_rounded,
          onPressed: () => _chatTag(id, row!.tags),
        ),
        ChatMessageMenuAction(
          label: row.pinned ? 'Unpin' : 'Pin',
          icon: Icons.push_pin_outlined,
          onPressed: () => _store.chatPinRemote(_conn, id, pinned: !row!.pinned),
        ),
        ChatMessageMenuAction(
          label: row.archived ? 'Unarchive' : 'Archive',
          icon: Icons.archive_outlined,
          onPressed: () => _store.chatArchiveRemote(_conn, [id], archived: !row!.archived),
        ),
        if (below.isNotEmpty)
          ChatMessageMenuAction(
            label: 'Archive below',
            icon: Icons.archive_outlined,
            onPressed: () => _store.chatArchiveRemote(_conn, below, archived: true),
          ),
        const ChatMessageMenuDivider(),
        ChatMessageMenuAction(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          onPressed: () => _chatDelete(id, row!.title),
        ),
      ],
    );
  }

  void _openReferralTree() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageReferralTree(conn: ReferralConn(uid: Session.instance.uid), viewerId: Session.instance.uid),
        ),
      );

  void _openSettings() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageSettings(conn: SettingsConn()),
        ),
      );

  Future<void> _signOut() async {
    await _conn.disconnect();
    await widget.auth.signOut();
  }

  void _lockSession() => widget.auth.lockSession();

  void _openBots() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageBots(chatConn: _conn)));

  void _openDevices() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageDevices(chatConn: _conn)));

  void _openSites() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PageNavStub(title: 'Sites', icon: Icons.language_outlined)));

  void _avatarMenu(BuildContext anchorCtx) => uiAccountMenuShow(
        anchorCtx,
        action: UiAccountMenuAction(
          conn: ReferralConn(uid: Session.instance.uid),
          onSettings: _openSettings,
          onReferralTree: _openReferralTree,
          onBalance: () => billingHistorySheet(context, conn: ReferralConn(uid: Session.instance.uid)),
          onPackage: () => billingPackageSheet(context, conn: ReferralConn(uid: Session.instance.uid)),
          onLock: _lockSession,
          onSignOut: _signOut,
          onBots: _openBots,
          onDevices: _openDevices,
          onSites: _openSites,
          botsCount: _store.navCounts.bots,
          devicesCount: _store.navCounts.devices,
          sitesCount: _store.navCounts.sites,
        ),
      );

  void _mentionToggle(String id) => setState(() => _mentionIds.contains(id) ? _mentionIds.remove(id) : _mentionIds.add(id));

  void _toolModeToggle() => setState(() => _toolMode = _toolMode == 'ask' ? 'agent' : 'ask');

  void _modelPut(AgentModel m) {
    setState(() => _model = m);
    unawaited(Session.instance.modelPut(m.id));
  }

  Future<void> _hintPick(SpaceHint hint) => hintRun(hint: hint, onSend: _composerSend);

  Future<void> _composerSend(String text, List<MsgAttachment> attachments) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;
    if (_store.promptBusy) return;

    var chatId = _store.activeChatId;
    if (chatId == null) {
      _store.chatEnsurePending();
      chatId = _store.activeChatId;
    }
    if (chatId == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final reqId = const Uuid().v4();
    final userMsg = MsgRow(
      id: DateTime.now().microsecondsSinceEpoch,
      chatId: chatId,
      role: 'user',
      content: trimmed,
      attachments: attachments,
      attachmentsJson: MsgAttachment.encode(attachments),
      createdAtMs: now,
      reqId: reqId,
    );
    _store.msgPut(userMsg);
    _store.msgPut(MsgRow(
      id: _store.msgNextLocalId(),
      chatId: chatId,
      role: 'assistant',
      content: '',
      createdAtMs: now,
      reqId: reqId,
    ));
    _timeline.scrollToBottom(force: true);

    final localChatId = chatId;
    var streamChatId = chatId;
    final serverChatId = chatId > 0 ? Int64(chatId) : Int64.ZERO;
    final promptStream = _conn.promptSend(
        text: trimmed,
        chatId: serverChatId,
        attachmentsJson: MsgAttachment.encode(attachments),
        mentionIds: _mentionIds.toList(),
        model: _model.id,
        thinking: _model.thinking.wire,
        toolMode: _toolMode,
        locale: CatalogTranslationCache.instance.lang,
        reqId: reqId,
      );
    _store.promptBusyPut(true, chatId: chatId, reqId: reqId);
    _store.msgStreamStart(chatId: chatId, reqId: reqId, model: _model.id);
    final promptStartedAtMs = _store.promptStartedAtMs;
    try {
      await for (final ev in promptStream) {
        if (ev.kind == 'start') {
          if (ev.chatId != Int64.ZERO) {
            final startId = ev.chatId.toInt();
            streamChatId = startId;
            final title = trimmed.isNotEmpty ? chatTitleFromText(trimmed.split('\n').first) : 'New chat';
            if (startId != localChatId) _store.chatIdMigrate(localChatId, startId);
            _store.chatPutFromServer(
              Chat(id: ev.chatId, title: title),
              ChatMember(chatId: ev.chatId, lastMsgPreview: trimmed, lastMsgTsMs: Int64(now)),
            );
            _store.promptBusyPut(true, chatId: startId, reqId: _conn.lastPromptReqId);
            if (_store.activeChatId == localChatId || _store.activeChatId == null) _store.chatSelect(startId);
          }
          _store.msgStreamStart(chatId: streamChatId, reqId: _conn.lastPromptReqId ?? '', model: ev.model.isNotEmpty ? ev.model : _model.id);
          continue;
        }
        if (ev.kind == 'delta') {
          if (ev.thought) {
            _store.msgStreamThought(ev.text, chatId: streamChatId);
          } else if (ev.blocksJson.isNotEmpty) {
            _store.msgStreamBlocks(ev.blocksJson, chatId: streamChatId);
          } else {
            _store.msgStreamContent(ev.text, chatId: streamChatId);
          }
          if (_store.activeChatId == streamChatId) _timeline.scrollToBottom();
          continue;
        }
        if (ev.kind == 'end' && ev.end != null) {
          final end = ev.end!;
          _store.msgStreamEnd(
            chatId: streamChatId,
            msgId: end.msgId.toInt(),
            tokensIn: end.tokensIn,
            tokensOut: end.tokensOut,
            costUsd: end.costUsd,
            durationMs: end.durationMs,
            reqId: end.reqId,
            model: end.model,
            error: end.hasErrorMessage() ? end.errorMessage : '',
          );
          if (end.reqId.isNotEmpty) {
            unawaited(_conn.tracePrefetch(end.reqId).then((_) {
              if (mounted) setState(() {});
            }));
          }
          continue;
        }
        if (ev.kind == 'fail') {
          _store.msgStreamFail(msgErrorNormalize(ev.message), chatId: streamChatId, startedAtMs: promptStartedAtMs);
          continue;
        }
      }
    } catch (e) {
      _store.msgStreamFail(msgErrorNormalize(e), chatId: streamChatId, startedAtMs: promptStartedAtMs);
    } finally {
      _store.msgStreamFinalize(chatId: streamChatId, model: _model.id, startedAtMs: promptStartedAtMs);
      for (final cid in {streamChatId, localChatId}) {
        if (_store.promptBusyFor(cid)) _store.promptBusyPut(false, chatId: cid);
      }
      if (_store.activeChatId == streamChatId) _timeline.scrollToBottom(force: true);
    }
  }

  Future<void> _abortPrompt() async {
    final id = _store.promptChatId ?? _store.activeChatId;
    try {
      await _conn.promptAbort(chatId: id != null && id > 0 ? Int64(id) : Int64.ZERO);
    } catch (_) {}
    if (id != null) _store.promptBusyPut(false, chatId: id);
  }

  Widget _accountAvatar() => Builder(
        builder: (ctx) => UiAccountBtn(
          tooltip: 'Account',
          onTap: () => _avatarMenu(ctx),
          child: UiUserAvatar(name: Session.instance.name, email: Session.instance.email, handle: Session.instance.handle, pic: Session.instance.pic, size: 28),
        ),
      );

  Widget _historySidebar() => UiChatHistorySidebar(
        store: _store,
        onNewChat: _newChat,
        onChatSelect: _selectChat,
        onChatMenu: _chatMenu,
        onRefresh: () => _store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang),
      );

  String _activeChatTitle() {
    final id = _store.activeChatId;
    if (id == null) return '';
    for (final c in _store.chats) {
      if (c.id != id) continue;
      return chatTitleDisplay(c.title);
    }
    return '';
  }

  Widget _threadContextMenu(BuildContext ctx, SelectableRegionState state) {
    final messages = _store.activeMsgs;
    if (messages.isEmpty) return const SizedBox.shrink();
    final i = _menuMsgIndex.clamp(0, messages.length - 1);
    final m = messages[i];
    final isUser = m.role == 'user';
    final plain = _plainForMsg(m);
    final lastUserIdx = messages.lastIndexWhere((x) => x.role == 'user');
    final lastAssistantIdx = messages.lastIndexWhere((x) => x.role == 'assistant');
    final showRetry = !_store.promptBusyFor(m.chatId) && (i == lastUserIdx || i == lastAssistantIdx);
    return msgBubbleContextMenu(
      ctx,
      state,
      plainText: plain,
      selectedText: _selectedPlain,
      viewerIsRoot: sessionViewerIsRoot(),
      isAssistant: !isUser,
      reqId: m.reqId,
      msgId: m.id > 0 ? m.id : 0,
      showRetry: showRetry,
      onRetryLastTurn: showRetry ? _retryLastTurn : null,
      conn: _conn,
    );
  }

  Widget _chatHeader({required bool wide}) {
    final title = _activeChatTitle();
    final bar = SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (!wide) ...[
              uiIconButton(
                tooltip: 'Chats',
                icon: const Icon(Icons.menu_rounded, color: _muted),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              uiIconButton(
                tooltip: 'New chat',
                icon: const Icon(Icons.add_rounded, color: _text),
                onPressed: _newChat,
              ),
            ],
            Expanded(
              child: title.isEmpty
                  ? const SizedBox.shrink()
                  : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            _accountAvatar(),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(color: _bg, border: Border(bottom: BorderSide(color: _border))),
      child: wide ? bar : SafeArea(bottom: false, child: bar),
    );
  }

  Widget _chatColumn({required bool wide}) => Column(
        children: [
          _chatHeader(wide: wide),
          Expanded(child: _threadBody()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InComposer(
              model: _model,
              models: _store.models,
              onModel: _modelPut,
              mentions: _mentions,
              selectedMentionIds: _mentionIds,
              toolMode: _toolMode,
              onMentionToggle: _mentionToggle,
              onToolModeToggle: _toolModeToggle,
              onSend: _composerSend,
              onAbort: _store.promptBusyFor(_store.activeChatId) ? _abortPrompt : null,
              busy: _store.promptBusyFor(_store.activeChatId),
              enabled: _catalogReady,
            ),
          ),
        ],
      );

  Widget? _msgErrorBadge(MsgRow m) {
    final err = msgRowError(m).trim();
    if (!sessionViewerIsRoot() || err.isEmpty) return null;
    return UiMsgErrorBadge(error: err);
  }

  String _plainForMsg(MsgRow m) {
    final parts = <String>[];
    final content = msgDisplayContent(m).trim();
    if (content.isNotEmpty) parts.add(content);
    if (m.thought.trim().isNotEmpty) parts.add(msgThoughtStripPlaceholders(m.thought));
    return parts.join('\n\n');
  }

  Widget _msgTile(MsgRow m, {required int i, required int count}) {
    final isUser = m.role == 'user';
    final lastIdx = count - 1;
    final lastAssistantIdx = _store.activeMsgs.lastIndexWhere((x) => x.role == 'assistant');
    final promptingThis = _store.promptBusyFor(m.chatId) && i == lastIdx && !isUser;
    final usageStreaming = !isUser && msgUsageStreaming(busy: _store.promptBusyFor(m.chatId), i: i, lastAssistantIdx: lastAssistantIdx, lastIdx: lastIdx);
    final copyPrefix = msgCopyPrefix(role: m.role, userName: Session.instance.name, createdAtMs: m.createdAtMs);

    Widget body;
    if (isUser) {
      body = UiUserBubble(content: m.content, copyPrefix: copyPrefix, attachments: m.attachments);
    } else {
      final content = msgDisplayContent(m);
      final inThoughtPhase = promptingThis && content.trim().isEmpty;
      final thoughtView = msgThoughtView(thought: m.thought, content: content, thinking: inThoughtPhase);
      final blocks = ChatBlock.decodeList(m.blocksJson);
      final locale = CatalogTranslationCache.instance.lang;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiMsgCopyPrefix(text: copyPrefix),
          if (thoughtView.thought != null)
            UiMsgThought(
              text: thoughtView.thought!,
              thinking: inThoughtPhase,
              startedAtMs: promptingThis ? _store.promptStartedAtMs : null,
            ),
          if (content.trim().isNotEmpty)
            MarkdownBody(
              data: content,
              selectable: false,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: _text, fontSize: 15, height: 1.45),
                code: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Consolas', backgroundColor: Color(0xFF1A1A1D)),
              ),
            )
          else if (promptingThis && content.trim().isEmpty)
            const Text('…', style: TextStyle(color: _muted, fontSize: 15)),
          if (blocks.isNotEmpty)
            UiMsgBlocks(
              msgId: m.id,
              blocks: blocks,
              consumptionApi: _consumptionApi,
              locale: locale,
              onConsumptionSaved: _onConsumptionBlockSaved,
            ),
          if (m.reqId.isNotEmpty) UiMsgTraceLoader(conn: _conn, reqId: m.reqId),
          Builder(builder: (_) {
            final badge = _msgErrorBadge(m);
            final usageMsg = m.model.isNotEmpty || i != lastAssistantIdx
                ? m
                : m.copyWith(model: m.model.isNotEmpty ? m.model : _model.id);
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UiMsgUsage(
                  msg: usageMsg,
                  streaming: usageStreaming,
                  billingCurrency: AppStore.instance.wallet.billingCurrency,
                  fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
                ),
                if (badge != null) badge,
              ],
            );
          }),
        ],
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: isUser
            ? body
            : FractionallySizedBox(
                widthFactor: 0.8,
                alignment: Alignment.centerLeft,
                child: body,
              ),
      ),
    );
  }

  Future<void> _retryLastTurn() async {
    final msgs = _store.activeMsgs;
    if (msgs.isEmpty) return;
    MsgRow? lastUser;
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].role == 'user') {
        lastUser = msgs[i];
        break;
      }
    }
    if (lastUser == null) return;
    await _composerSend(lastUser.content, lastUser.attachments);
  }

  Widget _threadHero() {
    final hints = hintsOfflineFallback();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UiAlienIcon(size: 48, color: _text),
            const SizedBox(height: 16),
            const Text('What can I help with?', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_catalogReady ? 'Start a new chat or pick one from history.' : 'Loading catalog…', textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 14)),
            if (hints.isNotEmpty) ...[
              const SizedBox(height: 20),
              UiHints(hints: hints, onPick: _hintPick),
            ],
          ],
        ),
      ),
    );
  }

  Widget _threadBody() {
    final msgs = _store.activeMsgs;
    if (_store.activeChatId == null && msgs.isEmpty) return _threadHero();
    if (msgs.isEmpty) return _threadHero();
    return SelectionArea(
      onSelectionChanged: (c) => _selectedPlain = c?.plainText,
      contextMenuBuilder: _threadContextMenu,
      child: UiChatTimeline(
        controller: _timeline,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: msgs.length,
        itemBuilder: (context, i) => ListenableBuilder(
          listenable: _store,
          builder: (_, __) {
            final rows = _store.activeMsgs;
            if (i >= rows.length) return const SizedBox.shrink();
            return Listener(
              onPointerDown: (_) => _menuMsgIndex = i,
              child: _msgTile(rows[i], i: i, count: rows.length),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bg,
          drawer: wide ? null : Drawer(backgroundColor: _bg, child: SafeArea(child: _historySidebar())),
          body: wide
              ? SafeArea(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(border: Border(right: BorderSide(color: _border))),
                          child: _historySidebar(),
                        ),
                      ),
                      Expanded(child: _chatColumn(wide: true)),
                    ],
                  ),
                )
              : _chatColumn(wide: false),
        );
      },
    );
  }
}
