import 'dart:async';

import 'package:alienai_c35/c/bot/bot_api.dart';
import 'package:alienai_c35/c/channel/channel_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/bots/in_bot_create.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

String botPeerTimeLabel(Int64 tsMs) {
  final ms = tsMs.toInt();
  if (ms <= 0) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.month}/${dt.day}';
}

class BotStore extends ChangeNotifier {
  BotStore({ChatConn? conn}) : _conn = conn ?? ChatConn();

  final ChatConn _conn;
  StreamSubscription<SyncPush>? _syncSub;

  ChatConn get conn => _conn;

  var _loadingBots = false;
  var _loadingPeers = false;
  var _loadingMsgs = false;
  var _sending = false;
  final _bots = <IdentityListRow>[];
  final _peers = <Chat>[];
  final _msgs = <int, List<MsgRow>>{};
  String? _selectedBotId;
  String? _selectedChatId;

  bool get loadingBots => _loadingBots;
  bool get loadingPeers => _loadingPeers;
  bool get loadingMsgs => _loadingMsgs;
  bool get sending => _sending;
  List<IdentityListRow> get bots => List.unmodifiable(_bots);
  List<Chat> get peers => List.unmodifiable(_peers);
  String? get selectedBotId => _selectedBotId;
  String? get selectedChatId => _selectedChatId;

  List<MsgRow> msgsFor(String? chatId) {
    if (chatId == null) return const [];
    final id = int.tryParse(chatId) ?? 0;
    return List.unmodifiable(_msgs[id] ?? const []);
  }

  Chat? peerById(String? chatId) {
    if (chatId == null) return null;
    for (final c in _peers) {
      if (c.id.toString() == chatId) return c;
    }
    return null;
  }

  IdentityListRow? botById(String? botId) {
    if (botId == null) return null;
    for (final b in _bots) {
      if (b.identity.iid.toString() == botId) return b;
    }
    return null;
  }

  void attach() {
    _syncSub ??= _conn.onSyncPush.listen(_onSyncPush);
  }

  void detach() {
    unawaited(_syncSub?.cancel());
    _syncSub = null;
  }

  void _onSyncPush(SyncPush push) {
    if (push.hasChatMsg()) {
      final m = push.chatMsg;
      final cid = m.chatId.toInt();
      if (_selectedChatId == cid.toString()) _msgPut(m);
    }
    if (push.hasChatMember()) {
      final m = push.chatMember;
      final i = _peers.indexWhere((c) => c.id == m.chatId);
      if (i >= 0) {
        final c = _peers[i];
        if (m.lastMsgPreview.isNotEmpty) c.lastMsgPreview = m.lastMsgPreview;
        if (m.lastMsgTsMs.toInt() > 0) c.lastMsgTsMs = m.lastMsgTsMs;
        notifyListeners();
      }
    }
  }

  void _msgPut(ChatMsg m) {
    final role = switch (m.role) {
      ChatMsgRole.CHAT_MSG_ROLE_USER => 'user',
      ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT => 'assistant',
      ChatMsgRole.CHAT_MSG_ROLE_SYSTEM => 'system',
      _ => 'assistant',
    };
    final row = MsgRow(
      id: m.id.toInt(),
      chatId: m.chatId.toInt(),
      role: role,
      content: m.content,
      thought: m.thought,
      attachmentsJson: m.attachmentsJson,
      blocksJson: m.blocksJson,
      reqId: m.reqId,
      tokensIn: m.tokensIn,
      tokensOut: m.tokensOut,
      durationMs: m.durationMs,
      costUsd: m.costUsd,
      createdAtMs: m.createdTsMs.toInt(),
    );
    final list = _msgs.putIfAbsent(row.chatId, () => []);
    final i = list.indexWhere((x) => x.id == row.id);
    if (i >= 0) {
      list[i] = row;
    } else {
      list.add(row);
      list.sort((a, b) => a.id.compareTo(b.id));
    }
    notifyListeners();
  }

  Future<void> ensureConnected({String locale = 'en'}) async {
    if (_conn.connected) return;
    await _conn.connect(locale: locale);
  }

  Future<InBotCreateResult?> showCreateBot(BuildContext context) => inBotCreateShow(
        context,
        store: this,
        onIdentityPut: (ReqIdentityPut req) => identityPut(_conn, req),
        onTelegramConnect: channelTelegramConnectFn(_conn),
        onWhatsappMetaConnect: channelWhatsappMetaConnectFn(_conn),
        onWhatsappPairStart: channelWhatsappPairStartFn(_conn),
        onWhatsappPairWatch: channelWhatsappPairWatchFn(_conn),
        onWhatsappPairAbort: channelWhatsappPairAbortFn(_conn),
      );

