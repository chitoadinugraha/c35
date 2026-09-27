import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

int chatMetaBoundDeviceIid(String metaJson) {
  if (metaJson.trim().isEmpty) return 0;
  try {
    final m = (jsonDecode(metaJson) as Map).cast<String, dynamic>();
    final v = m['bound_device_iid'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  } catch (_) {
    return 0;
  }
}

List<String> chatMetaStickyMentionIds(String metaJson) {
  if (metaJson.trim().isEmpty) return const [];
  try {
    final m = (jsonDecode(metaJson) as Map).cast<String, dynamic>();
    final raw = m['sticky_mention_ids'];
    if (raw is! List) return const [];
    return [for (final e in raw) '$e'.trim()].where((e) => e.isNotEmpty).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String _prefsKeyActiveChat(int deviceIid) => 'device_prompt_active_chat_$deviceIid';

class DevicePromptContextStore extends ChangeNotifier {
  DevicePromptContextStore({
    required this.deviceIid,
    required this.deviceName,
    required this.chatConn,
  });

  final int deviceIid;
  final String deviceName;
  final ChatConn chatConn;

  var composerOpen = false;
  var loading = false;
  var messagesLoading = false;
  var streaming = false;
  var toolMode = 'agent';
  String? error;
  int? activeChatId;
  final contexts = <Chat>[];
  final membersByChatId = <int, ChatMember>{};
  final messages = <ChatMsg>[];
  String streamingTail = '';

  SharedPreferences? _prefs;
  var _msgsBeforeId = Int64.ZERO;
  var _msgsHasMore = false;

  Chat? get activeChat {
    final id = activeChatId;
    if (id == null) return null;
    for (final c in contexts) {
      if (c.id.toInt() == id) return c;
    }
    return null;
  }

  String get activeTitle {
    final c = activeChat;
    if (c == null) return deviceName;
    return c.title.isNotEmpty ? c.title : deviceName;
  }

  bool get sendEnabled => chatConn.connected && !streaming && activeChatId != null && activeChatId! > 0;

  Future<void> init() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final stored = _prefs!.getInt(_prefsKeyActiveChat(deviceIid));
      await _contextListReload();
      if (contexts.isEmpty) {
        await contextCreate();
      } else {
        final ids = contexts.map((c) => c.id.toInt()).toSet();
        if (stored != null && ids.contains(stored)) {
          await contextSelect(stored, persist: false);
        } else {
          await contextSelect(contexts.first.id.toInt(), persist: false);
        }
      }
    } catch (e) {
      error = '$e';
      lError('device prompt init: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void composerOpenPut(bool open) {
    if (composerOpen == open) return;
    composerOpen = open;
    notifyListeners();
  }

  void toolModeToggle() {
    toolMode = toolMode == 'ask' ? 'agent' : 'ask';
    notifyListeners();
  }

  Future<void> _contextListReload() async {
    final res = await chatConn.chatDeviceContextList(deviceIid: Int64(deviceIid), includeArchived: true, limit: 50);
    contexts
      ..clear()
      ..addAll(res.chats);
    membersByChatId
      ..clear()
      ..addEntries([for (final m in res.members) MapEntry(m.chatId.toInt(), m)]);
    notifyListeners();
  }

  Future<void> contextCreate({String title = ''}) async {
    await chatConn.chatDeviceContextCreate(deviceIid: Int64(deviceIid), title: title);
    await _contextListReload();
    final newest = contexts.isNotEmpty ? contexts.first.id.toInt() : 0;
    if (newest > 0) await contextSelect(newest);
  }

  Future<void> contextSelect(int chatId, {bool persist = true}) async {
    if (chatId <= 0) return;
    activeChatId = chatId;
    if (persist) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setInt(_prefsKeyActiveChat(deviceIid), chatId);
    }
    _msgsBeforeId = Int64.ZERO;
    messages.clear();
    streamingTail = '';
    notifyListeners();
    await messagesReload();
  }

  Future<void> messagesReload({bool loadMore = false}) async {
    final cid = activeChatId;
    if (cid == null || cid <= 0) return;
    if (messagesLoading) return;
    messagesLoading = true;
    notifyListeners();
    try {
      final before = loadMore ? _msgsBeforeId : Int64.ZERO;
      final res = await chatConn.chatMsgList(chatId: Int64(cid), beforeId: before, limit: 80);
      final batch = res.messages.toList();
      if (batch.isNotEmpty) {
        _msgsBeforeId = batch.last.id;
        _msgsHasMore = batch.length >= 80;
      } else {
        _msgsHasMore = false;
      }
      if (loadMore && batch.isNotEmpty) {
        messages.insertAll(0, batch);
      } else if (!loadMore) {
        messages
          ..clear()
          ..addAll(batch);
      }
      messages.sort((a, b) => a.createdTsMs.compareTo(b.createdTsMs));
    } catch (e) {
      lError('device prompt msgs: $e');
    } finally {
      messagesLoading = false;
      notifyListeners();
    }
  }

  bool get messagesCanLoadMore => _msgsHasMore;

  Future<void> promptSend(String text, {String? toolMode}) async {
    final trimmed = text.trim();
    final turnToolMode = toolMode ?? this.toolMode;
    final cid = activeChatId;
    if (trimmed.isEmpty || cid == null || cid <= 0 || streaming) return;
    if (!chatConn.connected) return;

    final member = membersByChatId[cid];
    if (member != null && member.archivedTsMs > Int64.ZERO) {
      try {
        await chatConn.chatPatch(chatId: Int64(cid), archived: false);
      } catch (e) {
        lError('device prompt unarchive: $e');
      }
    }

    final reqId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    messages.add(
      ChatMsg(
        id: Int64(now),
        chatId: Int64(cid),
        role: ChatMsgRole.CHAT_MSG_ROLE_USER,
        content: trimmed,
        createdTsMs: Int64(now),
        reqId: reqId,
      ),
    );
    messages.add(
      ChatMsg(
        id: Int64(now + 1),
        chatId: Int64(cid),
        role: ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT,
        content: '',
        createdTsMs: Int64(now + 1),
        reqId: reqId,
      ),
    );
    streaming = true;
    streamingTail = '';
    error = null;
    notifyListeners();

    final stream = chatConn.promptSend(
      text: trimmed,
      chatId: Int64(cid),
      mentionIds: ['iid:$deviceIid'],
      deviceIids: [Int64(deviceIid)],
      toolMode: turnToolMode,
      locale: CatalogTranslationCache.instance.lang,
      reqId: reqId,
    );
    try {
      await for (final ev in stream) {
        if (ev.kind == 'start' && ev.chatId > Int64.ZERO) {
          final startId = ev.chatId.toInt();
          if (startId != cid) {
            activeChatId = startId;
            _prefs ??= await SharedPreferences.getInstance();
            await _prefs!.setInt(_prefsKeyActiveChat(deviceIid), startId);
          }
          continue;
        }
        if (ev.kind == 'delta' && !ev.thought) {
          streamingTail += ev.text;
          final i = messages.indexWhere((m) => m.reqId == reqId && m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT);
          if (i >= 0) messages[i].content = streamingTail;
          notifyListeners();
          continue;
        }
        if (ev.kind == 'end' && ev.end != null) {
          final i = messages.indexWhere((m) => m.reqId == reqId && m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT);
          if (i >= 0 && ev.end!.msgId > Int64.ZERO) messages[i].id = ev.end!.msgId;
          continue;
        }
        if (ev.kind == 'fail') {
          error = ev.message;
          final i = messages.indexWhere((m) => m.reqId == reqId && m.role == ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT);
          if (i >= 0) messages[i].errorText = ev.message;
        }
      }
    } catch (e) {
      error = '$e';
      lError('device prompt send: $e');
    } finally {
      streaming = false;
      streamingTail = '';
      notifyListeners();
      unawaited(_contextListReload());
    }
  }
}
