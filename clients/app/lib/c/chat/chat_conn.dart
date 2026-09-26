import 'dart:async';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/catalog.pb.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/pb/c35/log.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ChatConnStatus { disconnected, connecting, connected, reconnecting }

class PromptStreamEvent {
  const PromptStreamEvent._({
    required this.kind,
    this.chatId = Int64.ZERO,
    this.msgId = Int64.ZERO,
    this.model = '',
    this.text = '',
    this.thought = false,
    this.blocksJson = '',
    this.message = '',
    this.end,
  });

  factory PromptStreamEvent.start({required Int64 chatId, required Int64 msgId, required String model}) => PromptStreamEvent._(
        kind: 'start',
        chatId: chatId,
        msgId: msgId,
        model: model,
      );

  factory PromptStreamEvent.delta({required String text, required bool thought, String blocksJson = ''}) => PromptStreamEvent._(
        kind: 'delta',
        text: text,
        thought: thought,
        blocksJson: blocksJson,
      );

  factory PromptStreamEvent.end(ResPromptEnd end) => PromptStreamEvent._(
        kind: 'end',
        msgId: end.msgId,
        model: end.model,
        end: end,
      );

  factory PromptStreamEvent.fail(String message) => PromptStreamEvent._(kind: 'fail', message: message);

  final String kind;
  final Int64 chatId;
  final Int64 msgId;
  final String model;
  final String text;
  final bool thought;
  final String blocksJson;
  final String message;
  final ResPromptEnd? end;
}

class ChatConn {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  var _manualDisconnect = false;
  var _retryCount = 0;
  var _locale = 'en';
  var _tz = '';
  final status = ValueNotifier<ChatConnStatus>(ChatConnStatus.disconnected);
  final _reconnectedCtrl = StreamController<void>.broadcast();
  final _promptPending = <String, StreamController<PromptStreamEvent>>{};
  final _rpcPending = <String, Completer<WsRes>>{};
  final _syncPushCtrl = StreamController<SyncPush>.broadcast();
  final _billingBalanceCtrl = StreamController<BillingPushBalance>.broadcast();
  final _billingQuotaCtrl = StreamController<BillingPushQuota>.broadcast();
  final _billingCommissionCtrl = StreamController<BillingPushCommission>.broadcast();
  final _channelPairPushCtrl = StreamController<ChannelPairPush>.broadcast();
  final _remoteSignalCtrl = StreamController<WsRes>.broadcast();
  final _statsPushCtrl = StreamController<StatsPush>.broadcast();
  final _logPushCtrl = StreamController<LogPush>.broadcast();
  final _promptRunPushCtrl = StreamController<PromptRunPush>.broadcast();
  final _promptFollowupPushCtrl = StreamController<PromptFollowupPush>.broadcast();
  final _traceCache = <String, List<TraceLogDoc>>{};
  final _traceCacheCtrl = StreamController<String>.broadcast();

  Stream<SyncPush> get onSyncPush => _syncPushCtrl.stream;
  Stream<String> get onTraceCachePut => _traceCacheCtrl.stream;
  Stream<ChannelPairPush> get onChannelPairPush => _channelPairPushCtrl.stream;
  Stream<WsRes> get onRemoteSignal => _remoteSignalCtrl.stream;
  Stream<BillingPushBalance> get onBillingBalance => _billingBalanceCtrl.stream;
  Stream<BillingPushQuota> get onBillingQuota => _billingQuotaCtrl.stream;
  Stream<BillingPushCommission> get onBillingCommission => _billingCommissionCtrl.stream;
  Stream<StatsPush> get onStatsPush => _statsPushCtrl.stream;
  Stream<LogPush> get onLogPush => _logPushCtrl.stream;
  Stream<PromptRunPush> get onPromptRunPush => _promptRunPushCtrl.stream;
  Stream<PromptFollowupPush> get onPromptFollowupPush => _promptFollowupPushCtrl.stream;
  Stream<void> get onReconnected => _reconnectedCtrl.stream;

  bool get connected => _ch != null;

  String _wsUrl({String locale = 'en', String tz = ''}) {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final u = Uri.parse(base);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    final token = Session.instance.token.trim();
    return Uri(
      scheme: scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: '/v1/ws',
      queryParameters: {
        'jwt': token,
        if (locale.isNotEmpty) 'locale': locale,
        if (tz.isNotEmpty) 'tz': tz,
      },
    ).toString();
  }

