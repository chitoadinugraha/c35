import 'dart:async';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/device/device_presence_cache.dart';
import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:flutter/foundation.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/pb/c35/catalog.pb.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/data_source.pb.dart';
import 'package:alienai_c35/c/pb/c35/device.pb.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/live.pb.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/pb/c35/log.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/c/pb/c35/task.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/trace/trace_log.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/prompt_run_store.dart';
import 'package:fixnum/fixnum.dart';
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
  var _socketGen = 0;
  static const _wsReadyTimeout = Duration(seconds: 8);
  var _locale = 'en';
  var _tz = '';
  var _appBuild = 0;
  var _appVersionName = '';
  final status = ValueNotifier<ChatConnStatus>(ChatConnStatus.disconnected);
  void _statusSet(ChatConnStatus next) {
    if (status.value == next) return;
    status.value = next;
  }

  final _reconnectedCtrl = StreamController<void>.broadcast();
  final _socketAttachedCtrl = StreamController<void>.broadcast();
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
  final _taskRunPushCtrl = StreamController<TaskRunPush>.broadcast();
  final _devicePresencePushCtrl = StreamController<DevicePresencePush>.broadcast();
  final _notifyPushCtrl = StreamController<NotifyPush>.broadcast();
  final _traceCache = <String, List<TraceLogDoc>>{};
  final _tracePrefetchInflight = <String, Future<void>>{};
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
  Stream<TaskRunPush> get onTaskRunPush => _taskRunPushCtrl.stream;
  Stream<DevicePresencePush> get onDevicePresencePush => _devicePresencePushCtrl.stream;
  Stream<NotifyPush> get onNotifyPush => _notifyPushCtrl.stream;
  Stream<void> get onReconnected => _reconnectedCtrl.stream;
  /// Fires after auto-reconnect attaches a socket (before first frame); run session init.
  Stream<void> get onSocketAttached => _socketAttachedCtrl.stream;

  bool get connected => _ch != null && status.value == ChatConnStatus.connected;

  String _wsUrl({String locale = 'en', String tz = '', int appBuild = 0, String appVersionName = ''}) {
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
        if (appBuild > 0) 'build': '$appBuild',
        if (appVersionName.isNotEmpty) 'version_name': appVersionName,
      },
    ).toString();
  }

  static int wirePlatform() => switch (defaultTargetPlatform) {
        TargetPlatform.android => 1,
        TargetPlatform.iOS => 1,
        TargetPlatform.macOS => 2,
        TargetPlatform.windows => 3,
        TargetPlatform.linux => 3,
        _ => 4,
      };

  Future<void> connect({
    String locale = 'en',
    String tz = '',
    int appBuild = 0,
    String appVersionName = '',
  }) async {
    _manualDisconnect = false;
    _locale = locale;
    _tz = tz;
    _appBuild = appBuild > 0 ? appBuild : (int.tryParse(csaiVersion) ?? 0);
    _appVersionName = appVersionName.isNotEmpty ? appVersionName : csaiVersionFull;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    _statusSet(ChatConnStatus.connecting);
    await _tearDownSocket(failPending: true);
    try {
      await _attachSocket(locale: locale, tz: tz, appBuild: appBuild, appVersionName: appVersionName);
    } catch (e) {
      lError('chat ws connect: $e');
      if (Session.instance.token.trim().isEmpty) {
        _statusSet(ChatConnStatus.disconnected);
      } else {
        _scheduleReconnectIfNeeded();
      }
      rethrow;
    }
  }

  /// Cancel backoff, tear down the socket, and connect again with the last [connect] params.
  Future<void> reconnect() => connect(
        locale: _locale,
        tz: _tz,
        appBuild: _appBuild,
        appVersionName: _appVersionName,
      );

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    await _tearDownSocket(failPending: true);
    _statusSet(ChatConnStatus.disconnected);
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
      if (c.isClosed) continue;
      c.add(PromptStreamEvent.fail(uiConnectionFailed));
      if (!c.isClosed) await c.close();
    }
    _promptPending.clear();
    for (final c in _rpcPending.values) {
      if (!c.isCompleted) c.completeError('disconnected');
    }
    _rpcPending.clear();
  }

  Future<void> _attachSocket({
    required String locale,
    String tz = '',
    int appBuild = 0,
    String appVersionName = '',
  }) async {
    final token = Session.instance.token.trim();
    if (token.isEmpty) throw 'not signed in';
    final gen = ++_socketGen;
    _ch = WebSocketChannel.connect(
      Uri.parse(_wsUrl(locale: locale, tz: tz, appBuild: appBuild, appVersionName: appVersionName)),
    );
    _sub = _ch!.stream.listen(
      (data) => _onData(data, gen),
      onError: (e) => _onWsError(e, gen),
      onDone: () => _onWsDone(gen),
    );
    try {
      await _waitSocketReady(gen);
      if (gen != _socketGen) return;
      _markConnected(gen);
    } catch (e) {
      if (gen != _socketGen) return;
      await _dropSocketIfGen(gen);
      rethrow;
    }
  }

  Future<void> _waitSocketReady(int gen) async {
    final ch = _ch;
    if (ch == null) throw StateError('no socket');
    try {
      await ch.ready.timeout(_wsReadyTimeout);
    } on TimeoutException {
      if (gen != _socketGen) return;
      await _dropSocketIfGen(gen);
      throw StateError('chat ws ready timeout');
    }
  }

  Future<void> _dropSocketIfGen(int gen) async {
    if (gen != _socketGen || _ch == null) return;
    await _sub?.cancel();
    _sub = null;
    try {
      await _ch?.sink.close();
    } catch (_) {}
    _ch = null;
  }

  void _markConnected(int gen) {
    if (gen != _socketGen || _ch == null) return;
    final wasOffline = status.value != ChatConnStatus.connected;
    _retryCount = 0;
    _statusSet(ChatConnStatus.connected);
    if (wasOffline) {
      if (!_reconnectedCtrl.isClosed) _reconnectedCtrl.add(null);
    }
  }

  void _emitSocketAttached() {
    if (!_socketAttachedCtrl.isClosed) _socketAttachedCtrl.add(null);
  }

  void _onWsError(Object e, int gen) {
    if (gen != _socketGen) return;
    lError('chat ws: $e');
    _failAll(uiPromptErrorMessage('$e'));
    _scheduleReconnectIfNeeded();
  }

  void _onWsDone(int gen) {
    if (gen != _socketGen) return;
    _failAll(uiConnectionFailed);
    _scheduleReconnectIfNeeded();
  }

  void _scheduleReconnectIfNeeded() {
    if (_manualDisconnect) {
      _statusSet(ChatConnStatus.disconnected);
      return;
    }
    if (Session.instance.token.trim().isEmpty) {
      _statusSet(ChatConnStatus.disconnected);
      return;
    }
    if (_reconnectTimer != null) return;
    _statusSet(ChatConnStatus.reconnecting);
    _retryCount++;
    // Exponential backoff capped at 16 seconds to prevent socket exhaustion and ensure quick recovery
    final sec = (1 << (_retryCount - 1).clamp(0, 4)).clamp(1, 16);
    final delay = Duration(seconds: sec);
    l('chat ws reconnect attempt $_retryCount in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (_manualDisconnect) return;
      try {
        _statusSet(ChatConnStatus.connecting);
        await _tearDownSocket(failPending: false);
        await _attachSocket(
          locale: _locale,
          tz: _tz,
          appBuild: _appBuild,
          appVersionName: _appVersionName,
        );
        _emitSocketAttached();
      } catch (e) {
        lError('chat ws reconnect: $e');
        _scheduleReconnectIfNeeded();
      }
    });
  }

  bool _trySend(WsReq req) {
    final ch = _ch;
    if (ch == null || ch.closeCode != null) {
      unawaited(_nudgeReconnectAfterSendFailure());
      return false;
    }
    try {
      ch.sink.add(req.writeToBuffer());
      return true;
    } catch (e) {
      lError('chat ws send skipped: $e');
      unawaited(_nudgeReconnectAfterSendFailure());
      return false;
    }
  }

  Future<void> _nudgeReconnectAfterSendFailure() async {
    if (_manualDisconnect || Session.instance.token.trim().isEmpty) return;
    await _dropSocketIfGen(_socketGen);
    _scheduleReconnectIfNeeded();
  }

  Future<T> rpc<T>(WsReq req, T Function(WsRes res) parse) => _rpc(req, parse);

  Future<T> _rpc<T>(WsReq req, T Function(WsRes res) parse) async {
    Object? lastSendErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (_ch == null || status.value != ChatConnStatus.connected) {
        if (_ch != null && (status.value == ChatConnStatus.connecting || status.value == ChatConnStatus.reconnecting)) {
          try {
            await _waitSocketReady(_socketGen);
          } catch (_) {}
        }
        if (_ch == null || status.value != ChatConnStatus.connected) await reconnect();
      }
      final reqId = req.reqId.isNotEmpty ? req.reqId : const Uuid().v4();
      req.reqId = reqId;
      final completer = Completer<WsRes>();
      _rpcPending[reqId] = completer;
      try {
        if (!_trySend(req)) throw ApiException(uiConnectionFailed);
      } catch (e) {
        _rpcPending.remove(reqId);
        lastSendErr = e;
        if (attempt == 0) {
          await reconnect();
          continue;
        }
        rethrow;
      }
      final res = await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          _rpcPending.remove(reqId);
          throw TimeoutException('rpc timeout: $reqId');
        },
      );
      return parse(res);
    }
    throw lastSendErr ?? StateError('rpc send failed');
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

  void _onData(dynamic data, int gen) {
    if (gen != _socketGen) return;
    if (data is! List<int>) return;
    _markConnected(gen);
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
    if (res.hasLogPush()) {
      final push = res.logPush;
      if (!_logPushCtrl.isClosed) _logPushCtrl.add(push);
      if (push.hasRow()) traceCacheMerge(TraceLogDoc.fromLog(push.row));
    }
    if (res.hasPromptRunPush()) {
      final push = res.promptRunPush;
      PromptRunStore.instance.put(push);
      if (!_promptRunPushCtrl.isClosed) _promptRunPushCtrl.add(push);
    }
    if (res.hasPromptFollowupPush()) {
      final push = res.promptFollowupPush;
      if (!_promptFollowupPushCtrl.isClosed) _promptFollowupPushCtrl.add(push);
    }
    if (res.hasTaskRunPush()) {
      final push = res.taskRunPush;
      if (!_taskRunPushCtrl.isClosed) _taskRunPushCtrl.add(push);
    }
    if (res.hasDevicePresencePush()) {
      final push = res.devicePresencePush;
      DevicePresenceCache.instance.apply(push);
      if (!_devicePresencePushCtrl.isClosed) _devicePresencePushCtrl.add(push);
    }
    if (res.hasNotifyPush() && !_notifyPushCtrl.isClosed) _notifyPushCtrl.add(res.notifyPush);
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
      if (e.value.isClosed) continue;
      e.value.add(PromptStreamEvent.fail(message));
      if (!e.value.isClosed) e.value.close();
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
    int appBuild = 0,
    String appVersionName = '',
    bool includeInbox = true,
    bool includeBilling = false,
    Int64 hintsSinceMs = Int64.ZERO,
    Int64 mentionsSinceMs = Int64.ZERO,
    String generationImage = '',
    String generationVideo = '',
    String generationMusic = '',
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
            appBuild: Int64(appBuild),
            appVersionName: appVersionName,
            includeInbox: includeInbox,
            includeBilling: includeBilling,
            hintsSinceMs: hintsSinceMs,
            mentionsSinceMs: mentionsSinceMs,
            generationImage: generationImage,
            generationVideo: generationVideo,
            generationMusic: generationMusic,
          ),
        ),
        (res) => res.sessionInit,
      );

  Future<ResHintTouch> hintTouch({required Int64 assetIid, required String assetKind}) => _rpc<ResHintTouch>(
        WsReq(hintTouch: ReqHintTouch(assetIid: assetIid, assetKind: assetKind)),
        (res) => res.hintTouch,
      );

  Future<ResLiveStart> liveStart({
        required String offerId,
        String locale = '',
        int? chatId,
        List<String> mentionIds = const [],
      }) =>
      _rpc<ResLiveStart>(
        WsReq(
          liveStart: ReqLiveStart(
            offerId: offerId,
            locale: locale,
            reqId: const Uuid().v4(),
            chatId: chatId != null ? Int64(chatId) : Int64.ZERO,
            mentionIds: mentionIds,
          ),
        ),
        (res) => res.liveStart,
      );

  Future<ResInboxList> inboxList({bool includeArchived = false, int limit = 100}) => _rpc<ResInboxList>(
        WsReq(inboxList: ReqInboxList(includeArchived: includeArchived, limit: limit)),
        (res) => res.inboxList,
      );

  Future<ResChatMsgList> chatMsgList({required Int64 chatId, Int64 beforeId = Int64.ZERO, int limit = 100}) => _rpc<ResChatMsgList>(
        WsReq(chatMsgList: ReqChatMsgList(chatId: chatId, beforeId: beforeId, limit: limit)),
        (res) => res.chatMsgList,
      );

  Future<ResChatDeviceContextList> chatDeviceContextList({
    required Int64 deviceIid,
    bool includeArchived = true,
    int limit = 20,
  }) =>
      _rpc<ResChatDeviceContextList>(
        WsReq(
          chatDeviceContextList: ReqChatDeviceContextList(
            deviceIid: deviceIid,
            includeArchived: includeArchived,
            limit: limit,
          ),
        ),
        (res) => res.chatDeviceContextList,
      );

  Future<ResChatDeviceContextCreate> chatDeviceContextCreate({
    required Int64 deviceIid,
    String title = '',
  }) =>
      _rpc<ResChatDeviceContextCreate>(
        WsReq(
          chatDeviceContextCreate: ReqChatDeviceContextCreate(deviceIid: deviceIid, title: title),
        ),
        (res) => res.chatDeviceContextCreate,
      );

  Future<ResChatHistoryClear> chatHistoryClear({bool dryRun = false}) => _rpc<ResChatHistoryClear>(
        WsReq(chatHistoryClear: ReqChatHistoryClear(dryRun: dryRun)),
        (res) => res.chatHistoryClear,
      );

  Future<ResMemoryList> memoryList({int limit = 100}) => _rpc<ResMemoryList>(
        WsReq(memoryList: ReqMemoryList(limit: limit)),
        (res) => res.memoryList,
      );

  Future<ResMemoryDelete> memoryDelete({required int id}) => _rpc<ResMemoryDelete>(
        WsReq(memoryDelete: ReqMemoryDelete(id: Int64(id))),
        (res) => res.memoryDelete,
      );

  Future<ResChatFeedbackReasonList> chatFeedbackReasonList({
    String locale = '',
    ChatFeedbackVote vote = ChatFeedbackVote.CHAT_FEEDBACK_VOTE_UNSPECIFIED,
  }) =>
      _rpc<ResChatFeedbackReasonList>(
        WsReq(chatFeedbackReasonList: ReqChatFeedbackReasonList(locale: locale, vote: vote)),
        (res) => res.chatFeedbackReasonList,
      );

  Future<ResChatMsgFeedbackPut> chatMsgFeedbackPut({
    required int msgId,
    required int chatId,
    required ChatFeedbackVote vote,
    int reasonId = 0,
    String comment = '',
    String locale = '',
  }) =>
      _rpc<ResChatMsgFeedbackPut>(
        WsReq(
          chatMsgFeedbackPut: ReqChatMsgFeedbackPut(
            msgId: Int64(msgId),
            chatId: Int64(chatId),
            vote: vote,
            reasonId: reasonId,
            comment: comment,
            locale: locale,
          ),
        ),
        (res) => res.chatMsgFeedbackPut,
      );

  Future<ResChatMsgFeedbackList> chatMsgFeedbackList({required int chatId, String locale = ''}) => _rpc<ResChatMsgFeedbackList>(
        WsReq(chatMsgFeedbackList: ReqChatMsgFeedbackList(chatId: Int64(chatId), locale: locale)),
        (res) => res.chatMsgFeedbackList,
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

  Future<ResChatContextWindowSet> chatContextWindowSet({required int chatId, required int contextWindow}) => _rpc<ResChatContextWindowSet>(
        WsReq(chatContextWindowSet: ReqChatContextWindowSet(chatId: Int64(chatId), contextWindow: contextWindow)),
        (res) => res.chatContextWindowSet,
      );

  Future<ResChatCompact> chatCompact({required int chatId}) => _rpc<ResChatCompact>(
        WsReq(chatCompact: ReqChatCompact(chatId: Int64(chatId))),
        (res) => res.chatCompact,
      );

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

  void traceCacheMerge(TraceLogDoc doc) {
    final reqId = doc.reqId.trim();
    if (reqId.isEmpty) return;
    final prev = _traceCache[reqId] ?? const <TraceLogDoc>[];
    final next = List<TraceLogDoc>.from(prev);
    final idx = doc.id > 0 ? next.indexWhere((e) => e.id == doc.id) : -1;
    if (idx >= 0) {
      next[idx] = doc;
    } else {
      next.add(doc);
      next.sort((a, b) => a.tsMs.compareTo(b.tsMs));
    }
    _traceCache[reqId] = next;
    if (!_traceCacheCtrl.isClosed) _traceCacheCtrl.add(reqId);
  }

  Future<void> tracePrefetch(String reqId, {bool force = false}) async {
    final id = reqId.trim();
    if (id.isEmpty) return;
    if (!force && traceCacheGet(id).isNotEmpty) return;
    final inflight = _tracePrefetchInflight[id];
    if (inflight != null) return inflight;
    final job = _tracePrefetchOnce(id);
    _tracePrefetchInflight[id] = job;
    try {
      await job;
    } finally {
      if (identical(_tracePrefetchInflight[id], job)) _tracePrefetchInflight.remove(id);
    }
  }

  Future<void> _tracePrefetchOnce(String reqId) async {
    for (var i = 0; i < 3; i++) {
      try {
        final res = await logList(reqId: reqId);
        final logs = res.logs.map(TraceLogDoc.fromLog).toList();
        if (logs.isNotEmpty) {
          traceCachePut(reqId, logs);
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: 80 * (i + 1)));
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

  Future<ResTaskList> taskList({int deviceIid = 0, bool includeInactive = true}) => _rpc<ResTaskList>(
        WsReq(taskList: ReqTaskList(deviceIid: Int64(deviceIid), includeInactive: includeInactive)),
        (res) => res.taskList,
      );

  Future<ResTaskPut> taskPut(Task task) => _rpc<ResTaskPut>(
        WsReq(taskPut: ReqTaskPut(task: task)),
        (res) => res.taskPut,
      );

  Future<ResTaskRunStart> taskRunStart(ReqTaskRunStart req) => _rpc<ResTaskRunStart>(
        WsReq(taskRunStart: req),
        (res) => res.taskRunStart,
      );

  Future<ResTaskRunCancel> taskRunCancel(int runId) => _rpc<ResTaskRunCancel>(
        WsReq(taskRunCancel: ReqTaskRunCancel(runId: Int64(runId))),
        (res) => res.taskRunCancel,
      );

  Future<ResTaskRunCancelDevice> taskRunCancelDevice(int deviceIid) => _rpc<ResTaskRunCancelDevice>(
        WsReq(taskRunCancelDevice: ReqTaskRunCancelDevice(deviceIid: Int64(deviceIid))),
        (res) => res.taskRunCancelDevice,
      );

  Future<ResTaskRunList> taskRunList({int deviceIid = 0, int taskId = 0, int sinceMs = 0, int limit = 50}) => _rpc<ResTaskRunList>(
        WsReq(
          taskRunList: ReqTaskRunList(
            deviceIid: Int64(deviceIid),
            taskId: Int64(taskId),
            sinceMs: Int64(sinceMs),
            limit: limit,
          ),
        ),
        (res) => res.taskRunList,
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

  Future<ResRemoteAgentPush> remoteAgentPush(int deviceIid, String payload) => _rpc<ResRemoteAgentPush>(
        WsReq(
          reqRemoteAgentPush: ReqRemoteAgentPush(
            deviceIid: Int64(deviceIid),
            payload: payload,
          ),
        ),
        (res) => res.resRemoteAgentPush,
      );

  Future<ResRemoteBrowserInvoke> remoteBrowserInvoke({
    required int deviceIid,
    required String method,
    String paramsJson = '{}',
    int timeoutSec = 45,
  }) =>
      _rpc<ResRemoteBrowserInvoke>(
        WsReq(
          reqRemoteBrowserInvoke: ReqRemoteBrowserInvoke(
            deviceIid: Int64(deviceIid),
            method: method,
            paramsJson: paramsJson,
            timeoutSec: timeoutSec,
          ),
        ),
        (res) => res.resRemoteBrowserInvoke,
      );

  Future<ResSkillCatalogInstall> skillCatalogInstall({
    required int catalogId,
    SkillScope scope = SkillScope.SKILL_SCOPE_USER,
    int deviceIid = 0,
    int variantId = 0,
    int releaseId = 0,
    String externalSource = '',
    String externalSlug = '',
    String externalTitle = '',
  }) =>
      _rpc<ResSkillCatalogInstall>(
        WsReq(
          skillCatalogInstall: ReqSkillCatalogInstall(
            catalogId: Int64(catalogId),
            variantId: Int64(variantId),
            releaseId: Int64(releaseId),
            scope: scope,
            deviceIid: Int64(deviceIid),
            externalSource: externalSource,
            externalSlug: externalSlug,
            externalTitle: externalTitle,
          ),
        ),
        (res) => res.skillCatalogInstall,
      );

  Future<ResSkillCatalogSearch> skillCatalogSearch({String q = '', String tagsJson = '', int limit = 20, int offset = 0}) => _rpc<ResSkillCatalogSearch>(
        WsReq(skillCatalogSearch: ReqSkillCatalogSearch(q: q, tagsJson: tagsJson, limit: limit, offset: offset)),
        (res) => res.skillCatalogSearch,
      );

  Future<ResMentionList> mentionList({Int64 sinceMs = Int64.ZERO}) => _rpc<ResMentionList>(
        WsReq(mentionList: ReqMentionList(sinceMs: sinceMs)),
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

  Future<ResSiteHandlePut> siteHandlePut(int siteIid, String newAlienId) => _rpc<ResSiteHandlePut>(
        WsReq(siteHandlePut: ReqSiteHandlePut(siteIid: Int64(siteIid), newAlienId: newAlienId)),
        (res) => res.siteHandlePut,
      );

  Future<ResSiteBootGet> siteBootGet(int siteIid, {SiteBootMode mode = SiteBootMode.SITE_BOOT_MODE_DRAFT}) =>
      _rpc<ResSiteBootGet>(
        WsReq(siteBootGet: ReqSiteBootGet(siteIid: Int64(siteIid), mode: mode)),
        (res) => res.siteBootGet,
      );

  Future<ResSiteProductList> siteProductList(int siteIid) => _rpc<ResSiteProductList>(
        WsReq(siteProductList: ReqSiteProductList(siteIid: Int64(siteIid))),
        (res) => res.siteProductList,
      );

  Future<ResSiteProductPut> siteProductPut(int siteIid, SiteProduct product) => _rpc<ResSiteProductPut>(
        WsReq(siteProductPut: ReqSiteProductPut(siteIid: Int64(siteIid), product: product)),
        (res) => res.siteProductPut,
      );

  Future<ResImgGenerate> imgGenerate({required String prompt, required String provider}) =>
      _rpc<ResImgGenerate>(
        WsReq(imgGenerate: ReqImgGenerate(prompt: prompt, provider: provider)),
        (res) => res.imgGenerate,
      );

  Future<ResSiteProductDelete> siteProductDelete(int siteIid, int productId) => _rpc<ResSiteProductDelete>(
        WsReq(siteProductDelete: ReqSiteProductDelete(siteIid: Int64(siteIid), productId: Int64(productId))),
        (res) => res.siteProductDelete,
      );

  Future<ResSiteProductReorder> siteProductReorder(int siteIid, List<SiteProductReorderEntry> entries) =>
      _rpc<ResSiteProductReorder>(
        WsReq(siteProductReorder: ReqSiteProductReorder(siteIid: Int64(siteIid), entries: entries)),
        (res) => res.siteProductReorder,
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

  Future<ResSiteLinkList> siteLinkList(int siteIid) => _rpc<ResSiteLinkList>(
        WsReq(siteLinkList: ReqSiteLinkList(siteIid: Int64(siteIid))),
        (res) => res.siteLinkList,
      );

  Future<ResSiteLinkPut> siteLinkPut(int siteIid, SiteLink link) => _rpc<ResSiteLinkPut>(
        WsReq(siteLinkPut: ReqSiteLinkPut(siteIid: Int64(siteIid), link: link)),
        (res) => res.siteLinkPut,
      );

  Future<ResSiteLinkDelete> siteLinkDelete(int siteIid, int linkId) => _rpc<ResSiteLinkDelete>(
        WsReq(siteLinkDelete: ReqSiteLinkDelete(siteIid: Int64(siteIid), linkId: Int64(linkId))),
        (res) => res.siteLinkDelete,
      );

  Future<ResSiteGrantList> siteGrantList(int siteIid) => _rpc<ResSiteGrantList>(
        WsReq(siteGrantList: ReqSiteGrantList(siteIid: Int64(siteIid))),
        (res) => res.siteGrantList,
      );

  Future<ResSiteGrantPut> siteGrantPut(
    int siteIid, {
    Int64 granteeIid = Int64.ZERO,
    String granteeAlienId = '',
    String granteeEmail = '',
    required String role,
    List<String> workShiftIds = const [],
  }) =>
      _rpc<ResSiteGrantPut>(
        WsReq(
          siteGrantPut: ReqSiteGrantPut(
            siteIid: Int64(siteIid),
            granteeIid: granteeIid,
            granteeAlienId: granteeAlienId,
            granteeEmail: granteeEmail,
            role: role,
            workShiftIds: workShiftIds,
          ),
        ),
        (res) => res.siteGrantPut,
      );

  Future<ResSiteGrantDelete> siteGrantDelete(int siteIid, int granteeIid) => _rpc<ResSiteGrantDelete>(
        WsReq(siteGrantDelete: ReqSiteGrantDelete(siteIid: Int64(siteIid), granteeIid: Int64(granteeIid))),
        (res) => res.siteGrantDelete,
      );

  Future<ResSiteWorkShiftList> siteWorkShiftList(int siteIid) => _rpc<ResSiteWorkShiftList>(
        WsReq(siteWorkShiftList: ReqSiteWorkShiftList(siteIid: Int64(siteIid))),
        (res) => res.siteWorkShiftList,
      );

  Future<ResSiteWorkShiftPut> siteWorkShiftPut(int siteIid, List<SiteWorkShift> shifts) => _rpc<ResSiteWorkShiftPut>(
        WsReq(siteWorkShiftPut: ReqSiteWorkShiftPut(siteIid: Int64(siteIid), shifts: shifts)),
        (res) => res.siteWorkShiftPut,
      );

  Future<ResSiteTransferOwnership> siteTransferOwnership(int siteIid, int targetIid) =>
      _rpc<ResSiteTransferOwnership>(
        WsReq(siteTransferOwnership: ReqSiteTransferOwnership(siteIid: Int64(siteIid), targetIid: Int64(targetIid))),
        (res) => res.siteTransferOwnership,
      );

  Future<ResSiteMemberFaceList> siteMemberFaceList(int siteIid, int granteeIid) => _rpc<ResSiteMemberFaceList>(
        WsReq(siteMemberFaceList: ReqSiteMemberFaceList(siteIid: Int64(siteIid), granteeIid: Int64(granteeIid))),
        (res) => res.siteMemberFaceList,
      );

  Future<ResSiteMemberFacePut> siteMemberFacePut(
    int siteIid,
    int granteeIid, {
    required String fileHash,
    String pose = '',
  }) =>
      _rpc<ResSiteMemberFacePut>(
        WsReq(
          siteMemberFacePut: ReqSiteMemberFacePut(
            siteIid: Int64(siteIid),
            granteeIid: Int64(granteeIid),
            fileHash: fileHash,
            pose: pose,
          ),
        ),
        (res) => res.siteMemberFacePut,
      );

  Future<ResSiteMemberFaceDel> siteMemberFaceDel(int siteIid, int granteeIid, String faceId) =>
      _rpc<ResSiteMemberFaceDel>(
        WsReq(
          siteMemberFaceDel: ReqSiteMemberFaceDel(
            siteIid: Int64(siteIid),
            granteeIid: Int64(granteeIid),
            faceId: faceId,
          ),
        ),
        (res) => res.siteMemberFaceDel,
      );

  Future<ResSitePresenceLocationList> sitePresenceLocationList(int siteIid) => _rpc<ResSitePresenceLocationList>(
        WsReq(sitePresenceLocationList: ReqSitePresenceLocationList(siteIid: Int64(siteIid))),
        (res) => res.sitePresenceLocationList,
      );

  Future<ResSitePresenceLocationPut> sitePresenceLocationPut(int siteIid, List<SitePresenceLocation> locations) =>
      _rpc<ResSitePresenceLocationPut>(
        WsReq(sitePresenceLocationPut: ReqSitePresenceLocationPut(siteIid: Int64(siteIid), locations: locations)),
        (res) => res.sitePresenceLocationPut,
      );

  Future<ResSiteQueueList> siteQueueList(int siteIid) => _rpc<ResSiteQueueList>(
        WsReq(siteQueueList: ReqSiteQueueList(siteIid: Int64(siteIid))),
        (res) => res.siteQueueList,
      );

  Future<ResSiteQueuePut> siteQueuePut(int siteIid, SiteQueue queue) => _rpc<ResSiteQueuePut>(
        WsReq(siteQueuePut: ReqSiteQueuePut(siteIid: Int64(siteIid), queue: queue)),
        (res) => res.siteQueuePut,
      );

  Future<ResSiteQueueAdvance> siteQueueAdvance(int siteIid, {int queueId = 1}) => _rpc<ResSiteQueueAdvance>(
        WsReq(siteQueueAdvance: ReqSiteQueueAdvance(siteIid: Int64(siteIid), queueId: Int64(queueId))),
        (res) => res.siteQueueAdvance,
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

  Future<ResBotPeerCreate> botPeerCreate(int botIid, {String title = ''}) => _rpc<ResBotPeerCreate>(
        WsReq(botPeerCreate: ReqBotPeerCreate(botIid: Int64(botIid), title: title)),
        (res) => res.botPeerCreate,
      );

  Future<ResBotPeerAppSend> botPeerAppSend(int chatId, String text, {String attachmentsJson = '[]'}) => _rpc<ResBotPeerAppSend>(
        WsReq(botPeerAppSend: ReqBotPeerAppSend(chatId: Int64(chatId), text: text, attachmentsJson: attachmentsJson)),
        (res) => res.botPeerAppSend,
      );

  Future<ResBotPeerDelete> botPeerDelete(int chatId) => _rpc<ResBotPeerDelete>(
        WsReq(botPeerDelete: ReqBotPeerDelete(chatId: Int64(chatId))),
        (res) => res.botPeerDelete,
      );

  Future<ResDataSourceList> dataSourceList({int botIid = 0, int sinceUpdatedTsMs = 0, int limit = 100}) =>
      _rpc<ResDataSourceList>(
        WsReq(
          dataSourceList: ReqDataSourceList(
            botIid: Int64(botIid),
            sinceUpdatedTsMs: Int64(sinceUpdatedTsMs),
            limit: limit,
          ),
        ),
        (res) => res.dataSourceList,
      );

  Future<ResDataSourcePut> dataSourcePut(DataSourceDoc doc) => _rpc<ResDataSourcePut>(
        WsReq(dataSourcePut: ReqDataSourcePut(doc: doc)),
        (res) => res.dataSourcePut,
      );

  Future<ResDataSourceDelete> dataSourceDelete(int id) => _rpc<ResDataSourceDelete>(
        WsReq(dataSourceDelete: ReqDataSourceDelete(id: Int64(id))),
        (res) => res.dataSourceDelete,
      );

  Future<ResDataSourceSync> dataSourceSync(int id) => _rpc<ResDataSourceSync>(
        WsReq(dataSourceSync: ReqDataSourceSync(id: Int64(id))),
        (res) => res.dataSourceSync,
      );

  Future<ResDataSourceCheck> dataSourceCheck({required String sourceKind, required String viewUrl}) =>
      _rpc<ResDataSourceCheck>(
        WsReq(dataSourceCheck: ReqDataSourceCheck(sourceKind: sourceKind, viewUrl: viewUrl)),
        (res) => res.dataSourceCheck,
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

  Future<ResNotifyList> notifyList({int limit = 20, bool unreadOnly = false}) => _rpc<ResNotifyList>(
        WsReq(notifyList: ReqNotifyList(limit: limit, unreadOnly: unreadOnly)),
        (res) => res.notifyList,
      );

  Future<ResNotifyRead> notifyRead({List<int> ids = const []}) => _rpc<ResNotifyRead>(
        WsReq(notifyRead: ReqNotifyRead(ids: [for (final id in ids) Int64(id)])),
        (res) => res.notifyRead,
      );

  Future<void> notifyTokenPut({required String clientId, required String token, required String platform}) async {
    await _rpc<ResNotifyTokenPut>(
      WsReq(notifyTokenPut: ReqNotifyTokenPut(clientId: clientId, token: token, platform: platform)),
      (res) => res.notifyTokenPut,
    );
  }

  Future<void> appPresence({required String clientId, required bool resumed}) async {
    await _rpc<ResAppPresence>(
      WsReq(appPresence: ReqAppPresence(clientId: clientId, resumed: resumed)),
      (res) => res.appPresence,
    );
  }

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
    bool talk = false,
    bool replaceLastTurn = false,
  }) async* {
    if (_ch == null || status.value != ChatConnStatus.connected) {
      if (_ch != null && (status.value == ChatConnStatus.connecting || status.value == ChatConnStatus.reconnecting)) {
        try {
          await _waitSocketReady(_socketGen);
        } catch (_) {}
      }
      if (_ch == null || status.value != ChatConnStatus.connected) {
        try {
          await reconnect();
        } catch (_) {}
      }
    }
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
        talk: talk,
        replaceLastTurn: replaceLastTurn,
      ),
    );
    if (!_trySend(req)) {
      _scheduleReconnectIfNeeded();
      if (!ctrl.isClosed) ctrl.add(PromptStreamEvent.fail(uiConnectionFailed));
      _promptPending.remove(id);
      if (!ctrl.isClosed) await ctrl.close();
    }
    yield* ctrl.stream;
  }
}
