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
  var _search = '';
  final _bots = <IdentityListRow>[];
  final _peers = <Chat>[];
  final _msgs = <int, List<MsgRow>>{};
  String? _selectedBotId;
  String? _selectedChatId;

  bool get loadingBots => _loadingBots;
  bool get loadingPeers => _loadingPeers;
  bool get loadingMsgs => _loadingMsgs;
  bool get sending => _sending;
  String get search => _search;
  List<IdentityListRow> get bots => List.unmodifiable(_bots);

  List<IdentityListRow> get filtered {
    final q = _search.trim().toLowerCase();
    return _bots.where((r) {
      if (r.archivedTsMs.toInt() > 0) return false;
      if (q.isEmpty) return true;
      final id = r.identity;
      return id.name.toLowerCase().contains(q) || id.alienId.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  void searchPut(String value) {
    if (_search == value) return;
    _search = value;
    notifyListeners();
  }

  void _sortBots() => _bots.sort((a, b) {
        final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
        if (pin != 0) return pin;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return b.identity.updatedTsMs.compareTo(a.identity.updatedTsMs);
      });
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
      if (_selectedChatId == cid.toString()) {
        _msgPut(m);
      } else if (_selectedBotId != null) {
        final peer = peerById(cid.toString());
        if (peer != null) {
          if (m.content.isNotEmpty) peer.lastMsgPreview = m.content.length > 120 ? '${m.content.substring(0, 120)}…' : m.content;
          if (m.createdTsMs.toInt() > 0) peer.lastMsgTsMs = m.createdTsMs;
          notifyListeners();
        } else {
          unawaited(refreshPeers());
        }
      }
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
      final res = await identityList(_conn, const ['bot']);
      _bots
        ..clear()
        ..addAll(res.rows);
      _sortBots();
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

  Future<void> archivePut(String id, bool archived) => _grantPatch(id, ReqIdentityGrantPatch(resourceIid: Int64.parseInt(id), archived: archived));

  Future<void> reorderPut(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0 || oldIndex >= _bots.length || newIndex >= _bots.length) return;
    final item = _bots.removeAt(oldIndex);
    _bots.insert(newIndex, item);
    notifyListeners();
    try {
      for (var i = 0; i < _bots.length; i++) {
        final row = _bots[i];
        final botId = row.identity.iid.toString();
        await _grantPatch(botId, ReqIdentityGrantPatch(resourceIid: row.identity.iid, sortOrder: (i + 1) * 10), notify: i == _bots.length - 1);
      }
    } catch (e) {
      lError('bot reorder: $e');
      await refreshBots();
      rethrow;
    }
  }

  Future<void> botDelete(String id) async {
    final iid = int.tryParse(id) ?? 0;
    if (iid <= 0) return;
    try {
      await ensureConnected();
      await identityDelete(_conn, iid);
      _bots.removeWhere((b) => b.identity.iid.toString() == id);
      if (_selectedBotId == id) {
        _selectedBotId = _bots.isNotEmpty ? _bots.first.identity.iid.toString() : null;
        _selectedChatId = null;
        _peers.clear();
        if (_selectedBotId != null) await refreshPeers();
      }
      notifyListeners();
    } catch (e) {
      lError('bot delete: $e');
      rethrow;
    }
  }

  Future<void> _grantPatch(String id, ReqIdentityGrantPatch req, {bool notify = true}) async {
    try {
      await ensureConnected();
      final res = await identityGrantPatch(_conn, req);
      final i = _bots.indexWhere((r) => r.identity.iid.toString() == id);
      if (i >= 0) {
        _bots[i] = res.row;
      } else {
        _bots.add(res.row);
      }
      if (req.hasArchived() && req.archived) {
        _bots.removeWhere((r) => r.identity.iid.toString() == id);
        if (_selectedBotId == id) {
          _selectedBotId = _bots.isNotEmpty ? _bots.first.identity.iid.toString() : null;
          _selectedChatId = null;
          _peers.clear();
        }
      }
      _sortBots();
      if (notify) notifyListeners();
    } catch (e) {
      lError('bot grant patch: $e');
      rethrow;
    }
  }
}