  Future<void> connect({String locale = 'en', String tz = ''}) async {
    _manualDisconnect = false;
    _locale = locale;
    _tz = tz;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    status.value = ChatConnStatus.connecting;
    await _tearDownSocket(failPending: true);
    _attachSocket(locale: locale, tz: tz);
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    await _tearDownSocket(failPending: true);
    status.value = ChatConnStatus.disconnected;
  }

  Future<void> _tearDownSocket({required bool failPending}) async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;
    if (!failPending) return;
    for (final c in _promptPending.values) {
      if (!c.isClosed) c.add(PromptStreamEvent.fail('disconnected'));
      await c.close();
    }
    _promptPending.clear();
    for (final c in _rpcPending.values) {
      if (!c.isCompleted) c.completeError('disconnected');
    }
    _rpcPending.clear();
  }

  void _attachSocket({required String locale, String tz = ''}) {
    final token = Session.instance.token.trim();
    if (token.isEmpty) throw 'not signed in';
    _ch = WebSocketChannel.connect(Uri.parse(_wsUrl(locale: locale, tz: tz)));
    _sub = _ch!.stream.listen(_onData, onError: _onWsError, onDone: _onWsDone);
  }

  void _onWsError(Object e) {
    lError('chat ws: $e');
    _failAll('$e');
    _scheduleReconnectIfNeeded();
  }

  void _onWsDone() {
    _failAll('connection closed');
    _scheduleReconnectIfNeeded();
  }

  void _scheduleReconnectIfNeeded() {
    if (_manualDisconnect) {
      status.value = ChatConnStatus.disconnected;
      return;
    }
    if (_reconnectTimer != null) return;
    status.value = ChatConnStatus.reconnecting;
    _retryCount++;
    // Exponential backoff capped at 30 seconds to prevent socket exhaustion
    final sec = (1 << (_retryCount - 1).clamp(0, 5)).clamp(1, 30);
    final delay = Duration(seconds: sec);
    l('chat ws reconnect attempt $_retryCount in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (_manualDisconnect) return;
      try {
        status.value = ChatConnStatus.connecting;
        await _tearDownSocket(failPending: false);
        _attachSocket(locale: _locale, tz: _tz);
      } catch (e) {
        lError('chat ws reconnect: $e');
        _scheduleReconnectIfNeeded();
      }
    });
  }

  void _send(WsReq req) => _ch!.sink.add(req.writeToBuffer());

  Future<T> _rpc<T>(WsReq req, T Function(WsRes res) parse) async {
    if (_ch == null) await connect();
    final reqId = req.reqId.isNotEmpty ? req.reqId : const Uuid().v4();
    req.reqId = reqId;
    final completer = Completer<WsRes>();
    _rpcPending[reqId] = completer;
    _send(req);
    final res = await completer.future;
    return parse(res);
  }

  void _rpcComplete(String reqId, WsRes res) {
    final c = _rpcPending.remove(reqId);
    if (c == null || c.isCompleted) return;
    if (res.hasErr()) {
      final err = res.err;
      c.completeError(err.message.isNotEmpty ? err.message : err.code);
      return;
    }
    c.complete(res);
  }

  void _onData(dynamic data) {
    if (data is! List<int>) return;
    if (status.value != ChatConnStatus.connected || _retryCount > 0) {
      final wasReconnecting = _retryCount > 0 || status.value == ChatConnStatus.reconnecting;
      _retryCount = 0;
      status.value = ChatConnStatus.connected;
      if (wasReconnecting && !_reconnectedCtrl.isClosed) {
        _reconnectedCtrl.add(null);
      }
    }
    final res = WsRes.fromBuffer(data);
    final reqId = res.reqId;

    if (res.hasSyncPush()) {
      if (!_syncPushCtrl.isClosed) _syncPushCtrl.add(res.syncPush);
    }
    if (res.hasBillingBalance() && !_billingBalanceCtrl.isClosed) _billingBalanceCtrl.add(res.billingBalance);
    if (res.hasBillingQuota() && !_billingQuotaCtrl.isClosed) _billingQuotaCtrl.add(res.billingQuota);
    if (res.hasBillingCommission() && !_billingCommissionCtrl.isClosed) _billingCommissionCtrl.add(res.billingCommission);
    if (res.hasChannelPairPush() && !_channelPairPushCtrl.isClosed) _channelPairPushCtrl.add(res.channelPairPush);
    if (res.hasStatsPush() && !_statsPushCtrl.isClosed) _statsPushCtrl.add(res.statsPush);
    if (res.hasLogPush() && !_logPushCtrl.isClosed) _logPushCtrl.add(res.logPush);
    if (res.hasPromptRunPush()) {
      final push = res.promptRunPush;
      PromptRunStore.instance.put(push);
      if (!_promptRunPushCtrl.isClosed) _promptRunPushCtrl.add(push);
    }
    if (res.hasPromptFollowupPush()) {
      final push = res.promptFollowupPush;
      if (!_promptFollowupPushCtrl.isClosed) _promptFollowupPushCtrl.add(push);
    }
    if (_isRemoteSignal(res) && !_remoteSignalCtrl.isClosed) _remoteSignalCtrl.add(res);

    if (res.hasErr() && reqId.isNotEmpty) {
      final prompt = _promptPending[reqId];
      if (prompt != null && !prompt.isClosed) {
        final err = res.err;
        prompt.add(PromptStreamEvent.fail(err.message.isNotEmpty ? err.message : err.code));
        unawaited(prompt.close());
        _promptPending.remove(reqId);
        return;
      }
      if (_rpcPending.containsKey(reqId)) {
        _rpcComplete(reqId, res);
        return;
      }
    }

    final ctrl = _promptPending[reqId];
    if (ctrl != null && !ctrl.isClosed) {
      if (res.hasPromptStart()) {
        final s = res.promptStart;
        ctrl.add(PromptStreamEvent.start(chatId: s.chatId, msgId: s.msgId, model: s.model));
        return;
      }
      if (res.hasPromptDelta()) {
        final d = res.promptDelta;
        ctrl.add(PromptStreamEvent.delta(text: d.text, thought: d.thought, blocksJson: d.blocksJson));
        return;
      }
      if (res.hasPromptEnd()) {
        ctrl.add(PromptStreamEvent.end(res.promptEnd));
        unawaited(ctrl.close());
        _promptPending.remove(reqId);
        return;
      }
      if (res.hasPromptFail()) {
        ctrl.add(PromptStreamEvent.fail(res.promptFail.message));
        unawaited(ctrl.close());
        _promptPending.remove(reqId);
        return;
      }
    }

    if (reqId.isNotEmpty && _rpcPending.containsKey(reqId)) {
      if (res.hasPromptFail()) {
        final c = _rpcPending.remove(reqId);
        c?.completeError(res.promptFail.message);
        return;
      }
      if (!res.hasPromptStart() && !res.hasPromptDelta() && !res.hasPromptEnd()) {
        _rpcComplete(reqId, res);
      }
    }
  }

  void _failAll(String message) {
    for (final e in _promptPending.entries) {
      if (!e.value.isClosed) e.value.add(PromptStreamEvent.fail(message));
      e.value.close();
    }
    _promptPending.clear();
    for (final c in _rpcPending.values) {
      if (!c.isCompleted) c.completeError(message);
    }
    _rpcPending.clear();
    _sub?.cancel();
    _sub = null;
    try {
      _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  Future<ResSessionInit> sessionInit({
    Int64 sinceMs = Int64.ZERO,
    String locale = 'en',
    String tz = '',
    String locationCity = '',
    String locationRegion = '',
    String locationCountry = '',
    String locationSource = '',
    String dv = '',
    String clientId = '',
    int platform = 0,
    bool includeInbox = true,
    bool includeBilling = false,
    Int64 hintsSinceMs = Int64.ZERO,
  }) =>
      _rpc<ResSessionInit>(
        WsReq(
          sessionInit: ReqSessionInit(
            sinceMs: sinceMs,
            locale: locale,
            tz: tz,
            locationCity: locationCity,
            locationRegion: locationRegion,
            locationCountry: locationCountry,
            locationSource: locationSource,
            dv: dv,
            clientId: clientId,
            platform: platform,
            includeInbox: includeInbox,
            includeBilling: includeBilling,
            hintsSinceMs: hintsSinceMs,
          ),
        ),
        (res) => res.sessionInit,
      );

  Future<ResHintTouch> hintTouch({required Int64 assetIid, required String assetKind}) => _rpc<ResHintTouch>(
        WsReq(hintTouch: ReqHintTouch(assetIid: assetIid, assetKind: assetKind)),
        (res) => res.hintTouch,
      );

  Future<ResInboxList> inboxList({bool includeArchived = false, int limit = 100}) => _rpc<ResInboxList>(
        WsReq(inboxList: ReqInboxList(includeArchived: includeArchived, limit: limit)),
        (res) => res.inboxList,
      );

  Future<ResChatMsgList> chatMsgList({required Int64 chatId, Int64 beforeId = Int64.ZERO, int limit = 100}) => _rpc<ResChatMsgList>(
        WsReq(chatMsgList: ReqChatMsgList(chatId: chatId, beforeId: beforeId, limit: limit)),
        (res) => res.chatMsgList,
      );

  Future<ResChatHistoryClear> chatHistoryClear({bool dryRun = false}) => _rpc<ResChatHistoryClear>(
        WsReq(chatHistoryClear: ReqChatHistoryClear(dryRun: dryRun)),
        (res) => res.chatHistoryClear,
      );

  Future<ResChatPatch> chatPatch({
    required Int64 chatId,
    bool? pinned,
    bool? archived,
    List<String>? tags,
    bool? deleted,
  }) async {
    final req = ReqChatPatch(chatId: chatId);
    if (pinned != null) req.pinned = pinned;
    if (archived != null) req.archived = archived;
    if (tags != null) req.tags = TagSet(tags: tags);
    if (deleted != null) req.deleted = deleted;
    return _rpc<ResChatPatch>(
      WsReq(chatPatch: req),
      (res) => res.chatPatch,
    );
  }

  Future<ResAssetTagList> assetTagList({required String kind, String prefix = '', int limit = 20}) => _rpc<ResAssetTagList>(
        WsReq(assetTagList: ReqAssetTagList(kind: kind, prefix: prefix, limit: limit)),
        (res) => res.assetTagList,
      );

  List<TraceLogDoc> traceCacheGet(String reqId) => _traceCache[reqId] ?? const [];

  void traceCachePut(String reqId, List<TraceLogDoc> logs) {
    if (reqId.isEmpty || logs.isEmpty) return;
    _traceCache[reqId] = logs;
    if (!_traceCacheCtrl.isClosed) _traceCacheCtrl.add(reqId);
  }

  Future<void> tracePrefetch(String reqId, {bool force = false}) async {
    if (reqId.isEmpty) return;
    if (!force && traceCacheGet(reqId).isNotEmpty) return;
    for (var i = 0; i < 3; i++) {
      try {
        final res = await logList(reqId: reqId);
        final logs = res.logs.map(TraceLogDoc.fromLog).toList();
        if (logs.isNotEmpty) {
          traceCachePut(reqId, logs);
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: 200 * (i + 1)));
    }
  }

  Future<TraceView> traceViewFetch(String reqId) async {
    final res = await logList(reqId: reqId);
    final logs = res.logs.map(TraceLogDoc.fromLog).toList();
    if (logs.isNotEmpty) traceCachePut(reqId, logs);
    return buildTraceView(logs);
  }

  Future<ResLogList> logList({required String reqId, int limit = 200}) => _rpc<ResLogList>(
        WsReq(logList: ReqLogList(reqId: reqId, limit: limit)),
        (res) => res.logList,
      );

  Future<ResIdentityList> identityList(List<String> kinds, {bool includeArchived = false}) => _rpc<ResIdentityList>(
        WsReq(identityList: ReqIdentityList(kinds: kinds, includeArchived: includeArchived)),
        (res) => res.identityList,
      );

  Future<ResIdentityGrantPatch> identityGrantPatch(ReqIdentityGrantPatch req) => _rpc<ResIdentityGrantPatch>(
        WsReq(identityGrantPatch: req),
        (res) => res.identityGrantPatch,
      );

  Future<ResIdentityPut> identityPut(ReqIdentityPut req) => _rpc<ResIdentityPut>(
        WsReq(identityPut: req),
        (res) => res.identityPut,
      );

  Future<ResIdentityDelete> identityDelete(int iid) => _rpc<ResIdentityDelete>(
        WsReq(identityDelete: ReqIdentityDelete(iid: Int64(iid))),
        (res) => res.identityDelete,
      );

  Future<ResChannelDisconnect> channelDisconnect(int botIid, String channelId) => _rpc<ResChannelDisconnect>(
        WsReq(channelDisconnect: ReqChannelDisconnect(botIid: Int64(botIid), channelId: channelId)),
        (res) => res.channelDisconnect,
      );

  Future<ResSkillList> skillList({SkillScope scope = SkillScope.SKILL_SCOPE_USER, int deviceIid = 0, int teamIid = 0, int sinceMs = 0}) => _rpc<ResSkillList>(
        WsReq(skillList: ReqSkillList(scope: scope, deviceIid: Int64(deviceIid), teamIid: Int64(teamIid), sinceMs: Int64(sinceMs))),
        (res) => res.skillList,
      );

  Future<ResSkillPut> skillPut(Skill skill) => _rpc<ResSkillPut>(
        WsReq(skillPut: ReqSkillPut(skill: skill)),
        (res) => res.skillPut,
      );

  Future<ResSkillCatalogList> skillCatalogList({String q = '', int limit = 50}) => _rpc<ResSkillCatalogList>(
        WsReq(skillCatalogList: ReqSkillCatalogList(q: q, limit: limit)),
        (res) => res.skillCatalogList,
      );

  bool _isRemoteSignal(WsRes res) =>
      res.hasRemoteSessionPush() || res.hasRtcSignalOffer() || res.hasRtcSignalAnswer() || res.hasRtcSignalIce();

  Future<ResRemoteIceConfig> remoteIceConfig() => _rpc<ResRemoteIceConfig>(
        WsReq(remoteIceConfig: ReqRemoteIceConfig()),
        (res) => res.remoteIceConfig,
      );

  Future<ResRemoteSessionStart> remoteSessionStart(int deviceIid, String sessionId) => _rpc<ResRemoteSessionStart>(
        WsReq(remoteSessionStart: ReqRemoteSessionStart(deviceIid: Int64(deviceIid), sessionId: sessionId)),
        (res) => res.remoteSessionStart,
      );

  Future<ResRemoteSessionStop> remoteSessionStop(int deviceIid, String sessionId) => _rpc<ResRemoteSessionStop>(
        WsReq(remoteSessionStop: ReqRemoteSessionStop(deviceIid: Int64(deviceIid), sessionId: sessionId)),
        (res) => res.remoteSessionStop,
      );

  Future<void> rtcSignalOffer(RtcSignalOffer offer) => _rpc<void>(
        WsReq(rtcSignalOffer: offer),
        (_) {},
      );

  Future<void> rtcSignalAnswer(RtcSignalAnswer answer) => _rpc<void>(
        WsReq(rtcSignalAnswer: answer),
        (_) {},
      );

  Future<void> rtcSignalIce(RtcSignalIce ice) => _rpc<void>(
        WsReq(rtcSignalIce: ice),
        (_) {},
      );

  Future<ResSkillCatalogInstall> skillCatalogInstall({required int catalogId, SkillScope scope = SkillScope.SKILL_SCOPE_USER, int deviceIid = 0, int variantId = 0, int releaseId = 0}) => _rpc<ResSkillCatalogInstall>(
        WsReq(
          skillCatalogInstall: ReqSkillCatalogInstall(
            catalogId: Int64(catalogId),
            variantId: Int64(variantId),
            releaseId: Int64(releaseId),
            scope: scope,
            deviceIid: Int64(deviceIid),
          ),
        ),
        (res) => res.skillCatalogInstall,
      );

  Future<ResSkillCatalogSearch> skillCatalogSearch({String q = '', String tagsJson = '', int limit = 20, int offset = 0}) => _rpc<ResSkillCatalogSearch>(
        WsReq(skillCatalogSearch: ReqSkillCatalogSearch(q: q, tagsJson: tagsJson, limit: limit, offset: offset)),
        (res) => res.skillCatalogSearch,
      );

  Future<ResMentionList> mentionList() => _rpc<ResMentionList>(
        WsReq(mentionList: ReqMentionList()),
        (res) => res.mentionList,
      );

  Future<ResMentionSearch> mentionSearch({String q = '', List<String> kinds = const [], int limit = 20}) => _rpc<ResMentionSearch>(
        WsReq(mentionSearch: ReqMentionSearch(q: q, kinds: kinds, limit: limit)),
        (res) => res.mentionSearch,
      );

  Future<ResSkillCatalogSubmit> skillCatalogSubmit({required int skillId, String submitAction = 'new', int existingCatalogId = 0}) => _rpc<ResSkillCatalogSubmit>(
        WsReq(skillCatalogSubmit: ReqSkillCatalogSubmit(skillId: Int64(skillId), submitAction: submitAction, existingCatalogId: Int64(existingCatalogId))),
        (res) => res.skillCatalogSubmit,
      );

  Future<ResSkillRunReport> skillRunReport({required int skillId, bool success = true, int stepIndex = 0, String error = '', String patchMd = '', String detectedAppVersion = '', String metaJson = ''}) => _rpc<ResSkillRunReport>(
        WsReq(
          skillRunReport: ReqSkillRunReport(
            skillId: Int64(skillId),
            success: success,
            stepIndex: stepIndex,
            error: error,
            patchMd: patchMd,
            detectedAppVersion: detectedAppVersion,
            metaJson: metaJson,
          ),
        ),
        (res) => res.skillRunReport,
      );

  Future<ResSiteList> siteList({bool archived = false}) => _rpc<ResSiteList>(
        WsReq(siteList: ReqSiteList(archived: archived)),
        (res) => res.siteList,
      );

  Future<ResSiteDraftGet> siteDraftGet(int siteIid) => _rpc<ResSiteDraftGet>(
        WsReq(siteDraftGet: ReqSiteDraftGet(siteIid: Int64(siteIid))),
        (res) => res.siteDraftGet,
      );

  Future<ResSiteDraftPut> siteDraftPut(SiteDraft draft, {bool skipPublish = false}) => _rpc<ResSiteDraftPut>(
        WsReq(siteDraftPut: ReqSiteDraftPut(draft: draft, skipPublish: skipPublish)),
        (res) => res.siteDraftPut,
      );

  Future<ResSitePublish> sitePublish(int siteIid) => _rpc<ResSitePublish>(
        WsReq(sitePublish: ReqSitePublish(siteIid: Int64(siteIid))),
        (res) => res.sitePublish,
      );

  Future<ResSitePreviewToken> sitePreviewToken(int siteIid, {int ttlSecs = 300}) => _rpc<ResSitePreviewToken>(
        WsReq(sitePreviewToken: ReqSitePreviewToken(siteIid: Int64(siteIid), ttlSecs: ttlSecs)),
        (res) => res.sitePreviewToken,
      );

  Future<ResSiteProductList> siteProductList(int siteIid) => _rpc<ResSiteProductList>(
        WsReq(siteProductList: ReqSiteProductList(siteIid: Int64(siteIid))),
        (res) => res.siteProductList,
      );

  Future<ResSiteProductPut> siteProductPut(int siteIid, SiteProduct product) => _rpc<ResSiteProductPut>(
        WsReq(siteProductPut: ReqSiteProductPut(siteIid: Int64(siteIid), product: product)),
        (res) => res.siteProductPut,
      );

  Future<ResSiteContactList> siteContactList(int siteIid) => _rpc<ResSiteContactList>(
        WsReq(siteContactList: ReqSiteContactList(siteIid: Int64(siteIid))),
        (res) => res.siteContactList,
      );

  Future<ResSiteContactPut> siteContactPut(int siteIid, SiteContact contact) => _rpc<ResSiteContactPut>(
        WsReq(siteContactPut: ReqSiteContactPut(siteIid: Int64(siteIid), contact: contact)),
        (res) => res.siteContactPut,
      );

  Future<ResSiteObjectList> siteObjectList(int siteIid) => _rpc<ResSiteObjectList>(
        WsReq(siteObjectList: ReqSiteObjectList(siteIid: Int64(siteIid))),
        (res) => res.siteObjectList,
      );

  Future<ResSiteObjectPut> siteObjectPut(int siteIid, SiteObject obj) => _rpc<ResSiteObjectPut>(
        WsReq(siteObjectPut: ReqSiteObjectPut(siteIid: Int64(siteIid), obj: obj)),
        (res) => res.siteObjectPut,
      );

  Future<ResSiteDomainList> siteDomainList(int siteIid) => _rpc<ResSiteDomainList>(
        WsReq(siteDomainList: ReqSiteDomainList(siteIid: Int64(siteIid))),
        (res) => res.siteDomainList,
      );

  Future<ResSiteDomainPut> siteDomainPut(int siteIid, SiteDomain domain) => _rpc<ResSiteDomainPut>(
        WsReq(siteDomainPut: ReqSiteDomainPut(siteIid: Int64(siteIid), domain: domain)),
        (res) => res.siteDomainPut,
      );

  Future<ResSiteDomainVerify> siteDomainVerify(int siteIid, int domainId, {bool forceTls = false}) =>
      _rpc<ResSiteDomainVerify>(
        WsReq(
          siteDomainVerify: ReqSiteDomainVerify(
            siteIid: Int64(siteIid),
            domainId: Int64(domainId),
            forceTls: forceTls,
          ),
        ),
        (res) => res.siteDomainVerify,
      );

  Future<ResSiteConfigPut> siteConfigPut(int siteIid, {required String capabilitiesJson}) => _rpc<ResSiteConfigPut>(
        WsReq(siteConfigPut: ReqSiteConfigPut(siteIid: Int64(siteIid), capabilitiesJson: capabilitiesJson)),
        (res) => res.siteConfigPut,
      );

  Future<ResCollectionDefList> collectionDefList({int siteIid = 0}) => _rpc<ResCollectionDefList>(
        WsReq(collectionDefList: ReqCollectionDefList(siteIid: Int64(siteIid))),
        (res) => res.collectionDefList,
      );

  Future<ResTxGet> txGet(int siteIid, Int64 txId) => _rpc<ResTxGet>(
        WsReq(txGet: ReqTxGet(siteIid: Int64(siteIid), txId: txId)),
        (res) => res.txGet,
      );

  Future<ResTxList> txList(int siteIid, {String q = '', int limit = 100, bool includeArchived = false}) => _rpc<ResTxList>(
        WsReq(txList: ReqTxList(siteIid: Int64(siteIid), q: q, limit: limit, includeArchived: includeArchived)),
        (res) => res.txList,
      );

  Future<ResTxPut> txPut(Tx tx) => _rpc<ResTxPut>(
        WsReq(txPut: ReqTxPut(tx: tx)),
        (res) => res.txPut,
      );

  Future<ResTxPreview> txPreview(Tx tx) => _rpc<ResTxPreview>(
        WsReq(txPreview: ReqTxPreview(tx: tx)),
        (res) => res.txPreview,
      );

  Future<ResSync> sync({Int64 sinceMs = Int64.ZERO, List<String> collections = const [], int limitPerCollection = 500}) =>
      _rpc<ResSync>(
        WsReq(sync: ReqSync(sinceMs: sinceMs, collections: collections, limitPerCollection: limitPerCollection)),
        (res) => res.sync,
      );

  Future<InvokeRes> invoke(InvokeReq req) async {
    if (req.reqId.isEmpty) req.reqId = const Uuid().v4();
    if (req.callerIid == Int64.ZERO) req.callerIid = Int64(Session.instance.uid);
    return _rpc<InvokeRes>(WsReq(invoke: req), (res) => res.invoke);
  }

  Future<void> statsSubscribe() => _rpc<void>(
        WsReq(statsSubscribe: ReqStatsSubscribe()),
        (_) {},
      );

  Future<void> statsUnsubscribe() => _rpc<void>(
        WsReq(statsUnsubscribe: ReqStatsUnsubscribe()),
        (_) {},
      );

  Future<void> logSubscribe({int? ownerIid}) => _rpc<void>(
        WsReq(
          logSubscribe: ReqLogSubscribe(
            ownerIid: ownerIid == null ? null : Int64(ownerIid),
          ),
        ),
        (_) {},
      );

  Future<void> logUnsubscribe() => _rpc<void>(
        WsReq(logUnsubscribe: ReqLogUnsubscribe()),
        (_) {},
      );

  Future<ResChannelWhatsappPair> channelWhatsappPairStart(int botIid, {String channelId = ''}) => _rpc<ResChannelWhatsappPair>(
        WsReq(channelWhatsappPairStart: ReqChannelWhatsappPairStart(botIid: Int64(botIid), channelId: channelId)),
        (res) => res.channelWhatsappPairStart,
      );

  Future<ResChannelWhatsappPair> channelWhatsappPairWatch(int botIid, String channelId) => _rpc<ResChannelWhatsappPair>(
        WsReq(channelWhatsappPairWatch: ReqChannelWhatsappPairWatch(botIid: Int64(botIid), channelId: channelId)),
        (res) => res.channelWhatsappPairWatch,
      );

  Future<ResChannelWhatsappPair> channelWhatsappPairAbort(int botIid, String channelId) => _rpc<ResChannelWhatsappPair>(
        WsReq(channelWhatsappPairAbort: ReqChannelWhatsappPairAbort(botIid: Int64(botIid), channelId: channelId)),
        (res) => res.channelWhatsappPairAbort,
      );

  Future<ResBotPeerList> botPeerList(int botIid, {bool includeArchived = false, int limit = 100}) => _rpc<ResBotPeerList>(
        WsReq(botPeerList: ReqBotPeerList(botIid: Int64(botIid), includeArchived: includeArchived, limit: limit)),
        (res) => res.botPeerList,
      );

  Future<ResChatStop> chatStop(int chatId, bool stopped) => _rpc<ResChatStop>(
        WsReq(chatStop: ReqChatStop(chatId: Int64(chatId), stopped: stopped)),
        (res) => res.chatStop,
      );

  Future<ResChatSend> chatSend(int chatId, String text, {String attachmentsJson = '[]'}) => _rpc<ResChatSend>(
        WsReq(chatSend: ReqChatSend(chatId: Int64(chatId), text: text, attachmentsJson: attachmentsJson)),
        (res) => res.chatSend,
      );

  Future<ResPromptFollowupPut> promptFollowupPut({
    required int chatId,
    required String text,
    String reqId = '',
    String attachmentsJson = '[]',
    PromptFollowupKind kind = PromptFollowupKind.PROMPT_FOLLOWUP_KIND_QUEUE,
  }) =>
      _rpc<ResPromptFollowupPut>(
        WsReq(
          promptFollowupPut: ReqPromptFollowupPut(
            chatId: Int64(chatId),
            reqId: reqId,
            text: text,
            attachmentsJson: attachmentsJson,
            kind: kind,
          ),
        ),
        (res) => res.promptFollowupPut,
      );

  Stream<PromptStreamEvent> promptAttach({required String reqId}) async* {
    if (_ch == null) await connect();
    final id = reqId.trim();
    if (id.isEmpty) return;
    final ctrl = StreamController<PromptStreamEvent>();
    _promptPending[id] = ctrl;
    lastPromptReqId = id;
    yield* ctrl.stream;
  }

  Future<ResPromptFollowupCancel> promptFollowupCancel({required String id}) => _rpc<ResPromptFollowupCancel>(
        WsReq(promptFollowupCancel: ReqPromptFollowupCancel(id: id)),
        (res) => res.promptFollowupCancel,
      );

  Future<ResPromptFollowupList> promptFollowupList({required int chatId, String reqId = ''}) =>
      _rpc<ResPromptFollowupList>(
        WsReq(
          promptFollowupList: ReqPromptFollowupList(chatId: Int64(chatId), reqId: reqId),
        ),
        (res) => res.promptFollowupList,
      );

  Future<void> promptAbort({Int64 chatId = Int64.ZERO, String reqId = ''}) async {
    final req = ReqPromptAbort(chatId: chatId);
    if (reqId.isNotEmpty) req.reqId = reqId;
    await _rpc<ResChatStop>(
      WsReq(promptAbort: req),
      (res) => res.hasChatStop() ? res.chatStop : ResChatStop(),
    );
  }

  String? lastPromptReqId;

  Stream<PromptStreamEvent> promptSend({
    required String text,
    Int64 chatId = Int64.ZERO,
    String model = '',
    String attachmentsJson = '[]',
    String thinking = '',
    List<String> mentionIds = const [],
    List<Int64> deviceIids = const [],
    String topicId = '',
    String toolMode = 'agent',
    String locale = 'en',
    String? reqId,
  }) async* {
    if (_ch == null) await connect(locale: locale);
    final id = reqId != null && reqId.isNotEmpty ? reqId : const Uuid().v4();
    lastPromptReqId = id;
    final ctrl = StreamController<PromptStreamEvent>();
    _promptPending[id] = ctrl;
    final req = WsReq(
      reqId: id,
      prompt: ReqPrompt(
        chatId: chatId,
        model: model,
        text: text,
        attachmentsJson: attachmentsJson,
        thinking: thinking,
        mentionIds: mentionIds,
        deviceIids: deviceIids,
        topicId: topicId,
        toolMode: toolMode,
      ),
    );
    _send(req);
    yield* ctrl.stream;
  }
}
