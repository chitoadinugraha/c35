import 'dart:async';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final _promptPending = <String, StreamController<PromptStreamEvent>>{};
  final _rpcPending = <String, Completer<WsRes>>{};
  final _syncPushCtrl = StreamController<SyncPush>.broadcast();
  final _billingBalanceCtrl = StreamController<BillingPushBalance>.broadcast();
  final _billingQuotaCtrl = StreamController<BillingPushQuota>.broadcast();
  final _billingCommissionCtrl = StreamController<BillingPushCommission>.broadcast();
  final _channelPairPushCtrl = StreamController<ChannelPairPush>.broadcast();
  final _traceCache = <String, List<TraceLogDoc>>{};

  Stream<SyncPush> get onSyncPush => _syncPushCtrl.stream;
  Stream<ChannelPairPush> get onChannelPairPush => _channelPairPushCtrl.stream;
  Stream<BillingPushBalance> get onBillingBalance => _billingBalanceCtrl.stream;
  Stream<BillingPushQuota> get onBillingQuota => _billingQuotaCtrl.stream;
  Stream<BillingPushCommission> get onBillingCommission => _billingCommissionCtrl.stream;

  bool get connected => _ch != null;

  String _wsUrl({String locale = 'en'}) {
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
      },
    ).toString();
  }

  Future<void> connect({String locale = 'en'}) async {
    await disconnect();
    final token = Session.instance.token.trim();
    if (token.isEmpty) throw 'not signed in';
    _ch = WebSocketChannel.connect(Uri.parse(_wsUrl(locale: locale)));
    _sub = _ch!.stream.listen(_onData, onError: (e) {
      lError('chat ws: $e');
      _failAll('$e');
    }, onDone: () => _failAll('connection closed'));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _ch?.sink.close();
    _ch = null;
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
    final res = WsRes.fromBuffer(data);
    final reqId = res.reqId;

    if (res.hasSyncPush()) {
      if (!_syncPushCtrl.isClosed) _syncPushCtrl.add(res.syncPush);
    }
    if (res.hasBillingBalance() && !_billingBalanceCtrl.isClosed) _billingBalanceCtrl.add(res.billingBalance);
    if (res.hasBillingQuota() && !_billingQuotaCtrl.isClosed) _billingQuotaCtrl.add(res.billingQuota);
    if (res.hasBillingCommission() && !_billingCommissionCtrl.isClosed) _billingCommissionCtrl.add(res.billingCommission);
    if (res.hasChannelPairPush() && !_channelPairPushCtrl.isClosed) _channelPairPushCtrl.add(res.channelPairPush);

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
    _ch = null;
    _sub = null;
  }

  Future<ResSessionInit> sessionInit({
    Int64 sinceMs = Int64.ZERO,
    String locale = 'en',
    String tz = '',
    String dv = '',
    String clientId = '',
    int platform = 0,
    bool includeInbox = true,
    bool includeBilling = false,
  }) =>
      _rpc<ResSessionInit>(
        WsReq(
          sessionInit: ReqSessionInit(
            sinceMs: sinceMs,
            locale: locale,
            tz: tz,
            dv: dv,
            clientId: clientId,
            platform: platform,
            includeInbox: includeInbox,
            includeBilling: includeBilling,
          ),
        ),
        (res) => res.sessionInit,
      );

  Future<ResInboxList> inboxList({bool includeArchived = false, int limit = 100}) => _rpc<ResInboxList>(
        WsReq(inboxList: ReqInboxList(includeArchived: includeArchived, limit: limit)),
        (res) => res.inboxList,
      );

  Future<ResChatMsgList> chatMsgList({required Int64 chatId, Int64 beforeId = Int64.ZERO, int limit = 100}) => _rpc<ResChatMsgList>(
        WsReq(chatMsgList: ReqChatMsgList(chatId: chatId, beforeId: beforeId, limit: limit)),
        (res) => res.chatMsgList,
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
  }

  Future<void> tracePrefetch(String reqId) async {
    if (reqId.isEmpty || traceCacheGet(reqId).isNotEmpty) return;
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
    var logs = traceCacheGet(reqId);
    if (logs.isEmpty) {
      final res = await logList(reqId: reqId);
      logs = res.logs.map(TraceLogDoc.fromLog).toList();
      traceCachePut(reqId, logs);
    }
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

  Future<InvokeRes> invoke(InvokeReq req) async {
    if (req.reqId.isEmpty) req.reqId = const Uuid().v4();
    if (req.callerIid == Int64.ZERO) req.callerIid = Int64(Session.instance.uid);
    return _rpc<InvokeRes>(WsReq(invoke: req), (res) => res.invoke);
  }

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

  Future<void> promptAbort({Int64 chatId = Int64.ZERO}) async {
    await _rpc<ResChatStop>(
      WsReq(promptAbort: ReqPromptAbort(chatId: chatId)),
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
        topicId: topicId,
        toolMode: toolMode,
      ),
    );
    _send(req);
    yield* ctrl.stream;
  }
}
