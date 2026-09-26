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
import 'package:alienai_c35/c/hint/hint_store.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:alienai_c35/c/consumption/consumption_api.dart';
import 'package:alienai_c35/c/expense/expense_api.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/location/location_permission.dart';
import 'package:alienai_c35/c/location/location_service.dart';
import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/settings/user_locale_prefs.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/store/prompt_followup_store.dart';
import 'package:alienai_c35/widgets/ai/prompt_followup_format.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:alienai_c35/pages/finance/page_finance_payments.dart';
import 'package:alienai_c35/pages/finance/page_finance_receive_accounts.dart';
import 'package:alienai_c35/pages/page_bots.dart';
import 'package:alienai_c35/pages/page_devices.dart';
import 'package:alienai_c35/pages/page_root_console.dart';
import 'package:alienai_c35/pages/page_sites.dart';
import 'package:alienai_c35/pages/page_settings.dart';
import 'package:alienai_c35/pages/referral/page_referral_tree.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_claim_dialog.dart';
import 'package:alienai_c35/widgets/settings/ui_location_consent_dialog.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_commission_sheet.dart';
import 'package:alienai_c35/widgets/ai/in_composer.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/c/tags/ask_tags.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_error.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_history_sidebar.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_hints.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ai/ui_subagent_run_card.dart';
import 'package:alienai_c35/widgets/ai/ui_user_bubble.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_history_sheet.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_package_sheet.dart';
import 'package:alienai_c35/widgets/chat/ui_chat_timeline.dart';
import 'package:alienai_c35/widgets/ui/ui_account_menu.dart';
import 'package:alienai_c35/widgets/ui/ui_conn_wifi.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:alienai_c35/widgets/ai/ui_canvas_panel.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_code_block.dart';
import 'package:alienai_c35/widgets/ai/ui_context_meter.dart';
import 'package:fixnum/fixnum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
  final _canvasStore = CanvasStore();
  final _composerCtrl = TextEditingController();
  final _composerFocus = FocusNode();
  final _conn = ChatConn();
  late final VoiceApi _voiceApi = VoiceApi(_conn);
  final _consumptionApi = ConsumptionApi();
  final _expenseApi = ExpenseApi();
  final _timeline = UiChatTimelineController();
  final _mentionIds = <String>{};
  var _toolMode = 'agent';
  var _model = AgentModel.alien;
  var _catalogReady = false;
  var _modelsReady = false;
  StreamSubscription? _syncSub;
  StreamSubscription? _billingBalanceSub;
  StreamSubscription? _billingQuotaSub;
  StreamSubscription? _billingCommissionSub;
  StreamSubscription? _reconnectedSub;
  StreamSubscription? _followupPushSub;
  StreamSubscription? _promptRunPushSub;
  var _menuMsgIndex = 0;
  var _retrying = false;
  var _hintRunning = false;
  String? _selectedPlain;
  String? _uiLang;

  @override
  void initState() {
    super.initState();
    SttService.instance.bindVoiceApi(_voiceApi);
    TtsService.instance.bindVoiceApi(_voiceApi);
    if (Session.instance.modelId.isNotEmpty) _model = AgentModel.of(Session.instance.modelId, _store.models);
    _timeline.attach();
    _reconnectedSub = _conn.onReconnected.listen((_) {
      unawaited(_store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang));
      if (mounted) setState(() {});
    });
    _followupPushSub = _conn.onPromptFollowupPush.listen((p) {
      PromptFollowupStore.instance.mergePush(p);
      if (mounted) setState(() {});
    });
    _promptRunPushSub = _conn.onPromptRunPush.listen((push) {
      if (push.parentReqId.isNotEmpty) return;
      final cid = _store.activeChatId;
      if (cid == null) return;
      if (push.status == 'queued' && !_store.promptBusyFor(cid)) {
        unawaited(_attachQueuedPromptRun(push.reqId, cid));
      }
    });
    PromptFollowupStore.instance.addListener(_onFollowupStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_boot());
      _checkReferralPrompt();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.locale.languageCode;
    if (_uiLang == lang) return;
    final prev = _uiLang;
    _uiLang = lang;
    if (prev != null) unawaited(_onUiLocaleChanged(lang));
  }

  Future<void> _onUiLocaleChanged(String lang) async {
    try {
      await CatalogTranslationCache.instance.ensure(lang, force: true);
      await _store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang);
    } catch (e) {
      lError('locale sync: $e');
    }
    if (mounted) setState(() {});
  }

  void _onFollowupStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _followupRefresh() async {
    final cid = _store.activeChatId;
    if (cid == null || cid <= 0) return;
    try {
      final res = await _conn.promptFollowupList(chatId: cid, reqId: _conn.lastPromptReqId ?? '');
      PromptFollowupStore.instance.merge(res);
    } catch (_) {}
  }

  Future<void> _followupSteer(PromptFollowupRow row) async {
    final cid = _store.activeChatId;
    if (cid == null) return;
    try {
      final res = await _conn.promptFollowupPut(
        chatId: cid,
        text: row.text,
        reqId: _conn.lastPromptReqId ?? '',
        kind: PromptFollowupKind.PROMPT_FOLLOWUP_KIND_STEER,
      );
      if (res.rejected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(promptFollowupRejectLabel(res.rejectReason, localeCode: context.locale.languageCode))),
        );
      } else if (!res.rejected) {
        await _conn.promptFollowupCancel(id: row.id);
      }
      await _followupRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _followupRemove(PromptFollowupRow row) async {
    try {
      await _conn.promptFollowupCancel(id: row.id);
      await _followupRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _attachQueuedPromptRun(String reqId, int chatId) async {
    if (_store.promptBusyFor(chatId)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _store.promptBusyPut(true, chatId: chatId, reqId: reqId);
    _store.msgPut(MsgRow(
      id: _store.msgNextLocalId(),
      chatId: chatId,
      role: 'assistant',
      content: '',
      createdAtMs: now + 1,
      reqId: reqId,
    ));
    _store.msgStreamStart(chatId: chatId, reqId: reqId, model: _model.id);
    final startedAt = _store.promptStartedAtMs;
    try {
      await for (final ev in _conn.promptAttach(reqId: reqId)) {
        if (ev.kind == 'delta') {
          if (ev.thought) {
            _store.msgStreamThought(ev.text, chatId: chatId);
          } else if (ev.blocksJson.isNotEmpty) {
            _store.msgStreamBlocks(ev.blocksJson, chatId: chatId);
          } else {
            _store.msgStreamContent(ev.text, chatId: chatId);
          }
          continue;
        }
        if (ev.kind == 'end' && ev.end != null) {
          final end = ev.end!;
          _store.msgStreamEnd(
            chatId: chatId,
            msgId: end.msgId.toInt(),
            tokensIn: end.tokensIn,
            tokensOut: end.tokensOut,
            costUsd: end.costUsd,
            durationMs: end.durationMs,
            reqId: end.reqId,
            model: end.model,
            error: end.hasErrorMessage() ? end.errorMessage : '',
          );
          continue;
        }
        if (ev.kind == 'fail') {
          _store.msgStreamFail(msgErrorNormalize(ev.message), chatId: chatId, startedAtMs: startedAt);
        }
      }
    } catch (e) {
      _store.msgStreamFail(msgErrorNormalize(e), chatId: chatId, startedAtMs: startedAt);
    } finally {
      _store.msgStreamFinalize(chatId: chatId, model: _model.id, startedAtMs: startedAt);
      if (_store.promptBusyFor(chatId)) _store.promptBusyPut(false, chatId: chatId);
      PromptFollowupStore.instance.clear();
      if (mounted) setState(() {});
    }
  }

  void _checkReferralPrompt() {
    if (!mounted) return;
    if (Session.instance.needsReferralPrompt) {
      UiReferralClaimDialog.show(context, auth: widget.auth);
    }
  }

  @override
  void dispose() {
    SttService.instance.bindVoiceApi(null);
    TtsService.instance.bindVoiceApi(null);
    _syncSub?.cancel();
    _billingBalanceSub?.cancel();
    _billingQuotaSub?.cancel();
    _billingCommissionSub?.cancel();
    _reconnectedSub?.cancel();
    _followupPushSub?.cancel();
    _promptRunPushSub?.cancel();
    PromptFollowupStore.instance.removeListener(_onFollowupStoreChanged);
    _timeline.dispose();
    _conn.disconnect();
    _canvasStore.dispose();
    _composerCtrl.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    if (!mounted) return;
    _uiLang = context.locale.languageCode;
    try {
      await HintStore.instance.restore();
      await CatalogTranslationCache.instance.restore();
      await CatalogTranslationCache.instance.ensure(_uiLang!);
    } catch (e) {
      lError('catalog load: $e');
    }
    await PromptUsagePrefs.instance.load();
    if (mounted) setState(() => _catalogReady = true);
    try {
      final locale = CatalogTranslationCache.instance.lang;
      final localePrefs = UserLocalePrefs.instance;
      await _conn.connect(locale: locale, tz: localePrefs.tz.isNotEmpty ? localePrefs.tz : UserLocalePrefs.deviceTimezoneDetect());
      await _store.refreshFromConn(_conn, locale: locale);
      if (_store.mentionCatalog.mentions.isEmpty) {
        try {
          await _store.mentionCatalog.refresh(_conn);
        } catch (e) {
          lError('mention list: $e');
        }
      }
      if (mounted) _model = AgentModel.of(Session.instance.modelId, _store.models);
      _syncSub = _conn.onSyncPush.listen(_onSyncPush);
      _billingBalanceSub = _conn.onBillingBalance.listen(AppStore.instance.billingBalancePush);
      _billingQuotaSub = _conn.onBillingQuota.listen(AppStore.instance.billingQuotaPush);
      _billingCommissionSub = _conn.onBillingCommission.listen(AppStore.instance.billingCommissionPush);
    } catch (e) {
      lError('chat boot: $e');
    } finally {
      if (mounted) setState(() => _modelsReady = true);
    }
    if (mounted) unawaited(_checkLocationConsent());
  }

  Future<void> _checkLocationConsent() async {
    if (!mounted) return;
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) return;
    await UserLocationPrefs.instance.load();
    if (!mounted) return;
    if (UserLocationPrefs.instance.asked) return;
    if (UserLocalePrefs.instance.locationCity.isNotEmpty) return;
    final continueFlow = await UiLocationConsentDialog.show(context);
    await UserLocationPrefs.instance.put(asked: true);
    if (continueFlow != true) return;
    final granted = await locationPermissionEnsure();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.locationDeniedSnack'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final loc = await locationServiceResolve();
    if (loc == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.locationDeniedSnack'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    await UserLocationPrefs.instance.put(useDevice: true, locationSource: 'device');
    await UserLocalePrefs.instance.put(
      locationCity: loc.city,
      locationRegion: loc.region,
      locationCountry: loc.country,
      locationSource: 'device',
    );
    try {
      await _store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang);
    } catch (_) {}
    if (mounted) setState(() {});
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

  void _onExpenseBlockSaved(int msgId, ChatBlock block) {
    final rows = _store.activeMsgs;
    final i = rows.indexWhere((m) => m.id == msgId);
    if (i < 0) return;
    final blocks = ChatBlock.decodeList(rows[i].blocksJson);
    final txId = block.body['tx_id']?.toString() ?? '';
    final p = blocks.indexWhere((b) => b.kind == 'expense.receipt' && (b.body['tx_id']?.toString() ?? '') == txId);
    if (p >= 0) {
      blocks[p] = block;
    } else {
      blocks.add(block);
    }
    _store.msgUpdate(id: msgId, blocksJson: ChatBlock.encodeList(blocks));
  }

  void _onSyncPush(SyncPush push) {
    if (push.hasChat()) {
      final c = push.chat;
      if (c.id.toInt() > 0 && c.title.trim().isNotEmpty) {
        _store.chatTitlePut(c.id.toInt(), c.title);
      }
    }
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
      if (m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT) {
        if (_store.promptBusyFor(cid) && m.content.trim().isNotEmpty) {
          _store.promptBusyPut(false, chatId: cid);
        } else {
          _store.chatStatusStaleClear(chatId: cid);
        }
      }
    }
  }

  void _composerReset() {
    _composerCtrl.clear();
    _composerFocus.unfocus();
  }

  void _newChat() {
    _store.chatNew();
    _composerReset();
    _canvasStore.close();
    _timeline.scrollToBottom(force: true);
    if (MediaQuery.sizeOf(context).width < 720) _scaffoldKey.currentState?.closeDrawer();
  }

  void _onCanvasIterate(CanvasArtifact artifact) {
    if (MediaQuery.sizeOf(context).width < 720 && (_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
      Navigator.of(context).pop();
    }
    final snippet = artifact.title.isNotEmpty ? artifact.title : 'Canvas document';
    _composerCtrl.text = 'Regarding "$snippet":\n';
    _composerCtrl.selection = TextSelection.collapsed(offset: _composerCtrl.text.length);
    _composerFocus.requestFocus();
  }

  void _onCanvasExport(CanvasArtifact artifact, String prompt) {
    if (MediaQuery.sizeOf(context).width < 720 && (_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
      Navigator.of(context).pop();
    }
    _composerCtrl.text = prompt;
    _composerCtrl.selection = TextSelection.collapsed(offset: _composerCtrl.text.length);
    _composerFocus.requestFocus();
  }

  Future<void> _selectChat(int id) async {
    _store.chatSelect(id);
    _composerReset();
    _canvasStore.close();
    try {
      final res = await _conn.chatMsgList(chatId: Int64(id));
      _store.msgsReloadFromServer(id, res.messages);
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

  Future<void> _chatClear(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Clear messages?', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16)),
        content: const Text('All messages in this chat will be cleared.', style: TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;
    _store.chatClearMsgs(id);
    _timeline.scrollToBottom(force: true);
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
        ChatMessageMenuAction(
          label: 'Clear messages',
          icon: Icons.cleaning_services_outlined,
          onPressed: () => _chatClear(id),
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
          builder: (_) => PageSettings(conn: SettingsConn(), chatConn: _conn, chatStore: _store, auth: widget.auth),
        ),
      );

  Future<void> _signOut() async {
    await _conn.disconnect();
    await widget.auth.signOut();
  }

  void _lockSession() => widget.auth.lockSession();

  void _openBots() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageBots(chatConn: _conn)));

  void _openDevices() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageDevices(chatConn: _conn)));

  void _openSites() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageSites(chatConn: _conn)));

  void _openRootConsole() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootConsole(chatConn: _conn)));

  bool get _financeRole => Session.instance.isRoot || Session.instance.globalRoles.contains('finance');

  bool get _receiveAccountRole => Session.instance.isRoot || Session.instance.globalRoles.any((r) => r == 'finance' || r == 'director');

  void _openFinancePayments() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageFinancePayments(conn: ReferralConn(uid: Session.instance.uid), canReview: _financeRole),
        ),
      );

  void _openFinanceReceiveAccounts() => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => PageFinanceReceiveAccounts(conn: ReferralConn(uid: Session.instance.uid))),
      );

  void _openCommissionSheet() => referralCommissionSheet(context, conn: ReferralConn(uid: Session.instance.uid));

  void _avatarMenu(BuildContext anchorCtx) => uiAccountMenuShow(
        anchorCtx,
        action: UiAccountMenuAction(
          conn: ReferralConn(uid: Session.instance.uid),
          onSettings: _openSettings,
          onReferralTree: _openReferralTree,
          onBalance: () => billingHistorySheet(context, conn: ReferralConn(uid: Session.instance.uid)),
          onPackage: () => billingPackageSheet(context, conn: ReferralConn(uid: Session.instance.uid)),
          onCommissionTap: _openCommissionSheet,
          onFinancePayments: _financeRole ? _openFinancePayments : null,
          onFinanceReceiveAccounts: _receiveAccountRole ? _openFinanceReceiveAccounts : null,
          onLock: _lockSession,
          onSignOut: _signOut,
          onBots: _openBots,
          onDevices: _openDevices,
          onSites: _openSites,
          onRootConsole: Session.instance.isRoot ? _openRootConsole : null,
          botsCount: _store.navCounts.bots,
          devicesCount: _store.navCounts.devices,
          sitesCount: _store.navCounts.sites,
        ),
      );

  void _mentionToggle(String id) => setState(() => _mentionIds.contains(id) ? _mentionIds.remove(id) : _mentionIds.add(id));

  Future<List<CatalogMention>> _mentionSearch(String q) => _store.mentionCatalog.search(_conn, q: q);

  void _toolModeToggle() => setState(() => _toolMode = _toolMode == 'ask' ? 'agent' : 'ask');

  void _modelPut(AgentModel m) {
    setState(() => _model = m);
    unawaited(Session.instance.modelPut(m.id));
  }

  Future<void> _hintPick(HintItem hint) async {
    if (_store.promptBusy || _hintRunning) return;
    _hintRunning = true;
    try {
      final assetIid = hintTouchAssetIid(hint);
      if (assetIid != null) {
        unawaited(_store.hintTouch(_conn, assetIid: assetIid, assetKind: hintTouchAssetKind(hint)));
      }
      await hintActionRunFromProto(
        item: hint,
        onSend: _composerSend,
        onNavigate: _hintNavigate,
        context: context,
      );
      if (mounted) _composerReset();
    } finally {
      _hintRunning = false;
    }
  }

  Future<void> _hintNavigate(String route, Map<String, dynamic> payload) async {
    if (route != 'site.pos' || !mounted) return;
    final siteIid = '${payload['site_iid'] ?? ''}'.trim();
    if (siteIid.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PageSites(chatConn: _conn, initialSiteIid: siteIid, initialTabRoute: route),
      ),
    );
  }

  Future<void> _imageUpgradeHd(ChatBlock block) async {
    final prompt = block.body['prompt']?.toString().trim() ?? '';
    if (prompt.isEmpty || ChatBlock.imageIsHd(block)) return;
    if (_store.promptBusy) return;
    final locale = CatalogTranslationCache.instance.lang;
    final lead = locale.startsWith('id')
        ? 'Buat ulang gambar ini dalam kualitas HD (2K), detail lebih tajam.'
        : 'Regenerate this image in HD (2K) with sharper detail.';
    await _composerSend('$lead\n\n$prompt', const [], mentionIds: const ['image_high']);
  }

  Future<void> _composerSend(String text, List<MsgAttachment> attachments, {bool retry = false, String? toolMode, List<String>? mentionIds}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;
    if (_store.promptBusy && !retry) {
      final cid = _store.activeChatId;
      if (cid == null) return;
      try {
        final res = await _conn.promptFollowupPut(
          chatId: cid,
          text: trimmed,
          reqId: _conn.lastPromptReqId ?? '',
          attachmentsJson: MsgAttachment.encode(attachments),
        );
        if (res.rejected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(promptFollowupRejectLabel(res.rejectReason, localeCode: context.locale.languageCode))),
          );
        } else {
          _composerReset();
          await _followupRefresh();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    unawaited(TtsService.instance.stop());

    var chatId = _store.activeChatId;
    if (chatId == null) {
      _store.chatEnsurePending();
      chatId = _store.activeChatId;
    }
    if (chatId == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final reqId = const Uuid().v4();
    final replaceFailedTurn = !retry && _store.msgCanReplaceFailedTurn(chatId);
    if (replaceFailedTurn) _store.msgReplaceFailedTurnPrep(chatId);
    if (retry || replaceFailedTurn) {
      _store.msgUserTurnRetry(
        chatId: chatId,
        content: trimmed,
        attachments: attachments,
        reqId: reqId,
        createdAtMs: now,
      );
    } else {
      final userMsg = MsgRow(
        id: _store.msgNextLocalId(),
        chatId: chatId,
        role: 'user',
        content: trimmed,
        attachments: attachments,
        attachmentsJson: MsgAttachment.encode(attachments),
        createdAtMs: now,
        reqId: reqId,
      );
      _store.msgPut(userMsg);
    }
    _store.msgPut(MsgRow(
      id: _store.msgNextLocalId(),
      chatId: chatId,
      role: 'assistant',
      content: '',
      createdAtMs: now + 1,
      reqId: reqId,
    ));
    _timeline.scrollToBottom(force: true);

    final localChatId = chatId;
    var streamChatId = chatId;
    final serverChatId = chatId > 0 ? Int64(chatId) : Int64.ZERO;
    final turnToolMode = toolMode ?? _toolMode;
    final promptStream = _conn.promptSend(
        text: trimmed,
        chatId: serverChatId,
        attachmentsJson: MsgAttachment.encode(attachments),
        mentionIds: mentionIds ?? _mentionIds.toList(),
        model: _model.id,
        thinking: _model.thinking.wire,
        toolMode: turnToolMode,
        locale: CatalogTranslationCache.instance.lang,
        reqId: reqId,
      );
    _store.promptBusyPut(true, chatId: chatId, reqId: reqId);
    unawaited(_followupRefresh());
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
            final rid = _conn.lastPromptReqId ?? '';
            if (rid.isNotEmpty && ev.text.contains('Using ')) {
              unawaited(_conn.tracePrefetch(rid, force: true));
            }
          } else if (ev.blocksJson.isNotEmpty) {
            _store.msgStreamBlocks(ev.blocksJson, chatId: streamChatId);
          } else {
            _store.msgStreamContent(ev.text, chatId: streamChatId);
          }
          if (_store.activeChatId == streamChatId) {
            if (_timeline.stickToBottom) {
              _timeline.scrollToBottom();
            } else {
              _timeline.notifyStreamChunk();
            }
          }
          continue;
        }
        if (ev.kind == 'end' && ev.end != null) {
          final end = ev.end!;
          final err = end.hasErrorMessage() ? end.errorMessage : '';
          _store.msgStreamEnd(
            chatId: streamChatId,
            msgId: end.msgId.toInt(),
            tokensIn: end.tokensIn,
            tokensOut: end.tokensOut,
            costUsd: end.costUsd,
            durationMs: end.durationMs,
            reqId: end.reqId,
            model: end.model,
            error: err,
          );
          if (VoicePrefs.instance.speakEnabled && err.trim().isEmpty) {
            final rid = end.reqId.isNotEmpty ? end.reqId : (_conn.lastPromptReqId ?? '');
            MsgRow? spoken;
            for (final row in _store.activeMsgs.reversed) {
              if (row.role == 'assistant' && (rid.isEmpty || row.reqId == rid)) {
                spoken = row;
                break;
              }
            }
            final assistantText = spoken != null ? msgDisplayContent(spoken).trim() : '';
            if (assistantText.isNotEmpty) unawaited(_speak(assistantText));
          }
          if (end.reqId.isNotEmpty) {
            unawaited(_conn.tracePrefetch(end.reqId, force: true).then((_) {
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
      PromptFollowupStore.instance.clear();
      if (_store.activeChatId == streamChatId) _timeline.scrollToBottom(force: true);
    }
  }

  Future<void> _speak(String text) async {
    await TtsService.instance.speak(text);
    final err = TtsService.instance.lastSpeakError;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _abortPrompt() async {
    final id = _store.promptChatId ?? _store.activeChatId;
    final reqId = _store.pendingPromptReqId ?? '';
    try {
      await _conn.promptAbort(
        chatId: id != null && id > 0 ? Int64(id) : Int64.ZERO,
        reqId: reqId,
      );
    } catch (_) {}
    if (id != null) _store.promptBusyPut(false, chatId: id);
  }

  Future<void> _abortChildRun(int chatId, String reqId) async {
    if (reqId.trim().isEmpty) return;
    try {
      await _conn.promptAbort(
        chatId: chatId > 0 ? Int64(chatId) : Int64.ZERO,
        reqId: reqId,
      );
    } catch (e) {
      lError('subagent abort: $e');
    }
  }

  Widget _subagentRunCards(MsgRow m) {
    final parentReqId = m.reqId.trim();
    if (parentReqId.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: PromptRunStore.instance,
      builder: (_, __) {
        final children = PromptRunStore.instance.childrenFor(parentReqId);
        if (children.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children)
              UiSubagentRunCard(
                conn: _conn,
                push: child,
                chatId: m.chatId,
                onStop: promptRunStatusLive(child.status) ? () => unawaited(_abortChildRun(m.chatId, child.reqId)) : null,
              ),
          ],
        );
      },
    );
  }

  Widget _accountAvatar() => Builder(
        builder: (ctx) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiConnWifi(conn: _conn),
            UiAccountBtn(
              tooltip: 'Account',
              onTap: () => _avatarMenu(ctx),
              child: UiUserAvatar(name: Session.instance.name, email: Session.instance.email, handle: Session.instance.handle, pic: Session.instance.pic, size: 28),
            ),
          ],
        ),
      );

  Widget _historySidebar() => UiChatHistorySidebar(
        store: _store,
        onNewChat: _newChat,
        onChatSelect: _selectChat,
        onChatMenu: _chatMenu,
        onRefresh: () => _store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang),
      );

  ChatRow? get _activeChat {
    final id = _store.activeChatId;
    if (id == null) return null;
    for (final c in _store.chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  String _activeChatTitle() {
    final chat = _activeChat;
    if (chat == null) return '';
    return chatTitleDisplay(chat.title);
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
    final imageBlock = !isUser ? ChatBlock.imageFirst(m.blocksJson) : null;
    final showImageUpgrade = imageBlock != null && !ChatBlock.imageIsHd(imageBlock) && !_store.promptBusyFor(m.chatId);
    return msgBubbleContextMenu(
      ctx,
      state,
      plainText: plain,
      selectedText: _selectedPlain,
      viewerIsRoot: sessionViewerIsRoot(),
      isAssistant: !isUser,
      reqId: m.reqId,
      msgId: m.id > 0 ? m.id : 0,
      onSpeak: !isUser && plain.isNotEmpty
          ? () {
              ContextMenuController.removeAny();
              unawaited(_speak(plain));
            }
          : null,
      showRetry: showRetry,
      onRetryLastTurn: showRetry ? _retryLastTurn : null,
      onImageUpgradeHd: showImageUpgrade
          ? () {
              final b = ChatBlock.imageFirst(m.blocksJson);
              if (b != null) unawaited(_imageUpgradeHd(b));
            }
          : null,
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
                color: _muted,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              uiIconButton(
                tooltip: 'New chat',
                color: _muted,
                icon: const Icon(Icons.add_rounded),
                onPressed: _newChat,
              ),
            ],
            Expanded(
              child: title.isEmpty
                  ? const SizedBox.shrink()
                  : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (_canvasStore.hasArtifact) ...[
              uiIconButton(
                tooltip: _canvasStore.isOpen ? 'Hide canvas' : 'Open canvas',
                icon: Icon(
                  Icons.view_sidebar_rounded,
                  color: _canvasStore.isOpen ? const Color(0xFF06B6D4) : _muted,
                ),
                onPressed: () {
                  if (wide) {
                    _canvasStore.toggleOpen();
                  } else {
                    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    } else {
                      _scaffoldKey.currentState?.openEndDrawer();
                    }
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            if ((Session.instance.isRoot || Session.instance.isTester) && _activeChat?.contextSummaryPresent == true)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: uiTooltip(
                  message: 'Earlier messages summarized for context',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3F3F46)),
                    ),
                    child: const Text('Summarized', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
                  ),
                ),
              ),
            if (Session.instance.isRoot || Session.instance.isTester)
              ListenableBuilder(
                listenable: PromptUsagePrefs.instance,
                builder: (context, _) => PromptUsagePrefs.instance.showUsageStats
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: UiContextMeter(
                          tokensIn: _threadTokensIn,
                          tokensOut: _threadTokensOut,
                          costUsd: _threadCostUsd,
                          contextLimit: _model.gemini ? 1000000 : 128000,
                          billingCurrency: AppStore.instance.wallet.billingCurrency,
                          fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
                        ),
                      )
                    : const SizedBox.shrink(),
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

  int get _threadTokensIn => _store.activeMsgs.fold(0, (acc, m) => acc + m.tokensIn);
  int get _threadTokensOut => _store.activeMsgs.fold(0, (acc, m) => acc + m.tokensOut);
  double get _threadCostUsd => _store.activeMsgs.fold(0.0, (acc, m) => acc + m.costUsd);

  Widget _chatColumn({required bool wide}) => Column(
        children: [
          _chatHeader(wide: wide),
          Expanded(child: _threadBody()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: InComposer(
              key: ValueKey(_store.activeChatId ?? 'new'),
              controller: _composerCtrl,
              focusNode: _composerFocus,
              model: _model,
              models: _store.models,
              modelsLoading: !_modelsReady,
              onModel: _modelPut,
              mentions: _store.mentionCatalog.mentions,
              selectedMentionIds: _mentionIds,
              toolMode: _toolMode,
              onMentionToggle: _mentionToggle,
              onMentionSearch: _mentionSearch,
              onToolModeToggle: _toolModeToggle,
              promptHistory: _store.recentUserPrompts,
              onNewChat: _newChat,
              onSend: (text, atts, {toolMode}) => _composerSend(text, atts, toolMode: toolMode),
              onAbort: _store.promptBusyFor(_store.activeChatId) ? _abortPrompt : null,
              busy: _store.promptBusyFor(_store.activeChatId),
              followupRows: promptFollowupQueueRows(PromptFollowupStore.instance.items),
              onFollowupSteer: _followupSteer,
              onFollowupRemove: _followupRemove,
              enabled: _catalogReady,
            ),
          ),
        ],
      );

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
      final err = msgRowError(m).trim();
      final hasError = err.isNotEmpty;
      final inThoughtPhase = promptingThis && content.trim().isEmpty && !hasError;
      final thoughtView = msgThoughtView(thought: m.thought, content: content, thinking: inThoughtPhase);
      final blocks = ChatBlock.decodeList(m.blocksJson);
      final locale = CatalogTranslationCache.instance.lang;
      final showRetry = hasError && !_store.promptBusyFor(m.chatId) && i == lastAssistantIdx;
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
          if (m.reqId.isNotEmpty)
            UiMsgTraceLoader(
              conn: _conn,
              reqId: m.reqId,
              live: promptingThis,
              part: MsgTracePart.chips,
            ),
          _subagentRunCards(m),
          if (hasError)
            UiMsgError(
              message: msgPromptErrorMessage(err),
              detail: sessionViewerIsRoot() ? err : null,
              messageId: m.reqId,
              onRetry: showRetry ? _retryLastTurn : null,
              retrying: _retrying,
            )
          else if (content.trim().isNotEmpty)
            MarkdownBody(
              data: content,
              selectable: false,
              builders: {
                'code': UiMarkdownCodeBlockBuilder(
                  onOpenInCanvas: (title, code, language) {
                    _canvasStore.openCode(
                      title: title,
                      code: code,
                      language: language,
                      open: true,
                    );
                    if (MediaQuery.sizeOf(context).width < 720) {
                      _scaffoldKey.currentState?.openEndDrawer();
                    }
                  },
                ),
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: _text, fontSize: 15, height: 1.45),
                code: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Consolas', backgroundColor: Color(0xFF1A1A1D)),
              ),
            ),
          if (!hasError && blocks.isNotEmpty)
            UiMsgBlocks(
              msgId: m.id,
              blocks: blocks,
              consumptionApi: _consumptionApi,
              expenseApi: _expenseApi,
              locale: locale,
              primary: content.trim().isEmpty && !hasError,
              onConsumptionSaved: _onConsumptionBlockSaved,
              onExpenseSaved: _onExpenseBlockSaved,
              onBlockCollapsedChanged: (msgId, blockIndex, collapsed) =>
                  _store.msgBlockCollapsedPut(msgId: msgId, blockIndex: blockIndex, collapsed: collapsed),
              onImageUpgradeHd: _store.promptBusyFor(m.chatId) ? null : _imageUpgradeHd,
            ),
          if (!hasError && m.reqId.isNotEmpty)
            UiMsgTraceLoader(
              conn: _conn,
              reqId: m.reqId,
              live: promptingThis,
              part: MsgTracePart.citations,
            ),
          if (!hasError)
            Builder(builder: (_) {
              final usageMsg = m.model.isNotEmpty || i != lastAssistantIdx
                  ? m
                  : m.copyWith(model: m.model.isNotEmpty ? m.model : _model.id);
              return UiMsgUsage(
                msg: usageMsg,
                streaming: usageStreaming,
                billingCurrency: AppStore.instance.wallet.billingCurrency,
                fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
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
    if (_retrying) return;
    final turn = _store.retryLastTurnPrep();
    if (turn == null) return;
    setState(() => _retrying = true);
    try {
      await _composerSend(turn.text, turn.attachments, retry: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Widget _threadHero() => ListenableBuilder(
        listenable: HintStore.instance,
        builder: (context, _) {
          final hints = HintStore.instance.items.isNotEmpty ? HintStore.instance.items : hintsOfflineFallbackItems();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UiAlienIcon(size: 48, color: _text),
                  const SizedBox(height: 16),
                  Text('home.heroTitle'.tr(), style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_catalogReady ? 'home.heroSubtitle'.tr() : 'home.heroLoading'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 14)),
                  if (hints.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    UiHints(hints: hints, onPick: _hintPick),
                  ],
                ],
              ),
            ),
          );
        },
      );

  Widget _jumpToLatestPill(int unread) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _timeline.scrollToBottom(force: true, animate: true),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF18181C).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3F3F46)),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF06B6D4)),
                const SizedBox(width: 6),
                Text(
                  unread > 0 ? '$unread new message${unread > 1 ? 's' : ''}' : 'Jump to latest',
                  style: const TextStyle(
                    color: Color(0xFFF4F4F5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _threadBody() {
    final msgs = _store.activeMsgs;
    if (_store.activeChatId == null && msgs.isEmpty) return _threadHero();
    if (msgs.isEmpty) return _threadHero();
    return Stack(
      children: [
        Positioned.fill(
          child: SelectionArea(
            onSelectionChanged: (c) => _selectedPlain = c?.plainText,
            contextMenuBuilder: _threadContextMenu,
            child: UiChatTimeline(
              key: ValueKey(_store.activeChatId ?? 'hero'),
              controller: _timeline,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: msgs.length,
              itemBuilder: (context, i) => ListenableBuilder(
                listenable: _store,
                builder: (_, __) {
                  final rows = _store.activeMsgs;
                  if (i >= rows.length) return const SizedBox.shrink();
                  final m = rows[i];
                  return Listener(
                    onPointerDown: (_) => _menuMsgIndex = i,
                    child: KeyedSubtree(
                      key: ValueKey('${m.chatId}:${m.id}:${m.reqId}:${m.role}'),
                      child: _msgTile(m, i: i, count: rows.length),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 20,
          child: ListenableBuilder(
            listenable: Listenable.merge([_timeline.isAtBottom, _timeline.unreadStreamCount]),
            builder: (ctx, _) {
              if (_timeline.isAtBottom.value) return const SizedBox.shrink();
              return _jumpToLatestPill(_timeline.unreadStreamCount.value);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _canvasStore]),
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bg,
          drawer: wide ? null : Drawer(backgroundColor: _bg, child: SafeArea(child: _historySidebar())),
          endDrawer: wide || !_canvasStore.hasArtifact
              ? null
              : Drawer(
                  backgroundColor: _bg,
                  child: SafeArea(
                    child: UiCanvasPanel(
                      store: _canvasStore,
                      onPromptIterate: _onCanvasIterate,
                      onPromptExport: _onCanvasExport,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
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
                      if (_canvasStore.isOpen && _canvasStore.hasArtifact)
                        SizedBox(
                          width: 480,
                          child: UiCanvasPanel(
                            store: _canvasStore,
                            onPromptIterate: _onCanvasIterate,
                            onPromptExport: _onCanvasExport,
                          ),
                        ),
                    ],
                  ),
                )
              : _chatColumn(wide: false),
        );
      },
    );
  }
}