  Future<void> botCreatedSelect(InBotCreateResult created) async {
    await refreshBots();
    await botSelect(created.botIid.toString());
  }

  Future<void> refreshBots() async {
    _loadingBots = true;
    notifyListeners();
    try {
      await ensureConnected();
      final res = await _conn.identityList(const ['bot']);
      _bots
        ..clear()
        ..addAll(res.rows);
      if (_selectedBotId != null && botById(_selectedBotId) == null) _selectedBotId = null;
      if (_selectedBotId == null && _bots.isNotEmpty) _selectedBotId = _bots.first.identity.iid.toString();
      if (_selectedBotId != null) await refreshPeers();
    } catch (e) {
      lError('bot list: $e');
    } finally {
      _loadingBots = false;
      notifyListeners();
    }
  }

  Future<void> botSelect(String? id) async {
    if (_selectedBotId == id) return;
    _selectedBotId = id;
    _selectedChatId = null;
    _peers.clear();
    notifyListeners();
    if (id != null) await refreshPeers();
  }

  Future<void> refreshPeers() async {
    final botId = _selectedBotId;
    if (botId == null) return;
    final iid = int.tryParse(botId) ?? 0;
    if (iid <= 0) return;
    _loadingPeers = true;
    notifyListeners();
    try {
      await ensureConnected();
      final res = await _conn.botPeerList(iid);
      _peers
        ..clear()
        ..addAll(res.chats);
      if (_selectedChatId != null && peerById(_selectedChatId) == null) _selectedChatId = null;
    } catch (e) {
      lError('bot peers: $e');
    } finally {
      _loadingPeers = false;
      notifyListeners();
    }
  }

  Future<void> chatSelect(String? id) async {
    if (_selectedChatId == id) return;
    _selectedChatId = id;
    notifyListeners();
    if (id != null) await loadMessages(id);
  }

  Future<void> loadMessages(String chatId) async {
    final id = int.tryParse(chatId) ?? 0;
    if (id <= 0) return;
    _loadingMsgs = true;
    notifyListeners();
    try {
      await ensureConnected();
      final res = await _conn.chatMsgList(chatId: Int64(id));
      final list = <MsgRow>[];
      for (final m in res.messages) {
        final role = switch (m.role) {
          ChatMsgRole.CHAT_MSG_ROLE_USER => 'user',
          ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT => 'assistant',
          ChatMsgRole.CHAT_MSG_ROLE_SYSTEM => 'system',
          _ => 'assistant',
        };
        list.add(MsgRow(
          id: m.id.toInt(),
          chatId: m.chatId.toInt(),
          role: role,
          content: m.content,
          thought: m.thought,
          attachmentsJson: m.attachmentsJson,
          blocksJson: m.blocksJson,
          reqId: m.reqId,
          tokensIn: m.tokensIn,
          tokensOut: m.tokensOut,
          durationMs: m.durationMs,
          costUsd: m.costUsd,
          createdAtMs: m.createdTsMs.toInt(),
        ));
      }
      list.sort((a, b) => a.id.compareTo(b.id));
      _msgs[id] = list;
    } catch (e) {
      lError('bot msgs: $e');
    } finally {
      _loadingMsgs = false;
      notifyListeners();
    }
  }

  Future<void> chatStopToggle(String chatId) async {
    final peer = peerById(chatId);
    if (peer == null) return;
    final id = int.tryParse(chatId) ?? 0;
    if (id <= 0) return;
    final stopped = peer.aiReplyEnabled;
    try {
      await ensureConnected();
      final res = await _conn.chatStop(id, stopped);
      peer.aiReplyEnabled = res.aiReplyEnabled;
      notifyListeners();
    } catch (e) {
      lError('chat stop: $e');
      rethrow;
    }
  }

  Future<void> chatSend(String chatId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final id = int.tryParse(chatId) ?? 0;
    if (id <= 0) return;
    _sending = true;
    notifyListeners();
    try {
      await ensureConnected();
      final res = await _conn.chatSend(id, trimmed);
      if (res.hasMessage()) _msgPut(res.message);
      final peer = peerById(chatId);
      if (peer != null) {
        peer.lastMsgPreview = trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
        peer.lastMsgTsMs = Int64(DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      lError('chat send: $e');
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
