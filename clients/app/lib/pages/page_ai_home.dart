import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/composer_draft_store.dart';
import 'package:alienai_c35/c/conn/server_host.dart';
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
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/mail/mail_inbox_bus.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/share/share_inbound_listen.dart';
import 'package:alienai_c35/c/share/share_inbound_payload.dart';
import 'package:alienai_c35/c/share/share_inbound_present.dart';
import 'package:alienai_c35/c/share/share_inbound_staged.dart';
import 'package:alienai_c35/c/share/share_to_home_bridge.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/settings/ai_disclaimer_prefs.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/location/location_permission.dart';
import 'package:alienai_c35/c/location/location_service.dart';
import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/settings/user_locale_prefs.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/mention/composer_test_commands.dart';
import 'package:alienai_c35/core/notify/fcm_service.dart';
import 'package:alienai_c35/core/notify/notify_router.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/c/update/app_update_busy.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/store/prompt_followup_store.dart';
import 'package:alienai_c35/widgets/ai/prompt_followup_format.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/c/voice/voice_api.dart';
import 'package:alienai_c35/pages/finance/page_finance_payments.dart';
import 'package:alienai_c35/pages/finance/page_finance_receive_accounts.dart';
import 'package:alienai_c35/pages/page_bots.dart';
import 'package:alienai_c35/pages/devices_module_loader.dart';
import 'package:alienai_c35/pages/live_call_module_loader.dart';
import 'package:alienai_c35/pages/page_root_console.dart';
import 'package:alienai_c35/pages/page_site_pos.dart';
import 'package:alienai_c35/pages/page_sites.dart';
import 'package:alienai_c35/pages/mail/mail_module_loader.dart';
import 'package:alienai_c35/pages/notify/page_notify_history.dart';
import 'package:alienai_c35/pages/page_settings.dart';
import 'package:alienai_c35/pages/referral/page_referral_tree.dart';
import 'package:alienai_c35/widgets/auth/ui_ai_disclaimer_dialog.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_claim_dialog.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_commission_sheet.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_model_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_talk_stage.dart';
import 'package:alienai_c35/widgets/ai/composer_draft_host.dart';
import 'package:alienai_c35/widgets/ai/composer_stage_host.dart';
import 'package:alienai_c35/widgets/ai/in_composer.dart';
import 'package:alienai_c35/widgets/ai/msg_trace_view.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/c/tags/ask_tags.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_error.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_history_sidebar.dart';
import 'package:alienai_c35/widgets/ai/ui_chat_message_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_hints.dart';
import 'package:alienai_c35/widgets/ai/ui_live_call_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_context_menu.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_feedback_sheet.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_feedback_thread.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_blocks.dart';
import 'package:alienai_c35/c/presentation/slide_deck_theme_prefs.dart';
import 'package:alienai_c35/widgets/ai/ui_slide_deck_card.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_thought.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_usage.dart';
import 'package:alienai_c35/widgets/ai/ui_subagent_run_card.dart';
import 'package:alienai_c35/widgets/ai/ui_user_bubble.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_history_sheet.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_plan_sheet.dart';
import 'package:alienai_c35/widgets/chat/ui_chat_timeline.dart';
import 'package:alienai_c35/widgets/sites/ui_pos_link_host.dart';
import 'package:alienai_c35/widgets/sites/ui_sites_picker_dialog.dart';
import 'package:alienai_c35/widgets/sites/ui_staff_site_manage_card.dart';
import 'package:alienai_c35/widgets/sites/ui_staff_site_picker_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_account_menu.dart';
import 'package:alienai_c35/widgets/ui/ui_conn_wifi.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:alienai_c35/widgets/ai/ui_canvas_panel.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:alienai_c35/widgets/ai/ui_context_meter.dart';
import 'package:fixnum/fixnum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class PageAIHome extends StatefulWidget {
  const PageAIHome({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PageAIHome> createState() => _PageAIHomeState();
}

class _PageAIHomeState extends State<PageAIHome> with WidgetsBindingObserver {
  static const _bg = Color(0xFF08080A);
  static const _border = Color(0xFF27272A);
  static const _muted = Color(0xFF71717A);
  static const _text = Color(0xFFF4F4F5);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _store = ChatStore();
  final _canvasStore = CanvasStore();
  final _composerCtrl = TextEditingController();
  final _composerFocus = FocusNode();
  final _composerStageHost = ComposerStageHost();
  final _composerDraftHost = ComposerDraftHost();
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
  StreamSubscription? _socketAttachedSub;
  StreamSubscription? _followupPushSub;
  StreamSubscription? _promptRunPushSub;
  StreamSubscription? _notifyPushSub;
  Timer? _presenceTimer;
  var _appResumed = true;
  String? _clientId;
  String? _fcmToken;
  var _fcmStarted = false;
  var _fcmTokenSent = false;
  var _menuMsgIndex = 0;
  var _promptTokens = 0;
  TtsStreamQueue? _talkTtsQueue;
  ContextUsageParts _usage = const ContextUsageParts();
  int? _summarizeChatId;
  var _retrying = false;
  var _hintRunning = false;
  String? _selectedPlain;
  var _presentationDecksRev = -1;
  int? _presentationDecksChatId;
  List<SlideDeckData?>? _presentationDecksCache;
  Timer? _composerDraftDebounce;
  String? _uiLang;
  Timer? _promptWatchdog;
  Timer? _promptHardWatchdog;
  Timer? _connRefreshDebounce;
  ChatConnStatus? _connStatusLast;
  VoidCallback? _connStatusListener;
  VoidCallback? _promptConnGuardListener;
  var _talkRecording = false;
  var _talkMicStopInFlight = false;
  var _onboardingConsentInFlight = false;
  final _talkStaged = <StagedMedia>[];

  @override
  void initState() {
    super.initState();
    appUpdateBusyBind(conn: _conn, store: _store);
    WidgetsBinding.instance.addObserver(this);
    SttService.instance.bindVoiceApi(_voiceApi);
    TtsService.instance.bindVoiceApi(_voiceApi);
    if (Session.instance.modelId.isNotEmpty) _model = AgentModel.of(Session.instance.modelId, _store.models);
    _timeline.attach();
    _composerCtrl.addListener(_composerDraftScheduleSave);
    _connStatusLast = _conn.status.value;
    _connStatusListener = _onConnStatusChanged;
    _conn.status.addListener(_connStatusListener!);
    _reconnectedSub = _conn.onReconnected.listen((_) => _scheduleConnRefresh());
    _socketAttachedSub = _conn.onSocketAttached.listen((_) => _scheduleConnRefresh());
    _followupPushSub = _conn.onPromptFollowupPush.listen((p) {
      PromptFollowupStore.instance.mergePush(p);
    });
    _promptRunPushSub = _conn.onPromptRunPush.listen((push) {
      if (push.parentReqId.isNotEmpty) return;
      final cid = _store.activeChatId;
      if (cid == null) return;
      final rid = push.reqId.trim();
      if (push.status == 'queued' && !_store.promptBusyFor(cid)) {
        unawaited(_attachQueuedPromptRun(rid, cid));
        return;
      }
      if (rid.isEmpty || !_store.promptBusyFor(cid)) return;
      if (_store.pendingPromptReqId != rid) return;
      final terminal = push.status == 'done' || push.status == 'failed' || push.status == 'cancelled';
      if (terminal) {
        unawaited(() async {
          await _reconcilePromptState();
          if (!mounted) return;
          if (!_store.promptBusyFor(cid) || _store.pendingPromptReqId != rid) return;
          final reason = push.failReason.trim().isNotEmpty
              ? push.failReason.trim()
              : (push.status == 'cancelled' ? 'Prompt cancelled' : 'Prompt ended without a reply');
          _store.msgStreamFail(msgErrorNormalize(reason), chatId: cid, reqId: rid);
          _store.promptBusyPut(false, chatId: cid);
          if (mounted) setState(() {});
        }());
      }
    });
    NotifyRouter.appResumed = true;
    NotifyRouter.markRead = _notifyMarkRead;
    NotifyRouter.openRoute = _openNotifyRoute;
    _notifyPushSub = _conn.onNotifyPush.listen((push) {
      unawaited(NotifyRouter.show(push.title, push.body, push.routeJson, resumed: NotifyRouter.appResumed, id: push.id.toInt()));
      _store.notifyUnreadPut(_store.notifyUnreadCount + 1);
    });
    _presenceHeartbeat(true);
    VoicePrefs.instance.addListener(_onTalkPrefs);
    SttService.instance.isTranscribing.addListener(_onTalkSttUi);
    serverHostTick.addListener(_onServerHostChanged);
    ShareToHomeBridge.instance.addListener(_onShareToHome);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShareToHomeBridge.instance.setHomeReady(true);
      shareInboundBindPresenter();
      unawaited(shareInboundStart());
      unawaited(_boot());
      unawaited(_checkPostSignInPrompts());
    });
  }

  bool _homeSurfaceIsTop() => !Navigator.of(context).canPop();

  void _onShareToHome() {
    unawaited(_consumeInboundShare());
  }

  Future<void> _consumeInboundShare() async {
    final payload = ShareToHomeBridge.instance.takeQueued();
    if (payload == null || !mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _applyInboundShare(payload);
  }

  void _mergeInboundShareText(String shared) {
    final t = shared.trim();
    if (t.isEmpty) return;
    final cur = _composerCtrl.text;
    if (cur.trim().isEmpty) {
      _composerCtrl.text = t;
    } else {
      _composerCtrl.text = '$cur\n$t';
    }
    _composerCtrl.selection = TextSelection.collapsed(offset: _composerCtrl.text.length);
  }

  void _snackShare(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _applyInboundShare(ShareInboundPayload payload) async {
    if (!mounted) return;
    final atHome = _homeSurfaceIsTop();
    if (!atHome) {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.popUntil((route) => route.isFirst);
      _newChat();
    }

    final talk = VoicePrefs.instance.talkEnabled;
    final alreadyStaged = talk ? _talkStaged.length : 0;
    final result = await stagedMediaFromShareInbound(payload, alreadyStaged: alreadyStaged);
    final text = payload.text.trim();
    if (result.staged.isEmpty && text.isEmpty) {
      _snackShare('share.inboundNothingUsable'.tr());
      return;
    }
    if (result.skippedTotal > 0) {
      _snackShare('share.inboundPartialSkipped'.tr(namedArgs: {'count': '${result.skippedTotal}'}));
    }

    if (text.isNotEmpty) _mergeInboundShareText(text);

    if (result.staged.isNotEmpty) {
      if (talk) {
        _talkStageItems(result.staged);
      } else if (!_composerStageHost.stage(result.staged)) {
        _snackShare('share.inboundComposerNotReady'.tr());
        return;
      }
    }

    if (!talk) _composerFocus.requestFocus();
    _closeHistoryDrawerIfNarrow();
  }

  void _onServerHostChanged() {
    if (!mounted || !Session.instance.signedIn) return;
    unawaited(_connConnect());
  }

  void _onConnStatusChanged() {
    final next = _conn.status.value;
    final prev = _connStatusLast;
    _connStatusLast = next;
    if (next == ChatConnStatus.connected) {
      if (prev != ChatConnStatus.connected) {
        _scheduleConnRefresh();
      }
      return;
    }
    _promptCutOnDisconnect();
  }

  void _promptConnGuardUnbind() {
    if (_promptConnGuardListener == null) return;
    _conn.status.removeListener(_promptConnGuardListener!);
    _promptConnGuardListener = null;
  }

  /// While a turn is live, cut immediately whenever the socket is not connected (including retry while already reconnecting).
  void _promptConnGuardBind() {
    _promptConnGuardUnbind();
    _promptConnGuardListener = () {
      if (!_store.promptBusy) {
        _promptConnGuardUnbind();
        return;
      }
      if (!_conn.connected) _promptCutOnDisconnect();
    };
    _conn.status.addListener(_promptConnGuardListener!);
    _promptConnGuardListener!();
  }

  void _onPromptTurnStarted(int chatId, String reqId) {
    _store.promptBusyPut(true, chatId: chatId, reqId: reqId);
    _promptWatchdogStart(reqId);
    _promptConnGuardBind();
  }

  void _promptCutOnDisconnect() {
    if (_conn.status.value == ChatConnStatus.reconnecting) return;
    final cid = _store.promptChatId ?? _store.activeChatId;
    if (cid == null || !_store.promptBusyFor(cid)) return;
    _promptConnGuardUnbind();
    _promptWatchdogCancel();
    _talkTtsQueue?.cancel();
    final reqId = (_store.pendingPromptReqId ?? _store.promptLiveReqId ?? '').trim();
    _store.msgStreamFail(uiConnectionFailed, chatId: cid, reqId: reqId);
    if (_store.promptBusyFor(cid)) _store.promptBusyPut(false, chatId: cid);
    if (mounted) {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
        setState(() {});
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<void> _connConnect() async {
    final localePrefs = UserLocalePrefs.instance;
    try {
      await _conn.connect(
        locale: CatalogTranslationCache.instance.lang,
        tz: localePrefs.tz.isNotEmpty ? localePrefs.tz : UserLocalePrefs.deviceTimezoneDetect(),
      );
    } catch (_) {
      // connect() already scheduled auto-reconnect when appropriate
    }
    if (!_conn.connected) return;
    await _refreshConnSession();
    unawaited(_notifyAttach());
  }

  var _refreshConnInflight = false;

  /// Coalesce reconnect refresh (onReconnected + onSocketAttached + status listener).
  void _scheduleConnRefresh() {
    _connRefreshDebounce?.cancel();
    _connRefreshDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(_refreshConnSession());
    });
  }

  Future<void> _refreshConnSession() async {
    if (_refreshConnInflight) return;
    _refreshConnInflight = true;
    try {
      await _store.refreshFromConn(_conn, locale: CatalogTranslationCache.instance.lang);
      await _reconcilePromptState();
    } catch (e) {
      lError('conn session refresh: $e');
    } finally {
      _refreshConnInflight = false;
    }
    if (mounted) setState(() {});
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
    _onPromptTurnStarted(chatId, reqId);
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
          _promptWatchdogReset(reqId);
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
          await _promptEnsureBodyAfterEnd(chatId, end.reqId);
          _store.msgStreamEnd(
            chatId: chatId,
            msgId: end.msgId.toInt(),
            tokensIn: end.tokensIn,
            tokensOut: end.tokensOut,
            costUsd: end.costUsd,
            durationMs: end.durationMs,
            traceJson: end.traceJson,
            reqId: end.reqId,
            model: end.model,
            error: end.hasErrorMessage() ? end.errorMessage : '',
          );
          _promptEstimateApply(chatId, end);
          continue;
        }
        if (ev.kind == 'fail') {
          _store.msgStreamFail(msgErrorNormalize(ev.message), chatId: chatId, startedAtMs: startedAt, reqId: reqId);
        }
      }
    } catch (e) {
      final recovered = await _promptStreamRecoverFromServer(chatId, reqId);
      if (!recovered) _store.msgStreamFail(msgErrorNormalize(e), chatId: chatId, startedAtMs: startedAt);
    } finally {
      _promptWatchdogCancel();
      _promptConnGuardUnbind();
      _store.msgStreamFinalize(chatId: chatId, model: _model.id, startedAtMs: startedAt);
      if (_store.promptBusyFor(chatId)) _store.promptBusyPut(false, chatId: chatId);
      PromptFollowupStore.instance.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkPostSignInPrompts() async {
    if (!mounted || !Session.instance.signedIn) return;
    await _checkOnboardingConsent();
    if (!mounted) return;
    _checkReferralPrompt();
  }

  void _checkReferralPrompt() {
    if (!mounted) return;
    if (Session.instance.needsReferralPrompt) {
      UiReferralClaimDialog.show(context, auth: widget.auth);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appResumedSet(true);
        unawaited(_reconcilePromptState());
        if (_conn.status.value != ChatConnStatus.connected) {
          unawaited(_connConnect());
        } else {
          unawaited(_refreshConnSession());
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _appResumedSet(false);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _appResumedSet(bool resumed) {
    _appResumed = resumed;
    NotifyRouter.appResumed = resumed;
    unawaited(_presenceSend(resumed));
    _presenceHeartbeat(resumed);
  }

  void _presenceHeartbeat(bool run) {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    if (!run) return;
    _presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_appResumed || !_conn.connected) return;
      unawaited(_presenceSend(true));
    });
  }

  Future<String> _clientIdGet() async => _clientId ??= await deviceInstallId();

  Future<void> _presenceSend(bool resumed) async {
    if (!_conn.connected) return;
    try {
      await _conn.appPresence(clientId: await _clientIdGet(), resumed: resumed);
    } catch (e) {
      lError('app presence: $e');
    }
  }

  Future<void> _notifyAttach() async {
    await _presenceSend(_appResumed);
    await _fcmTokenPut();
  }

  Future<void> _fcmTokenPut() async {
    if (!_fcmStarted) {
      _fcmStarted = true;
      _fcmToken = await FcmService.start(NotifyRouter.deliverFcm);
    }
    final token = _fcmToken;
    if (token == null || token.isEmpty || _fcmTokenSent || !_conn.connected) return;
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    if (platform != 'ios' && platform != 'android') return;
    try {
      await _conn.notifyTokenPut(clientId: await _clientIdGet(), token: token, platform: platform);
      _fcmTokenSent = true;
    } catch (e) {
      lError('notify token: $e');
    }
  }

  Future<void> _notifyMarkRead(int id) async {
    try {
      await _conn.notifyRead(ids: [id]);
    } catch (_) {}
  }

  void _openNotifyRoute(String routeJson) {
    final raw = routeJson.trim();
    if (raw.isEmpty || raw == '{}') return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final chat = decoded['chat_id'];
      final chatId = chat is num ? chat.toInt() : int.tryParse('$chat') ?? 0;
      final reqId = decoded['req_id']?.toString() ?? '';
      if (chatId > 0) unawaited(_navigateToChatMessage(chatId, reqId));
    } catch (_) {}
  }

  void _openNotifyHistory() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageNotifyHistory(conn: _conn)));

  void _promptWatchdogCancel() {
    _promptWatchdog?.cancel();
    _promptWatchdog = null;
    _promptHardWatchdog?.cancel();
    _promptHardWatchdog = null;
  }

  void _promptWatchdogStart(String reqId) {
    _promptWatchdogCancel();
    // Inactivity silence watchdog: resets whenever streaming activity arrives.
    _promptWatchdog = Timer(const Duration(seconds: 45), () => unawaited(_promptWatchdogFire(reqId, reason: 'Timed out waiting for response (inactivity)')));
    // Hard ceiling watchdog: no single turn should hang beyond 5 minutes regardless of trickle.
    _promptHardWatchdog = Timer(const Duration(minutes: 5), () => unawaited(_promptWatchdogFire(reqId, reason: 'Turn exceeded maximum execution duration (5m)')));
  }

  void _promptWatchdogReset(String reqId) {
    _promptWatchdog?.cancel();
    _promptWatchdog = Timer(const Duration(seconds: 45), () => unawaited(_promptWatchdogFire(reqId, reason: 'Timed out waiting for response (inactivity)')));
  }

  Future<void> _reconcilePromptState({bool force = true}) async {
    final cid = _store.activeChatId;
    if (cid == null || cid <= 0) return;
    final locale = CatalogTranslationCache.instance.lang;
    final pullForce = force || _store.promptBusyFor(cid);
    try {
      await _store.msgsPullFromServer(_conn, cid, locale: locale, force: pullForce);
      if (_store.promptBusyFor(cid)) await _store.feedbackPull(_conn, cid, locale: locale);
    } catch (e) {
      lError('prompt reconcile: $e');
    }
    _store.promptReconcileFromServerMsgs(cid, _store.msgs.where((m) => m.chatId == cid));
    if (mounted) setState(() {});
  }

  Future<void> _promptEnsureBodyAfterEnd(int chatId, String reqId) async {
    final rid = reqId.trim();
    for (final m in _store.msgs) {
      if (m.chatId != chatId || m.role != 'assistant') continue;
      if (rid.isNotEmpty && m.reqId != rid) continue;
      if (msgHasBody(m)) return;
    }
    final ok = await _promptStreamRecoverFromServer(chatId, rid);
    if (ok && mounted) setState(() {});
  }

  Future<bool> _promptStreamRecoverFromServer(int chatId, String reqId) async {
    if (chatId <= 0) return false;
    final locale = CatalogTranslationCache.instance.lang;
    try {
      await _store.msgsPullFromServer(_conn, chatId, locale: locale, force: true);
      if (_store.promptBusyFor(chatId)) await _store.feedbackPull(_conn, chatId, locale: locale);
      final rid = reqId.trim();
      _store.promptReconcileFromServerMsgs(chatId, _store.msgs.where((m) => m.chatId == chatId));
      for (final row in _store.msgs) {
        if (row.chatId != chatId || row.role != 'assistant') continue;
        if (rid.isNotEmpty && row.reqId != rid) continue;
        if (row.error.trim().isEmpty && msgHasBody(row)) return true;
      }
    } catch (e) {
      lError('prompt stream recover: $e');
    }
    return false;
  }

  Future<void> _promptWatchdogFire(String reqId, {String reason = 'Timed out waiting for reply'}) async {
    final cid = _store.promptChatId ?? _store.activeChatId;
    if (cid == null || !_store.promptBusyFor(cid) || _store.pendingPromptReqId != reqId) return;
    l('prompt watchdog: reqId=$reqId chatId=$cid reason=$reason');
    final offline = _conn.status.value != ChatConnStatus.connected;
    if (!offline && cid > 0) {
      try {
        await _reconcilePromptState(force: true).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    if (!_store.promptBusyFor(cid) || _store.pendingPromptReqId != reqId) return;
    final failReason = offline ? uiConnectionFailed : reason;
    _store.msgStreamFail(failReason, chatId: cid, reqId: reqId);
    try {
      await _conn.promptAbort(chatId: cid > 0 ? Int64(cid) : Int64.ZERO, reqId: reqId).timeout(const Duration(seconds: 5));
    } catch (_) {}
    _store.promptBusyPut(false, chatId: cid);
    _promptWatchdogCancel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promptWatchdogCancel();
    _promptConnGuardUnbind();
    if (_connStatusListener != null) _conn.status.removeListener(_connStatusListener!);
    SttService.instance.bindVoiceApi(null);
    TtsService.instance.bindVoiceApi(null);
    _syncSub?.cancel();
    _billingBalanceSub?.cancel();
    _billingQuotaSub?.cancel();
    _billingCommissionSub?.cancel();
    _reconnectedSub?.cancel();
    _socketAttachedSub?.cancel();
    _connRefreshDebounce?.cancel();
    _followupPushSub?.cancel();
    _promptRunPushSub?.cancel();
    _notifyPushSub?.cancel();
    _presenceTimer?.cancel();
    VoicePrefs.instance.removeListener(_onTalkPrefs);
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onTalkLiveTranscript);
    SttService.instance.isTranscribing.removeListener(_onTalkSttUi);
    serverHostTick.removeListener(_onServerHostChanged);
    _timeline.dispose();
    _conn.disconnect();
    _canvasStore.dispose();
    ShareToHomeBridge.instance.removeListener(_onShareToHome);
    ShareToHomeBridge.instance.setHomeReady(false);
    ShareInbound.instance.onPayload = null;
    ShareInbound.instance.stop();
    _composerDraftDebounce?.cancel();
    _composerCtrl.removeListener(_composerDraftScheduleSave);
    _composerCtrl.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    if (!mounted) return;
    _uiLang = context.locale.languageCode;
    try {
      await HintStore.instance.restore();
      await _store.sessionInitCacheRestore();
      await _store.mentionCatalog.restore();
      await CatalogTranslationCache.instance.restore();
      await CatalogTranslationCache.instance.ensure(_uiLang!);
    } catch (e) {
      lError('catalog load: $e');
    }
    await PromptUsagePrefs.instance.load();
    await ComposerDraftStore.instance.restoreForUid(Session.instance.uid);
    if (mounted) setState(() => _catalogReady = true);
    try {
      await _connConnect();
      if (_store.mentionCatalog.mentions.isEmpty) {
        try {
          await _store.mentionCatalog.refresh(_conn);
        } catch (e) {
          lError('mention list: $e');
        }
      }
      if (mounted) {
        final draft = ComposerDraftStore.instance.get(_composerDraftChatKey);
        if (draft != null && (draft.text.isNotEmpty || draft.mentionIds.isNotEmpty)) {
          _composerDraftRestore();
        } else {
          setState(() => _mentionContextSyncFromChat(restoreComposer: true));
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
  }

  bool _onboardingNeedsLocationPrompt() {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) return false;
    if (UserLocationPrefs.instance.asked) return false;
    if (UserLocalePrefs.instance.locationCity.isNotEmpty) return false;
    return true;
  }

  Future<void> _checkOnboardingConsent() async {
    if (!mounted || !Session.instance.signedIn || _onboardingConsentInFlight) return;
    await UserLocationPrefs.instance.load();
    if (!mounted) return;
    final needTerms = !await AiDisclaimerPrefs.instance.acknowledged;
    final needLocation = _onboardingNeedsLocationPrompt();
    if (!needTerms && !needLocation) return;
    if (!mounted) return;
    _onboardingConsentInFlight = true;
    try {
      final result = await UiAiDisclaimerDialog.show(context, needTerms: needTerms, needLocation: needLocation);
      if (!mounted || result == null) return;
      if (needTerms) await AiDisclaimerPrefs.instance.acknowledgePut();
      if (needLocation) await UserLocationPrefs.instance.put(asked: true);
      if (result.locationOptIn) await _applyDeviceLocationFromConsent();
    } finally {
      _onboardingConsentInFlight = false;
    }
  }

  Future<void> _applyDeviceLocationFromConsent() async {
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
      if (push.hasChat()) {
        _store.chatPutFromServer(push.chat, m);
      } else {
        ChatRow? row;
        for (final c in _store.chats) {
          if (c.id == m.chatId.toInt()) {
            row = c;
            break;
          }
        }
        if (row != null) {
          _store.chatPutFromServer(
            Chat(id: Int64(row.id), title: row.title, tags: row.tags),
            m,
          );
        }
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
        _store.promptReconcileFromServerMsgs(cid, _store.msgs.where((x) => x.chatId == cid));
      }
    }
  }

  int? get _composerDraftChatKey => _store.activeChatId;

  void _composerDraftScheduleSave() {
    _composerDraftDebounce?.cancel();
    _composerDraftDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ComposerDraftStore.instance.put(
        _composerDraftChatKey,
        text: _composerCtrl.text,
        mentionIds: _mentionIds,
        stagedAttachments: _composerDraftHost.readAttachments(),
      );
    });
  }

  void _composerDraftSaveNow() {
    _composerDraftDebounce?.cancel();
    ComposerDraftStore.instance.put(
      _composerDraftChatKey,
      text: _composerCtrl.text,
      mentionIds: _mentionIds,
      stagedAttachments: _composerDraftHost.readAttachments(),
    );
  }

  void _composerDraftRestore() {
    final draft = ComposerDraftStore.instance.get(_composerDraftChatKey);
    if (draft != null && !draft.isEmpty) {
      _composerCtrl.text = draft.text;
      final len = draft.text.length;
      _composerCtrl.selection = TextSelection.collapsed(offset: len);
      _mentionIds
        ..clear()
        ..addAll(draft.mentionIds);
      _composerDraftHost.restoreAttachments([
        for (final a in draft.attachments) a.toStaged(),
      ]);
      return;
    }
    _composerCtrl.clear();
    _composerDraftHost.clearAttachments();
    _mentionIdsSyncFromChat();
    _composerStickyMentionsRestore();
  }

  void _composerReset({bool clearDraft = false}) {
    if (clearDraft) ComposerDraftStore.instance.remove(_composerDraftChatKey);
    _composerCtrl.clear();
    _composerDraftHost.clearAttachments();
    _composerFocus.unfocus();
  }

  void _mentionIdsSyncFromChat() {
    _mentionIds.clear();
    final chat = _activeChat;
    if (chat == null) return;
    if (chat.boundDeviceIid > 0) _mentionIds.add('iid:${chat.boundDeviceIid}');
    _mentionIds.addAll(chat.stickyMentionIds);
  }

  void _composerStickyMentionsRestore() {
    if (_mentionIds.isEmpty) return;
    final catalog = _store.mentionCatalog.mentions;
    final merged = composerMentionDraftMergeSticky(_composerCtrl.text, _mentionIds, catalog);
    if (merged == _composerCtrl.text) return;
    _composerCtrl.text = merged;
    _composerCtrl.selection = TextSelection.collapsed(offset: merged.length);
  }

  void _mentionContextSyncFromChat({bool restoreComposer = false}) {
    _mentionIdsSyncFromChat();
    if (restoreComposer) _composerStickyMentionsRestore();
  }

  void _closeHistoryDrawerIfNarrow() {
    if (MediaQuery.sizeOf(context).width >= 720) return;
    final state = _scaffoldKey.currentState;
    if (state == null || !state.isDrawerOpen) return;
    state.closeDrawer();
  }

  void _newChat() {
    _composerDraftSaveNow();
    _promptTokens = 0;
    _usage = const ContextUsageParts();
    _store.chatNew();
    _composerDraftRestore();
    _canvasStore.clear();
    _timeline.scrollToBottom(force: true);
    _closeHistoryDrawerIfNarrow();
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
    _composerDraftSaveNow();
    _closeHistoryDrawerIfNarrow();
    _store.chatSelect(id);
    final savedTokens = _store.chatPromptTokensGet(id);
    _promptTokens = savedTokens;
    _usage = savedTokens > 0 ? ContextUsageParts(conversation: savedTokens) : const ContextUsageParts();
    var lastSeenMsgId = 0;
    for (final m in _store.msgs) {
      if (m.chatId == id && m.id > lastSeenMsgId) lastSeenMsgId = m.id;
    }
    unawaited(_conn.sessionFocus(chatId: id, lastSeenMsgId: lastSeenMsgId).catchError((_) => ResSessionFocus()));
    _composerDraftRestore();
    _canvasStore.clear();
    final locale = CatalogTranslationCache.instance.lang;
    try {
      await _store.msgsPullFromServer(_conn, id, locale: locale);
      if (_store.promptBusyFor(id)) await _store.feedbackPull(_conn, id, locale: locale);
      _store.promptReconcileFromServerMsgs(id, _store.msgs.where((m) => m.chatId == id));
    } catch (_) {}
    if (!mounted) return;
    if (_promptTokens <= 0) {
      final est = _effectivePromptTokens;
      if (est > 0) {
        _promptTokens = est;
        _usage = _effectiveUsage;
      }
    }
    setState(() {});
    _timeline.scrollToBottom(force: true);
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
        ChatMessageMenuAction(
          label: 'Copy Chat ID',
          icon: Icons.copy_rounded,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: msgCopyClipboardId('Chat ID', '$id')));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chat ID copied'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
            );
          },
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
    _composerDraftSaveNow();
    await ComposerDraftStore.instance.clearForUid(Session.instance.uid);
    await _conn.disconnect();
    await widget.auth.signOut();
  }

  void _lockSession() => widget.auth.lockSession();

  void _openBots() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageBots(chatConn: _conn, shellStore: _store)));

  void _openDevices() => unawaited(openPageDevices(context, chatConn: _conn, shellStore: _store));

  void _openSites() => uiSitesPickerOpen(
        context: context,
        chatConn: _conn,
        shellStore: _store,
        onEdit: (siteIid) => _openSiteAdmin(siteIid, initialTabRoute: null),
        onPos: (siteIid) => sitePosOpen(context: context, chatConn: _conn, siteIid: siteIid),
      );

  void _openSiteAdmin(String siteIid, {String? initialTabRoute}) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageSites(chatConn: _conn, siteIid: siteIid, initialTabRoute: initialTabRoute),
        ),
      );

  void _openDirectorManageSite() => uiStaffSitePickerOpen(
        context: context,
        chatConn: _conn,
        onPicked: (row) {
          final siteIid = row.siteIid.toString();
          uiStaffSiteManageCardShow(
            context: context,
            chatConn: _conn,
            row: row,
            action: UiStaffSiteManageAction(
              onEdit: () => _openSiteAdmin(siteIid, initialTabRoute: null),
              onPos: () => sitePosOpen(context: context, chatConn: _conn, siteIid: siteIid),
            ),
          );
        },
      );

  void _openMail() => unawaited(openPageMail(context, chatConn: _conn));

  void _openRootConsole() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PageRootConsole(chatConn: _conn)));

  bool get _financeStaff => Session.instance.isFinanceStaff;

  void _openFinancePayments() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PageFinancePayments(conn: ReferralConn(uid: Session.instance.uid), canReview: _financeStaff),
        ),
      );

  void _openFinanceReceiveAccounts() => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => PageFinanceReceiveAccounts(conn: ReferralConn(uid: Session.instance.uid))),
      );

  void _openCommissionSheet() => referralCommissionSheet(context, conn: ReferralConn(uid: Session.instance.uid));

  Future<void> _navigateToChatMessage(int chatId, String reqId) async {
    if (chatId <= 0) return;
    if (_store.activeChatId != chatId) {
      await _selectChat(chatId);
    }
    if (reqId.isEmpty) return;

    final msgs = _store.msgs.where((m) => m.chatId == chatId).toList();
    final idx = msgs.indexWhere((m) => m.reqId == reqId);
    if (idx >= 0) {
      _timeline.scrollToChronologicalIndex(idx, itemCount: msgs.length, alignment: 0.5);
    }
  }

  Future<void> _avatarMenu(BuildContext anchorCtx) async {
    if (!mounted || !anchorCtx.mounted) return;
    uiAccountMenuShow(
        anchorCtx,
        action: UiAccountMenuAction(
          conn: ReferralConn(uid: Session.instance.uid),
          shellStore: _store,
          onSettings: _openSettings,
          onReferralTree: _openReferralTree,
          onBalance: () => billingHistorySheet(
            context,
            conn: ReferralConn(uid: Session.instance.uid),
            onNavigateToMessage: _navigateToChatMessage,
            mentionCatalog: _store.mentionCatalog,
          ),
          onPackage: () => showBillingPlanSheet(context, ReferralConn(uid: Session.instance.uid)),
          onCommissionTap: _openCommissionSheet,
          onFinancePayments: _financeStaff ? _openFinancePayments : null,
          onFinanceReceiveAccounts: _financeStaff ? _openFinanceReceiveAccounts : null,
          onMarketingGenerateVoucher: null,
          onLock: _lockSession,
          onSignOut: _signOut,
          onBots: _openBots,
          onDevices: _openDevices,
          onSites: _openSites,
          onRootConsole: Session.instance.isRoot ? _openRootConsole : null,
          onDirectorManageSite: Session.instance.isDirectorStaff ? _openDirectorManageSite : null,
          onMail: Session.instance.canUseMail || mailInboxBus.menuVisible ? _openMail : null,
          onNotifications: _openNotifyHistory,
          composerModel: _model,
          liveOffers: _store.liveOffers,
          onLiveCallStart: _liveCallStart,
          mailInboxCount: mailInboxBus.inboxCount,
          notifyUnreadCount: _store.notifyUnreadCount,
        ),
      );
  }

  String _primaryMentionLabel() {
    if (_mentionIds.isEmpty) return '';
    final id = _mentionIds.first;
    for (final m in _store.mentionCatalog.mentions) {
      if (m.id == id) return m.displayLabel;
    }
    return '';
  }

  void _mentionToggle(String id) {
    setState(() {
      final removing = _mentionIds.contains(id);
      if (removing) {
        _mentionIds.remove(id);
        _composerCtrl.text = _composerCtrl.text.replaceAll(composerMentionToken(id), '').trimLeft();
      } else {
        _mentionIds.add(id);
        _composerStickyMentionsRestore();
      }
      final chatId = _store.activeChatId;
      if (chatId != null) _store.chatStickyMentionsPut(chatId, _mentionIds.toList());
    });
    _composerDraftScheduleSave();
  }

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
      if (mounted) _composerReset(clearDraft: true);
    } finally {
      _hintRunning = false;
    }
  }

  Future<void> _hintNavigate(String route, Map<String, dynamic> payload) async {
    if (route != 'site.pos' || !mounted) return;
    final siteIid = '${payload['site_iid'] ?? ''}'.trim();
    if (siteIid.isEmpty) return;
    await sitePosOpen(context: context, chatConn: _conn, siteIid: siteIid);
  }

  Future<void> _imageUpgradeHd(ChatBlock block) async {
    final prompt = block.body['prompt']?.toString().trim() ?? '';
    if (!ChatBlock.imageCanUpgradeHd(block)) return;
    if (_store.promptBusy) return;
    final locale = CatalogTranslationCache.instance.lang;
    final lead = locale.startsWith('id')
        ? 'Buat ulang gambar ini dalam kualitas HD (2K), detail lebih tajam.'
        : 'Regenerate this image in HD (2K) with sharper detail.';
    await _composerSend('$lead\n\n$prompt', const [], mentionIds: const ['image_high']);
  }

  Future<void> _runTestMultitask() => _composerSend(composerTestMultitaskSlash, const []);

  Future<void> _composerSend(String text, List<MsgAttachment> attachments, {bool retry = false, int? retryChatId, String? toolMode, List<String>? mentionIds, String? displayContent, bool talk = false}) async {
    var trimmed = text.trim();
    var uiContent = (displayContent ?? trimmed).trim();
    var composerMentionIds = mentionIds;
    if (composerSendIsTestMultitask(uiContent) || composerSendIsTestMultitask(trimmed)) {
      final p = composerTestMultitaskPayload();
      trimmed = p.text;
      uiContent = p.displayContent;
      composerMentionIds = p.mentionIds;
    }
    final earlyChatId = retry ? (retryChatId ?? _store.activeChatId) : _store.activeChatId;
    final catalogMentions = _store.mentionCatalog.mentions;
    var wireMentionIds = composerMentionIdsForWire(
      fromComposer: composerMentionIds,
      selectedSticky: _mentionIds,
      chatSticky: earlyChatId != null ? _store.chatStickyMentionsFor(earlyChatId) : const [],
      text: uiContent,
    );
    if (trimmed.isEmpty && attachments.isEmpty && wireMentionIds.isEmpty) return;
    final draftKeyBeforeSend = _store.activeChatId;
    final wireText = composerMentionTextForWire(uiContent, catalogMentions, mentionIds: wireMentionIds);
    if (wireText.isEmpty && attachments.isEmpty && wireMentionIds.isEmpty) return;
    ComposerDraftStore.instance.remove(draftKeyBeforeSend);
    final previewLine = wireText;
    if (_store.promptBusy && !retry) {
      final cid = _store.activeChatId;
      if (cid == null) return;
      try {
        final res = await _conn.promptFollowupPut(
          chatId: cid,
          text: wireText,
          reqId: _conn.lastPromptReqId ?? '',
          attachmentsJson: MsgAttachment.encode(attachments),
        );
        if (res.rejected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(promptFollowupRejectLabel(res.rejectReason, localeCode: context.locale.languageCode))),
          );
        } else {
          _composerReset();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Queued while the current reply finishes'), behavior: SnackBarBehavior.floating),
            );
          }
          await _followupRefresh();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    unawaited(TtsService.instance.stop());

    int? chatId;
    if (retry) {
      chatId = retryChatId ?? _store.activeChatId;
      if (chatId == null || chatId == 0) return;
      if (_store.activeChatId != chatId) _store.chatSelect(chatId);
    } else {
      chatId = _store.activeChatId;
      if (chatId == null) {
        _store.chatEnsurePending();
        chatId = _store.activeChatId;
      }
    }
    if (chatId == null) return;

    if (wireMentionIds.isNotEmpty) {
      _store.chatStickyMentionsMerge(chatId, wireMentionIds);
    }
    if (mounted) {
      setState(() => _mentionContextSyncFromChat(restoreComposer: true));
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final reqId = const Uuid().v4();
    final mentionIdsJson = msgMentionIdsEncode(wireMentionIds);
    final userMsg = MsgRow(
      id: _store.msgNextLocalId(),
      chatId: chatId,
      role: 'user',
      content: uiContent,
      attachments: attachments,
      attachmentsJson: MsgAttachment.encode(attachments),
      createdAtMs: now,
      reqId: reqId,
      mentionIdsJson: mentionIdsJson,
    );
    _store.msgPut(userMsg);
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
        text: wireText,
        chatId: serverChatId,
        attachmentsJson: MsgAttachment.encode(attachments),
        mentionIds: wireMentionIds,
        model: _model.id,
        thinking: _model.thinking.wire,
        toolMode: turnToolMode,
        locale: CatalogTranslationCache.instance.lang,
        reqId: reqId,
        talk: talk,
        replaceLastTurn: retry,
      );
    _onPromptTurnStarted(chatId, reqId);
    unawaited(_followupRefresh());
    _store.msgStreamStart(chatId: chatId, reqId: reqId, model: _model.id);
    final promptStartedAtMs = _store.promptStartedAtMs;
    if (VoicePrefs.instance.talkEnabled && VoicePrefs.instance.talkSpeakEnabled) {
      _talkTtsQueue?.cancel();
      _talkTtsQueue = TtsStreamQueue(
        onComplete: () {
          if (!mounted) return;
          if (VoicePrefs.instance.talkEnabled &&
              VoicePrefs.instance.talkAutoListen &&
              !_talkRecording &&
              !_store.promptBusyFor(_store.activeChatId)) {
            unawaited(_talkMicStart());
          }
        },
      );
    }
    try {
      await for (final ev in promptStream) {
        if (_conn.promptStreamWasAborted(reqId)) break;
        if (ev.kind == 'start') {
          if (ev.chatId != Int64.ZERO) {
            final startId = ev.chatId.toInt();
            streamChatId = startId;
            final existingTitle = _store.chats.where((c) => c.id == startId).map((c) => c.title).firstOrNull ?? '';
            final title = chatTitleOnPromptStart(
              localChatId: localChatId,
              serverChatId: startId,
              existingTitle: existingTitle,
              previewLine: previewLine,
              mentions: catalogMentions,
            );
            if (startId != localChatId) {
              _store.chatIdMigrate(localChatId, startId);
              ComposerDraftStore.instance.migrateKey(localChatId, startId);
            }
            _store.chatPutFromServer(
              Chat(id: ev.chatId, title: title),
              ChatMember(chatId: ev.chatId, lastMsgPreview: previewLine, lastMsgTsMs: Int64(now)),
            );
            _store.promptBusyPut(true, chatId: startId, reqId: _conn.lastPromptReqId);
            if (_store.activeChatId == localChatId || _store.activeChatId == null) _store.chatSelect(startId);
            if (mounted) setState(() => _mentionContextSyncFromChat(restoreComposer: true));
          }
          _store.msgStreamStart(chatId: streamChatId, reqId: _conn.lastPromptReqId ?? '', model: ev.model.isNotEmpty ? ev.model : _model.id);
          continue;
        }
        if (ev.kind == 'delta') {
          _promptWatchdogReset(reqId);
          final rid = (_conn.lastPromptReqId ?? reqId).trim();
          if (!_store.msgStreamAccepts(rid)) continue;
          if (ev.thought) {
            _store.msgStreamThought(ev.text, chatId: streamChatId, reqId: rid);
            if (rid.isNotEmpty && ev.text.contains('Using ')) {
              unawaited(_conn.tracePrefetch(rid));
            }
          } else if (ev.blocksJson.isNotEmpty) {
            _store.msgStreamBlocks(ev.blocksJson, chatId: streamChatId, reqId: rid);
          } else {
            _store.msgStreamContent(ev.text, chatId: streamChatId, reqId: rid);
            if (VoicePrefs.instance.talkEnabled && VoicePrefs.instance.talkSpeakEnabled && !ev.thought && ev.text.isNotEmpty) {
              _talkTtsQueue ??= TtsStreamQueue();
              _talkTtsQueue!.feedChunk(ev.text);
            }
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
          await _promptEnsureBodyAfterEnd(streamChatId, end.reqId);
          _store.msgStreamEnd(
            chatId: streamChatId,
            msgId: end.msgId.toInt(),
            tokensIn: end.tokensIn,
            tokensOut: end.tokensOut,
            costUsd: end.costUsd,
            durationMs: end.durationMs,
            traceJson: end.traceJson,
            reqId: end.reqId,
            model: end.model,
            error: err,
          );
          _promptEstimateApply(streamChatId, end);
          if (VoicePrefs.instance.talkEnabled && VoicePrefs.instance.talkSpeakEnabled && err.trim().isEmpty) {
            _talkTtsQueue?.flush();
          }
          if (end.reqId.isNotEmpty) {
            unawaited(_conn.tracePrefetch(end.reqId).then((_) {
              if (mounted) setState(() {});
            }));
          }
          continue;
        }
        if (ev.kind == 'fail') {
          final rid = (_conn.lastPromptReqId ?? reqId).trim();
          if (_conn.promptStreamWasAborted(rid) || ev.message.trim().toLowerCase() == 'cancelled') {
            _store.msgStreamCancel(chatId: streamChatId, reqId: rid);
            _conn.promptStreamAbortAck(rid);
            break;
          }
          _store.msgStreamFail(msgErrorNormalize(ev.message), chatId: streamChatId, startedAtMs: promptStartedAtMs, reqId: rid);
          continue;
        }
      }
    } catch (e) {
      final rid = _conn.lastPromptReqId?.trim().isNotEmpty == true ? _conn.lastPromptReqId!.trim() : reqId;
      final recovered = await _promptStreamRecoverFromServer(streamChatId, rid);
      if (!recovered) {
        final rid = _conn.lastPromptReqId?.trim().isNotEmpty == true ? _conn.lastPromptReqId!.trim() : reqId;
        _store.msgStreamFail(msgErrorNormalize(e), chatId: streamChatId, startedAtMs: promptStartedAtMs, reqId: rid);
      }
    } finally {
      if (_conn.promptStreamWasAborted(reqId)) {
        _store.msgStreamCancel(chatId: streamChatId, reqId: reqId);
        _conn.promptStreamAbortAck(reqId);
      }
      _promptWatchdogCancel();
      _promptConnGuardUnbind();
      if (!_store.msgStreamCancelled(reqId)) {
        _store.msgStreamFinalize(chatId: streamChatId, model: _model.id, startedAtMs: promptStartedAtMs);
      }
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
    final reqId = (_store.pendingPromptReqId ?? _store.promptLiveReqId ?? '').trim();
    if (id == null || reqId.isEmpty) return;
    _talkTtsQueue?.cancel();
    _promptConnGuardUnbind();
    _promptWatchdogCancel();
    _store.promptStoppingBegin(reqId: reqId, chatId: id);
    _conn.promptStreamAbortLocal(reqId: reqId);
    if (mounted) setState(() {});
    unawaited(() async {
      try {
        await _conn.promptAbort(
          chatId: id > 0 ? Int64(id) : Int64.ZERO,
          reqId: reqId,
        );
      } catch (_) {}
    }());
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

  Widget _chatHeaderAccountTrailing(BuildContext menuCtx) => _HomeChatHeaderAccountTrailing(
        key: const ValueKey('chat_header_account_trailing'),
        menuCtx: menuCtx,
        home: this,
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

  Widget _activeChatTitleWidget() {
    final chat = _activeChat;
    if (chat == null) return const SizedBox.shrink();
    return ChatTitleText(
      title: chat.title,
      mentions: _store.mentionCatalog.mentions,
      stickyMentionIds: chat.stickyMentionIds,
      style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
      maxLines: 1,
    );
  }

  List<ChatMessageMenuItem> _messageBubbleMenuItems(
    BuildContext ctx, {
    required MsgRow m,
    required int index,
    required int lastUserIdx,
    required int lastAssistantIdx,
    String? selectedText,
  }) {
    final isUser = m.role == 'user';
    final plain = msgDisplayContent(m).trim();
    final showRetry = !_store.promptBusyFor(m.chatId) && (index == lastUserIdx || index == lastAssistantIdx);
    ChatBlock? imageBlock;
    var showImageUpgrade = false;
    if (!isUser && m.blocksJson.contains('"image"')) {
      imageBlock = ChatBlock.imageFirstUpgradeable(m.blocksJson);
      showImageUpgrade = imageBlock != null && !_store.promptBusyFor(m.chatId);
    }
    final imageBlockCaptured = imageBlock;
    return msgBubbleMenuItems(
      ctx,
      plainText: plain,
      selectedText: selectedText,
      viewerIsRoot: sessionViewerIsRoot(),
      isAssistant: !isUser,
      reqId: m.reqId,
      msgId: m.id > 0 ? m.id : 0,
      thought: m.thought,
      onSpeak: !isUser && plain.isNotEmpty
          ? () {
              ContextMenuController.removeAny();
              unawaited(_speak(_plainForMsg(m)));
            }
          : null,
      showRetry: showRetry,
      onRetryLastTurn: showRetry ? () => unawaited(_retryLastTurn(m.chatId)) : null,
      onImageUpgradeHd: showImageUpgrade
          ? () {
              if (imageBlockCaptured != null) unawaited(_imageUpgradeHd(imageBlockCaptured));
            }
          : null,
      conn: _conn,
      onGoodAnswer: !isUser && m.id > 0 ? () => unawaited(_feedback(m, ChatFeedbackVote.CHAT_FEEDBACK_VOTE_GOOD)) : null,
      onBadAnswer: !isUser && m.id > 0 ? () => unawaited(_feedback(m, ChatFeedbackVote.CHAT_FEEDBACK_VOTE_BAD)) : null,
    );
  }

  Widget _threadContextMenu(BuildContext ctx, SelectableRegionState state) {
    final messages = _store.activeMsgs;
    if (messages.isEmpty) return const SizedBox.shrink();
    final i = _menuMsgIndex.clamp(0, messages.length - 1);
    final m = messages[i];
    final lastUserIdx = messages.lastIndexWhere((x) => x.role == 'user');
    final lastAssistantIdx = messages.lastIndexWhere((x) => x.role == 'assistant');
    final items = _messageBubbleMenuItems(
      ctx,
      m: m,
      index: i,
      lastUserIdx: lastUserIdx,
      lastAssistantIdx: lastAssistantIdx,
      selectedText: _selectedPlain,
    );
    return msgBubbleContextMenuAt(
      ctx,
      state.contextMenuAnchors.primaryAnchor,
      secondaryAnchor: state.contextMenuAnchors.secondaryAnchor,
      items: items,
    );
  }

  Future<void> _feedback(MsgRow m, ChatFeedbackVote vote) async {
    final result = await showMsgFeedbackSheet(
      context,
      conn: _conn,
      msgId: m.id,
      chatId: m.chatId,
      vote: vote,
      locale: CatalogTranslationCache.instance.lang,
    );
    if (!mounted || result == null) return;
    if (result.id.toInt() == 0) {
      _store.feedbackClear(m.id);
    } else {
      _store.feedbackReplace(result);
    }
    setState(() {});
  }

  Widget _chatHeader({required bool wide}) {
    final bar = SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (!wide)
              uiIconButton(
                tooltip: 'Chats',
                color: _muted,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            Expanded(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) => _activeChatTitleWidget(),
              ),
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
            ListenableBuilder(
              listenable: _store,
              builder: (context, _) {
                final summarized = (Session.instance.isRoot || Session.instance.isTester) && _activeChat?.contextSummaryPresent == true;
                if (!summarized) return const SizedBox.shrink();
                return Padding(
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
                );
              },
            ),
            if (!wide)
              uiIconButton(
                tooltip: 'New chat',
                color: _muted,
                icon: const Icon(Icons.add_rounded),
                onPressed: _newChat,
              ),
            Builder(builder: _chatHeaderAccountTrailing),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(color: _bg, border: Border(bottom: BorderSide(color: _border))),
      child: wide ? bar : uiMobileTopBar(context, bar),
    );
  }

  int get _contextLimit => contextWindowResolve(_model.contextTokens, _activeChat?.contextWindow ?? 0);

  int get _effectivePromptTokens {
    if (_promptTokens > 0) return _promptTokens;
    if (_usage.total > 0) return _usage.total;
    final activeId = _store.activeChatId;
    if (activeId != null && activeId > 0) {
      final saved = _store.chatPromptTokensGet(activeId);
      if (saved > 0) return saved;
    }
    if (_store.activeMsgs.isEmpty) return 0;
    var totalChars = 0;
    for (final m in _store.activeMsgs) {
      totalChars += m.content.length;
    }
    final est = (totalChars / 4.0).ceil();
    return est > 0 ? (est + 1500) : 0;
  }

  ContextUsageParts get _effectiveUsage {
    if (_usage.total > 0) return _usage;
    final total = _effectivePromptTokens;
    if (total <= 0) return const ContextUsageParts();
    final conv = (total - 1500).clamp(0, total);
    return ContextUsageParts(instructions: 1500, conversation: conv);
  }

  List<int> get _contextWindowOptions => contextWindowOptionsForModel(_model.contextTokens);

  ContextUsageParts _usageParts(ContextUsage u) => ContextUsageParts(
        instructions: u.instructions,
        memory: u.memory,
        context: u.context,
        tools: u.tools,
        conversation: u.conversation,
      );

  void _promptEstimateApply(int chatId, ResPromptEnd end) {
    if (end.contextWindow > 0) _store.chatContextWindowPut(chatId, end.contextWindow);
    final usageParts = end.hasUsage() ? _usageParts(end.usage) : null;
    final pt = usageParts != null && usageParts.total > 0 ? usageParts.total : end.promptTokens;
    if (pt > 0) _store.chatPromptTokensPut(chatId, pt);
    if (!mounted || _store.activeChatId != chatId) return;
    setState(() {
      if (usageParts != null) {
        _usage = usageParts;
        _promptTokens = _usage.total > 0 ? _usage.total : end.promptTokens;
      } else {
        _promptTokens = end.promptTokens;
        _usage = ContextUsageParts(conversation: end.promptTokens);
      }
    });
  }

  Future<void> _contextWindowSet(int window) async {
    final id = _store.activeChatId;
    if (id == null || id <= 0) return;
    try {
      final res = await _conn.chatContextWindowSet(chatId: id, contextWindow: window);
      final applied = res.contextWindow > 0 ? res.contextWindow : window;
      if (!mounted || _store.activeChatId != id) return;
      setState(() {
        _store.chatContextWindowPut(id, applied);
        _usage = _usage.copyConversation(res.promptTokens);
        _promptTokens = _usage.total;
        _store.chatPromptTokensPut(id, _promptTokens);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _chatCompact() async {
    final id = _store.activeChatId;
    if (id == null || id <= 0 || _summarizeChatId != null) return;
    setState(() => _summarizeChatId = id);
    try {
      final res = await _conn.chatCompact(chatId: id);
      if (res.title.isNotEmpty) _store.chatTitlePut(id, res.title);
      if (res.ran) _store.chatContextSummaryPresentPut(id, true);
      if (!mounted || _store.activeChatId != id) return;
      setState(() {
        _usage = _usage.copyConversation(res.promptTokens);
        _promptTokens = _usage.total;
        _store.chatPromptTokensPut(id, _promptTokens);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() { if (_summarizeChatId == id) _summarizeChatId = null; });
    }
  }

  int get _threadTokensIn => _store.activeMsgs.fold(0, (acc, m) => acc + m.tokensIn);
  int get _threadTokensOut => _store.activeMsgs.fold(0, (acc, m) => acc + m.tokensOut);
  double get _threadCostUsd => _store.activeMsgs.fold(0.0, (acc, m) => acc + m.costUsd);

  void _onTalkPrefs() {
    if (!VoicePrefs.instance.talkEnabled && _talkRecording) unawaited(_talkMicCancel());
  }

  void _onTalkLiveTranscript() {
    if (mounted) setState(() {});
  }

  void _onTalkSttUi() {
    if (mounted) setState(() {});
  }

  Future<void> _talkMic() async {
    if (_store.promptBusyFor(_store.activeChatId)) {
      await _abortPrompt();
      return;
    }
    if (_talkRecording) {
      await _talkMicStop();
      return;
    }
    await _talkMicStart();
  }

  Future<void> _talkMicStart() async {
    if (_talkMicStopInFlight) return;
    await TtsService.instance.stop();
    SttService.instance.liveTranscript.removeListener(_onTalkLiveTranscript);
    SttService.instance.liveTranscript.addListener(_onTalkLiveTranscript);
    SttService.instance.onAutoStop = () {
      if (mounted && _talkRecording) unawaited(_talkMicStop());
    };
    final ok = await SttService.instance.startRecording(vadMode: SttVadMode.talk);
    if (!mounted) return;
    if (!ok) {
      SttService.instance.onAutoStop = null;
      SttService.instance.liveTranscript.removeListener(_onTalkLiveTranscript);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SttService.instance.lastStartError ?? sttMicErrorMessage()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _talkRecording = true);
  }

  Future<void> _talkMicStop() async {
    if (!_talkRecording || _talkMicStopInFlight) return;
    _talkMicStopInFlight = true;
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onTalkLiveTranscript);
    if (mounted) setState(() => _talkRecording = false);
    try {
      final text = await SttService.instance.stopAndTranscribe(lang: VoicePrefs.instance.speechLang);
      if (!mounted) return;
      final transcript = (text ?? SttService.instance.liveTranscript.value).trim();
      if (transcript.isEmpty) {
        final err = SttService.instance.lastTranscribeError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err ?? 'No speech detected'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      final staged = List<StagedMedia>.from(_talkStaged);
      setState(() => _talkStaged.clear());
      final atts = await _talkAttachments(staged);
      if (!mounted) return;
      await _composerSend(transcript, atts, talk: true);
    } finally {
      _talkMicStopInFlight = false;
    }
  }

  Future<void> _talkMicCancel() async {
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onTalkLiveTranscript);
    _talkMicStopInFlight = false;
    if (_talkRecording) await SttService.instance.cancel();
    if (mounted) setState(() => _talkRecording = false);
  }

  Future<void> _talkUpload(StagedMedia item) async {
    if (item.bytes.isEmpty) return;
    try {
      final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
      if (!mounted || res == null) return;
      final i = _talkStaged.indexWhere((m) => m.id == item.id);
      if (i >= 0) setState(() => _talkStaged[i] = _talkStaged[i].copyWith(hash: res.hash, uploadProgress: 1.0));
    } catch (_) {}
  }

  void _talkStageItems(List<StagedMedia> items) {
    if (!mounted || items.isEmpty) return;
    setState(() => _talkStaged.addAll(items));
    for (final item in items) {
      unawaited(_talkUpload(item));
    }
  }

  Future<List<MsgAttachment>> _talkAttachments(List<StagedMedia> staged) async {
    final atts = <MsgAttachment>[];
    for (var item in staged) {
      if ((item.hash == null || item.hash!.isEmpty) && item.bytes.isNotEmpty) {
        final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
        if (res != null) item = item.copyWith(hash: res.hash, uploadProgress: 1.0);
      }
      if (item.bytes.isNotEmpty || (item.hash != null && item.hash!.isNotEmpty)) {
        atts.add(MsgAttachment.fromStaged(item));
      }
    }
    return atts;
  }

  Future<void> _talkAttachImage() async {
    final picked = await askMedia(context: context, types: const [MediaType.image], allowMultiple: true);
    if (picked != null) _talkStageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _talkAttachFile() async {
    final picked = await askMedia(context: context, types: const [MediaType.document, MediaType.any], allowMultiple: true);
    if (picked != null) _talkStageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _talkAttach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF27272A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFFA1A1AA)),
              title: const Text('Photo', style: TextStyle(color: Color(0xFFF4F4F5))),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded, color: Color(0xFFA1A1AA)),
              title: const Text('File', style: TextStyle(color: Color(0xFFF4F4F5))),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'image') await _talkAttachImage();
    if (action == 'file') await _talkAttachFile();
  }

  Future<void> _talkModel() async {
    final next = await agentModelPick(context, _model, _store.models, modelsLoading: !_modelsReady);
    if (next != null) _modelPut(next);
  }

  Widget _talkStage() {
    final msgs = _store.activeMsgs;
    MsgRow? assistant;
    MsgRow? user;
    for (final m in msgs.reversed) {
      if (assistant == null && m.role == 'assistant') assistant = m;
      if (user == null && m.role == 'user') user = m;
      if (assistant != null && user != null) break;
    }
    final liveStt = _talkRecording || SttService.instance.isTranscribing.value;
    final userText = liveStt
        ? SttService.instance.liveTranscript.value
        : (user == null
            ? ''
            : msgUserContentForDisplay(
                content: user.content,
                mentionIdsJson: user.mentionIdsJson,
                mentions: _store.mentionCatalog.mentions,
              ));
    final busy = _store.promptBusyFor(_store.activeChatId);
    final stopping = _store.promptStopping;
    final showWelcome = user == null && assistant == null && !busy && !stopping;
    return UiTalkStage(
      assistant: assistant,
      userText: userText,
      welcome: showWelcome ? _threadHero() : null,
      listening: _talkRecording,
      transcribing: SttService.instance.isTranscribing.value,
      busy: busy,
      stopping: stopping,
      busyStartedAtMs: (busy || stopping) ? _store.promptStartedAtMs : null,
      onStopPrompt: stopping ? null : _abortPrompt,
      speakEnabled: VoicePrefs.instance.talkSpeakEnabled,
      onMic: () => unawaited(_talkMic()),
      onSendTranscript: _talkRecording && !_talkMicStopInFlight ? () => unawaited(_talkMicStop()) : null,
      onSpeak: () => unawaited(VoicePrefs.instance.setTalkSpeakEnabled(!VoicePrefs.instance.talkSpeakEnabled)),
      onAttach: () => unawaited(_talkAttach()),
      onModel: () => unawaited(_talkModel()),
      mentionLabel: _primaryMentionLabel(),
      onMentionClear: _mentionIds.isEmpty ? null : () => _mentionToggle(_mentionIds.first),
      blocks: assistant == null ? const <ChatBlock>[] : ChatBlock.decodeList(assistant.blocksJson),
      usage: assistant == null ? null : msgUsageStats(assistant),
      consumptionApi: _consumptionApi,
      expenseApi: _expenseApi,
      locale: CatalogTranslationCache.instance.lang,
      onConsumptionSaved: _onConsumptionBlockSaved,
      onExpenseSaved: _onExpenseBlockSaved,
      onBlockCollapsedChanged: (msgId, blockIndex, collapsed) =>
          _store.msgBlockCollapsedPut(msgId: msgId, blockIndex: blockIndex, collapsed: collapsed),
      onImageUpgradeHd: busy ? null : _imageUpgradeHd,
      stagedCount: _talkStaged.length,
      modelProvider: _model.provider,
      modelAccent: _model.accent,
      model: _model,
    );
  }

  Widget _chatComposer() => RepaintBoundary(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, uiSafeBottomInset(context, 16)),
          child: InComposer(
              key: const ValueKey('chat_composer'),
              stageHost: _composerStageHost,
              draftHost: _composerDraftHost,
              onDraftChanged: _composerDraftScheduleSave,
              controller: _composerCtrl,
              focusNode: _composerFocus,
              model: _model,
              models: _store.models,
              modelsLoading: !_modelsReady,
              onModel: _modelPut,
              mentions: _store.mentionCatalog.mentions
                  .where((m) => !m.rootOnly || Session.instance.isRoot)
                  .toList(growable: false),
              viewerIsRoot: Session.instance.isRoot,
              onTestMultitask: Session.instance.isRoot ? _runTestMultitask : null,
              selectedMentionIds: _mentionIds,
              toolMode: _toolMode,
              onMentionToggle: _mentionToggle,
              onToolModeToggle: _toolModeToggle,
              promptHistory: _store.recentUserPrompts,
              onNewChat: _newChat,
              onSend: (text, atts, {toolMode, mentionIds, displayContent}) => _composerSend(text, atts, toolMode: toolMode, mentionIds: mentionIds, displayContent: displayContent),
              onAbort: _store.promptBusyFor(_store.activeChatId) ? _abortPrompt : null,
              busy: _store.promptBusyFor(_store.activeChatId),
              followupRows: promptFollowupQueueRows(PromptFollowupStore.instance.items),
              onFollowupSteer: _followupSteer,
              onFollowupRemove: _followupRemove,
              enabled: _catalogReady,
            ),
        ),
      );

  Widget _chatColumn({required bool wide}) => ComposerStage(
        host: _composerStageHost,
        child: Column(
        children: [
          RepaintBoundary(child: _chatHeader(wide: wide)),
          Expanded(
            child: ListenableBuilder(
              listenable: VoicePrefs.instance,
              builder: (context, _) {
                if (!VoicePrefs.instance.talkEnabled) {
                  return Column(
                    children: [
                      Expanded(child: RepaintBoundary(child: _threadBody())),
                      _HomeChatComposer(home: this),
                    ],
                  );
                }
                return _talkStage();
              },
            ),
          ),
        ],
      ),
      );

  String _plainForMsg(MsgRow m) {
    final parts = <String>[];
    var content = msgDisplayContent(m).trim();
    if (m.role == 'user' && composerMentionTextHasTokens(content)) {
      content = composerMentionTextForPrompt(content, _store.mentionCatalog.mentions, mentionIds: composerMentionIdsParse(content));
    }
    if (content.isNotEmpty) parts.add(content);
    if (m.thought.trim().isNotEmpty) parts.add(msgThoughtStripPlaceholders(m.thought));
    return parts.join('\n\n');
  }

  List<SlideDeckData?> _presentationDecksForThread(List<MsgRow> msgs, int chatId) {
    final rev = _store.msgsRevision;
    if (_presentationDecksCache != null && _presentationDecksRev == rev && _presentationDecksChatId == chatId) {
      return _presentationDecksCache!;
    }
    final out = _presentationDecksBefore(msgs, chatId);
    _presentationDecksRev = rev;
    _presentationDecksChatId = chatId;
    _presentationDecksCache = out;
    return out;
  }

  List<SlideDeckData?> _presentationDecksBefore(List<MsgRow> msgs, int chatId) {
    final out = List<SlideDeckData?>.filled(msgs.length, null, growable: false);
    SlideDeckData? deck;
    final themeOverride = SlideDeckThemePrefs.instance.themeFor(chatId);
    for (var j = 0; j < msgs.length; j++) {
      out[j] = deck;
      final row = msgs[j];
      if (row.role != 'assistant') continue;
      for (final b in ChatBlock.decodeList(row.blocksJson)) {
        switch (b.kind) {
          case 'presentation.deck':
          case 'slide.deck':
          case 'presentation':
            deck = SlideDeckData.fromBlockBody(b.body, deck);
            if (themeOverride != null) deck.theme = themeOverride;
        }
      }
    }
    return out;
  }

  Widget _msgTile(
    MsgRow m, {
    required int i,
    required int count,
    required int lastAssistantIdx,
    SlideDeckData? presentationDeckPrior,
  }) {
    final isUser = m.role == 'user';
    final liveReqId = _store.promptLiveReqId ?? _store.pendingPromptReqId ?? '';
    final stoppingThis = !isUser && _store.promptStopping && m.reqId.isNotEmpty && m.reqId == (_store.promptStoppingReqId ?? '');
    final promptingThis = !isUser &&
        m.reqId.isNotEmpty &&
        m.reqId == liveReqId &&
        (_store.promptBusyFor(m.chatId) || stoppingThis);
    final usageStreaming = !isUser && msgUsageStreaming(busy: _store.promptBusyFor(m.chatId), msgReqId: m.reqId, liveReqId: liveReqId);
    final copyHeader = msgCopyHeader(
      role: m.role,
      userName: Session.instance.name,
      createdAtMs: m.createdAtMs,
      modelId: isUser ? '' : (m.model.isNotEmpty ? m.model : _model.id),
      models: _store.models,
    );
    final copyGap = i > 0 ? 2 : 0;

    Widget body;
    if (isUser) {
      final catalogMentions = _store.mentionCatalog.mentions;
      final userContent = msgUserContentForDisplay(
        content: m.content,
        mentionIdsJson: m.mentionIdsJson,
        mentions: catalogMentions,
      );
      body = UiUserBubble(content: userContent, copyPrefix: copyHeader, leadingNewlines: copyGap, attachments: m.attachments, mentions: catalogMentions);
    } else {
      var content = msgDisplayContent(m);
      var err = msgRowError(m).trim();
      if (err.isEmpty && uiIsTechnicalError(content.trim())) {
        err = content.trim();
        content = '';
      }
      final hasError = err.isNotEmpty;
      final inThoughtPhase = promptingThis && content.trim().isEmpty && !hasError && !stoppingThis;
      final showTraceChips = m.reqId.isNotEmpty;
      final blocks = ChatBlock.decodeList(m.blocksJson);
      final hasAnswerBody = content.trim().isNotEmpty || blocks.isNotEmpty;
      final showFatalError = hasError && !hasAnswerBody && !uiIsRecoverableDeviceContextError(err);
      final locale = CatalogTranslationCache.instance.lang;
      final showRetry = hasError && !_store.promptBusyFor(m.chatId) && i == lastAssistantIdx;
      final thoughtView = msgThoughtView(
        thought: m.thought,
        content: content,
        thinking: inThoughtPhase,
      );
      final showThought = stoppingThis || inThoughtPhase || (thoughtView.thought != null && thoughtView.thought!.isNotEmpty);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiMsgCopyPrefix(text: copyHeader, leadingNewlines: copyGap),
          if (showThought)
            UiMsgThought(
              text: stoppingThis ? 'Stopping…' : (thoughtView.thought ?? ''),
              thinking: inThoughtPhase,
              stopping: stoppingThis,
              startedAtMs: promptingThis ? _store.promptStartedAtMs : null,
              liveLabel: inThoughtPhase
                  ? msgThoughtLiveStatusLabel(thought: m.thought, defaultLabel: _model.thinkingStatusLabel)
                  : null,
              onStop: promptingThis && !stoppingThis ? _abortPrompt : null,
            ),
          if (showTraceChips)
            UiMsgTraceLoader(
              conn: _conn,
              reqId: m.reqId,
              live: promptingThis,
              part: MsgTracePart.chips,
            ),
          _subagentRunCards(m),
          if (showFatalError)
            UiMsgError(
              message: msgPromptErrorMessage(err),
              detail: sessionViewerIsRoot() ? err : null,
              msgId: m.id,
              reqId: m.reqId,
              onRetry: showRetry ? () => unawaited(_retryLastTurn(m.chatId)) : null,
              retrying: _retrying,
            )
          else if (content.trim().isNotEmpty)
            UiMarkdownBody(
              data: content,
              selectable: false,
              styleSheet: uiMarkdownChatStyleSheet(
                p: const TextStyle(color: _text, fontSize: 15, height: 1.45),
                code: const TextStyle(color: _text, fontSize: 13, fontFamily: 'Consolas', backgroundColor: Color(0xFF1A1A1D)),
              ),
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
          if (hasError && hasAnswerBody && !uiIsRecoverableDeviceContextError(err))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: UiMsgError(
                message: msgPromptErrorMessage(err),
                detail: sessionViewerIsRoot() ? err : null,
                msgId: m.id,
                reqId: m.reqId,
                onRetry: showRetry ? () => unawaited(_retryLastTurn(m.chatId)) : null,
                retrying: _retrying,
                showIcon: false,
              ),
            ),
          if ((!hasError || hasAnswerBody) && blocks.isNotEmpty)
            UiMsgBlocks(
              msgId: m.id,
              blocks: blocks,
              chatId: m.chatId,
              presentationDeckPrior: presentationDeckPrior,
              chatConn: _conn,
              consumptionApi: _consumptionApi,
              expenseApi: _expenseApi,
              locale: locale,
              primary: content.trim().isEmpty && !showFatalError,
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
              final feedback = _store.feedbackFor(m.id);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiMsgUsageWithTrace(
                    conn: _conn,
                    msg: m,
                    streaming: usageStreaming,
                    billingCurrency: AppStore.instance.wallet.billingCurrency,
                    fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
                  ),
                  if (feedback != null) UiMsgFeedbackThread(feedback: feedback),
                ],
              );
            }),
        ],
      );
    }

    return RepaintBoundary(
      child: Align(
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
      ),
    );
  }

  Future<void> _retryLastTurn(int chatId) async {
    if (_retrying || chatId == 0) return;
    ContextMenuController.removeAny();
    if (_store.activeChatId != chatId) _store.chatSelect(chatId);
    final turn = _store.retryLastTurnPrep(chatId: chatId);
    if (turn == null) return;
    final mentions = _store.mentionCatalog.mentions;
    final mentionIds = composerMentionIdsCollect(turn.text);
    final displayContent = composerMentionDisplayRestore(turn.text, mentions, mentionIds: mentionIds);
    setState(() => _retrying = true);
    try {
      await _composerSend(
        turn.text,
        turn.attachments,
        retry: true,
        retryChatId: chatId,
        mentionIds: mentionIds,
        displayContent: displayContent,
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  void _liveCallStart(LiveOffer offer) {
    if (_talkRecording) {
      unawaited(_talkMicCancel());
    } else if (SttService.instance.isRecording.value) {
      unawaited(SttService.instance.cancel());
    }
    unawaited(
      openPageLiveCall(
        context: context,
        conn: _conn,
        offer: offer,
        chatId: _store.activeChatId,
        chatStore: _store,
        mentionIds: _mentionIds.toList(),
        mentionLabel: _primaryMentionLabel(),
        onMentions: (ids) {
          if (!mounted) return;
          setState(() {
            _mentionIds
              ..clear()
              ..addAll(ids);
          });
          final chatId = _store.activeChatId;
          if (chatId != null) _store.chatStickyMentionsPut(chatId, ids);
        },
      ),
    );
  }

  Widget _threadHero() => ListenableBuilder(
        listenable: Listenable.merge([HintStore.instance, _store]),
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
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      UiLiveCallChip(composerModel: _model, offers: _store.liveOffers, onStart: _liveCallStart),
                      if (hints.isNotEmpty) UiHints(hints: hints, onPick: _hintPick),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _jumpToLatestButton(int unread) {
    final tooltip = unread > 0 ? '$unread new message${unread > 1 ? 's' : ''}' : 'Jump to latest';
    return uiIconButton(
      tooltip: tooltip,
      color: _muted,
      icon: const Icon(Icons.arrow_downward_rounded),
      onPressed: () => _timeline.scrollToBottom(force: true, animate: true),
    );
  }

  Widget _threadThinkingTail() => UiPromptThinkingIndicator(
        startedAtMs: _store.promptStartedAtMs,
        model: _model,
        stopping: _store.promptStopping,
        onStop: _store.promptStopping ? null : _abortPrompt,
      );

  Widget _threadBody() => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final msgs = _store.activeMsgs;
          if (_store.activeChatId == null && msgs.isEmpty) return _threadHero();
          if (msgs.isEmpty) return _threadHero();
          final cid = _store.activeChatId;
          final showThinkingTail = cid != null &&
              !_store.threadPromptLiveVisible(cid) &&
              (_store.promptBusyFor(cid) || (_store.promptStopping && _store.promptChatId == cid));
          final itemCount = msgs.length + (showThinkingTail ? 1 : 0);
          final lastAssistantIdx = msgs.lastIndexWhere((x) => x.role == 'assistant');
          final decksBefore = cid == null ? const <SlideDeckData?>[] : _presentationDecksForThread(msgs, cid);
          final timeline = UiChatTimeline(
            key: ValueKey(_store.activeChatId ?? 'hero'),
            controller: _timeline,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: itemCount,
            itemBuilder: (context, i) {
              if (showThinkingTail && i >= msgs.length) return _threadThinkingTail();
              if (i >= msgs.length) return const SizedBox.shrink();
              final m = msgs[i];
              return Listener(
                onPointerDown: (_) => _menuMsgIndex = i,
                child: KeyedSubtree(
                  key: ValueKey(msgTileKey(m)),
                  child: _msgTile(
                    m,
                    i: i,
                    count: msgs.length,
                    lastAssistantIdx: lastAssistantIdx,
                    presentationDeckPrior: i < decksBefore.length ? decksBefore[i] : null,
                  ),
                ),
              );
            },
          );
          final threadList = SelectionArea(
            onSelectionChanged: (c) => _selectedPlain = c?.plainText,
            contextMenuBuilder: _threadContextMenu,
            child: timeline,
          );
          return Stack(
            children: [
              Positioned.fill(child: threadList),
              Positioned(
                bottom: uiSafeBottomInset(context, 12),
                right: 20,
                child: ListenableBuilder(
                  listenable: Listenable.merge([_timeline.isAtBottom, _timeline.unreadStreamCount]),
                  builder: (ctx, _) {
                    if (_timeline.isAtBottom.value) return const SizedBox.shrink();
                    return _jumpToLatestButton(_timeline.unreadStreamCount.value);
                  },
                ),
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return UiPosLinkHost(
      chatConn: _conn,
      child: ListenableBuilder(
        listenable: _canvasStore,
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
                        RepaintBoundary(
                          child: SizedBox(
                            width: 280,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(border: Border(right: BorderSide(color: _border))),
                              child: _historySidebar(),
                            ),
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
      ),
    );
  }
}

/// App-bar wifi, context meter, and account control — isolated from full header rebuilds.
class _HomeChatHeaderAccountTrailing extends StatelessWidget {
  const _HomeChatHeaderAccountTrailing({super.key, required this.menuCtx, required this.home});

  final BuildContext menuCtx;
  final _PageAIHomeState home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([home._store, PromptUsagePrefs.instance]),
        builder: (context, _) {
          final h = home;
          final threadTokensIn = h._threadTokensIn;
          final threadTokensOut = h._threadTokensOut;
          final threadTotal = threadTokensIn + threadTokensOut;
          final showMeter = (Session.instance.isRoot || Session.instance.isTester) &&
              PromptUsagePrefs.instance.showUsageStats &&
              (threadTotal > 0 || h._effectivePromptTokens > 0);
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UiConnWifi(conn: h._conn, onReconnect: h._connConnect),
              const SizedBox(width: 6),
              if (showMeter)
                UiContextMeter(
                  key: const ValueKey('chat_context_meter'),
                  promptTokens: h._effectivePromptTokens,
                  usage: h._effectiveUsage,
                  tokensIn: threadTokensIn,
                  tokensOut: threadTokensOut,
                  costUsd: h._threadCostUsd,
                  contextLimit: h._contextLimit,
                  windowOptions: h._contextWindowOptions,
                  onWindowSelected: h._contextWindowSet,
                  onSummarize: h._chatCompact,
                  summarizeBusy: h._summarizeChatId != null && h._summarizeChatId == h._store.activeChatId,
                  billingCurrency: AppStore.instance.wallet.billingCurrency,
                  fxMicroPerUsd: AppStore.instance.wallet.fxMicroPerUsd,
                  tapPadding: const EdgeInsets.fromLTRB(4, 6, 2, 6),
                )
              else
                const UiAppBarVersionLabel(),
              SizedBox(width: showMeter ? 10 : 6),
              UiAccountBtn(
                tooltip: 'Account',
                onTap: () => h._avatarMenu(menuCtx),
                child: UiUserAvatar(
                  name: Session.instance.name,
                  email: Session.instance.email,
                  handle: Session.instance.handle,
                  pic: Session.instance.pic,
                  size: 28,
                ),
              ),
            ],
          );
        },
      );
}

/// Composer isolated from chat-thread [ChatStore] updates (streaming, sync) so typing stays smooth.
class _HomeChatComposer extends StatefulWidget {
  const _HomeChatComposer({required this.home});

  final _PageAIHomeState home;

  @override
  State<_HomeChatComposer> createState() => _HomeChatComposerState();
}

class _HomeChatComposerState extends State<_HomeChatComposer> {
  late VoidCallback _onStore;
  late VoidCallback _onMentions;
  late VoidCallback _onFollowups;

  var _busy = false;
  var _catalogReady = false;
  var _modelsReady = false;
  var _mentionRev = -1;
  var _followupCount = -1;
  var _modelsLen = -1;
  var _activeChatId = -2;
  var _modelId = '';
  var _mentionKey = '';
  var _promptHistoryLen = -1;

  @override
  void initState() {
    super.initState();
    final h = widget.home;
    _onStore = () => _syncFromStore();
    _onMentions = () => _syncFromStore();
    _onFollowups = () => _syncFromStore(followupsOnly: true);
    h._store.addListener(_onStore);
    h._store.mentionCatalog.addListener(_onMentions);
    PromptFollowupStore.instance.addListener(_onFollowups);
    _syncFromStore(force: true);
  }

  @override
  void dispose() {
    final h = widget.home;
    h._store.removeListener(_onStore);
    h._store.mentionCatalog.removeListener(_onMentions);
    PromptFollowupStore.instance.removeListener(_onFollowups);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromStore();
  }

  void _syncFromStore({bool force = false, bool followupsOnly = false}) {
    if (!mounted) return;
    final h = widget.home;
    final cid = h._store.activeChatId;
    final busy = h._store.promptBusyFor(cid);
    final mentionRev = h._store.mentionCatalog.rev;
    final followupCount = PromptFollowupStore.instance.items.length;
    final modelsLen = h._store.models.length;
    final modelId = h._model.id;
    final catalogReady = h._catalogReady;
    final modelsReady = h._modelsReady;
    final mentionKey = h._mentionIds.join(',');
    final promptHistoryLen = busy ? _promptHistoryLen : h._store.recentUserPrompts.length;

    if (!force &&
        !followupsOnly &&
        busy == _busy &&
        catalogReady == _catalogReady &&
        modelsReady == _modelsReady &&
        mentionRev == _mentionRev &&
        followupCount == _followupCount &&
        modelsLen == _modelsLen &&
        cid == _activeChatId &&
        modelId == _modelId &&
        mentionKey == _mentionKey &&
        promptHistoryLen == _promptHistoryLen) {
      return;
    }
    if (followupsOnly && followupCount == _followupCount) return;

    _busy = busy;
    _catalogReady = catalogReady;
    _modelsReady = modelsReady;
    _mentionRev = mentionRev;
    _followupCount = followupCount;
    _modelsLen = modelsLen;
    _activeChatId = cid ?? -1;
    _modelId = modelId;
    _mentionKey = mentionKey;
    _promptHistoryLen = promptHistoryLen;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.home._chatComposer();
}
