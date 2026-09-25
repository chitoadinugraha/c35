import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/hint/hint_store.dart';
import 'package:alienai_c35/c/mention/mention_catalog.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/settings/user_locale_prefs.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chatRowsKey = 'c35_chat_rows';
String _chatMsgsKey(int chatId) => 'c35_chat_msgs_$chatId';

bool msgHasBody(MsgRow m) =>
    (m.role == 'user' && (m.content.trim().isNotEmpty || m.attachments.isNotEmpty)) ||
    (m.role == 'assistant' && (m.content.trim().isNotEmpty || m.thought.trim().isNotEmpty || m.blocksJson.trim().isNotEmpty));

MsgRow _bestAssistantForTurn(List<MsgRow> assistants) {
  for (var i = assistants.length - 1; i >= 0; i--) {
    final m = assistants[i];
    if (m.error.trim().isEmpty && msgHasBody(m)) return m;
  }
  return assistants.last;
}

int _msgRoleOrder(String role) => switch (role) {
      'user' => 0,
      'assistant' => 1,
      _ => 2,
    };

/// Chronological order for one chat: time, then snowflake id, then user before assistant.
int msgOrderCompare(MsgRow a, MsgRow b) {
  final ta = a.createdAtMs;
  final tb = b.createdAtMs;
  if (ta > 0 && tb > 0) {
    final byTime = ta.compareTo(tb);
    if (byTime != 0) return byTime;
  }
  final byId = (a.id < 0 && b.id < 0) ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
  if (byId != 0) return byId;
  return _msgRoleOrder(a.role).compareTo(_msgRoleOrder(b.role));
}

List<MsgRow> msgsCollapseRetriedAssistants(List<MsgRow> chatMsgs) {
  final out = <MsgRow>[];
  var i = 0;
  while (i < chatMsgs.length) {
    final m = chatMsgs[i];
    if (m.role == 'user') {
      out.add(m);
      i++;
      final assistants = <MsgRow>[];
      while (i < chatMsgs.length && chatMsgs[i].role != 'user') {
        final row = chatMsgs[i++];
        if (row.role == 'assistant') {
          assistants.add(row);
        } else {
          out.add(row);
        }
      }
      if (assistants.isNotEmpty) out.add(_bestAssistantForTurn(assistants));
      continue;
    }
    out.add(m);
    i++;
  }
  return out;
}

String msgMergeText(String old, String incoming) {
  if (incoming.isEmpty) return old;
  if (old.isEmpty) return incoming;
  if (old == incoming) return old;
  if (incoming.startsWith(old)) return incoming;
  if (old.startsWith(incoming)) return old;
  return old.length >= incoming.length ? old : incoming;
}

class ChatRow {
  ChatRow({
    required this.id,
    required this.title,
    List<String>? tags,
    this.pinnedAt = 0,
    this.archivedAt = 0,
    this.lastMsgPreview = '',
    this.lastMsgAt = 0,
    this.pending = false,
    this.lastMsgStatus = 'done',
    this.unreadStatus = false,
    this.contextSummaryPresent = false,
  }) : tags = tags ?? const [];

  final int id;
  String title;
  List<String> tags;
  int pinnedAt;
  int archivedAt;
  String lastMsgPreview;
  int lastMsgAt;
  bool pending;
  String lastMsgStatus;
  bool unreadStatus;
  bool contextSummaryPresent;

  bool get pinned => pinnedAt > 0;
  bool get archived => archivedAt > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (tags.isNotEmpty) 'tags': tags,
        'pinnedAt': pinnedAt,
        'archivedAt': archivedAt,
        'lastMsgPreview': lastMsgPreview,
        'lastMsgAt': lastMsgAt,
        'pending': pending,
        'lastMsgStatus': lastMsgStatus,
        'unreadStatus': unreadStatus,
        'contextSummaryPresent': contextSummaryPresent,
      };

  factory ChatRow.fromJson(Map<String, dynamic> j) => ChatRow(
        id: j['id'] as int? ?? 0,
        title: '${j['title'] ?? ''}',
        tags: j['tags'] is List ? [for (final t in j['tags'] as List) '$t'] : ('${j['tag'] ?? ''}'.isEmpty ? const <String>[] : ['${j['tag']}']),
        pinnedAt: j['pinnedAt'] as int? ?? 0,
        archivedAt: j['archivedAt'] as int? ?? 0,
        lastMsgPreview: '${j['lastMsgPreview'] ?? ''}',
        lastMsgAt: j['lastMsgAt'] as int? ?? 0,
        pending: j['pending'] as bool? ?? false,
        lastMsgStatus: '${j['lastMsgStatus'] ?? 'done'}',
        unreadStatus: j['unreadStatus'] as bool? ?? false,
        contextSummaryPresent: j['contextSummaryPresent'] as bool? ?? false,
      );
}

bool chatMetaContextSummaryPresent(String metaJson) {
  if (metaJson.isEmpty) return false;
  try {
    final m = jsonDecode(metaJson) as Map<String, dynamic>;
    return m['context_summary_present'] == true;
  } catch (_) {
    return false;
  }
}

class MsgRow {
  MsgRow({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    this.thought = '',
    this.attachmentsJson = '[]',
    this.blocksJson = '',
    this.traceJson = '',
    this.reqId = '',
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.durationMs = 0,
    this.costUsd = 0,
    this.model = '',
    this.error = '',
    this.createdAtMs = 0,
    List<MsgAttachment>? attachments,
  }) : attachments = attachments ?? const [];

  final int id;
  final int chatId;
  final String role;
  String content;
  String thought;
  String attachmentsJson;
  String blocksJson;
  String traceJson;
  String reqId;
  int tokensIn;
  int tokensOut;
  int durationMs;
  double costUsd;
  String model;
  String error;
  int createdAtMs;
  List<MsgAttachment> attachments;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'role': role,
        'content': content,
        'thought': thought,
        'attachmentsJson': attachmentsJson.isNotEmpty ? attachmentsJson : MsgAttachment.encode(attachments),
        'blocksJson': blocksJson,
        'traceJson': traceJson,
        'reqId': reqId,
        'tokensIn': tokensIn,
        'tokensOut': tokensOut,
        'durationMs': durationMs,
        'costUsd': costUsd,
        if (model.isNotEmpty) 'model': model,
        if (error.isNotEmpty) 'error': error,
        'createdAtMs': createdAtMs,
      };

  factory MsgRow.fromJson(Map<String, dynamic> j) {
    final attachmentsRaw = '${j['attachmentsJson'] ?? '[]'}';
    return MsgRow(
      id: j['id'] as int? ?? 0,
      chatId: j['chatId'] as int? ?? 0,
      role: '${j['role'] ?? ''}',
      content: '${j['content'] ?? ''}',
      thought: '${j['thought'] ?? ''}',
      attachmentsJson: attachmentsRaw,
      blocksJson: '${j['blocksJson'] ?? ''}',
      traceJson: '${j['traceJson'] ?? ''}',
      reqId: '${j['reqId'] ?? ''}',
      tokensIn: j['tokensIn'] as int? ?? 0,
      tokensOut: j['tokensOut'] as int? ?? 0,
      durationMs: j['durationMs'] as int? ?? 0,
      costUsd: (j['costUsd'] as num?)?.toDouble() ?? 0,
      model: '${j['model'] ?? ''}',
      error: '${j['error'] ?? ''}',
      createdAtMs: j['createdAtMs'] as int? ?? 0,
      attachments: MsgAttachment.decode(attachmentsRaw),
    );
  }

  MsgRow copyWith({
    int? id,
    int? chatId,
    String? role,
    String? content,
    String? thought,
    String? attachmentsJson,
    String? blocksJson,
    String? traceJson,
    String? reqId,
    int? tokensIn,
    int? tokensOut,
    int? durationMs,
    double? costUsd,
    String? model,
    String? error,
    int? createdAtMs,
    List<MsgAttachment>? attachments,
  }) =>
      MsgRow(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        role: role ?? this.role,
        content: content ?? this.content,
        thought: thought ?? this.thought,
        attachmentsJson: attachmentsJson ?? this.attachmentsJson,
        blocksJson: blocksJson ?? this.blocksJson,
        traceJson: traceJson ?? this.traceJson,
        reqId: reqId ?? this.reqId,
        tokensIn: tokensIn ?? this.tokensIn,
        tokensOut: tokensOut ?? this.tokensOut,
        durationMs: durationMs ?? this.durationMs,
        costUsd: costUsd ?? this.costUsd,
        model: model ?? this.model,
        error: error ?? this.error,
        createdAtMs: createdAtMs ?? this.createdAtMs,
        attachments: attachments ?? this.attachments,
      );
}

class ChatStore extends ChangeNotifier {
  ChatStore() {
    unawaited(load());
  }

  List<ChatRow> chats = [];
  List<MsgRow> msgs = [];
  List<AgentModel> models = const [AgentModel.alien];
  NavCounts navCounts = NavCounts();
  String search = '';
  bool archivedOpen = false;
  int? activeChatId;
  bool promptBusy = false;
  int? promptChatId;
  int promptStartedAtMs = 0;
  String? pendingPromptReqId;
  final Set<int> _deletingChatIds = {};

  bool promptBusyFor(int? chatId) => promptBusy && chatId != null && chatId == promptChatId;

  bool chatDeletingFor(int id) => _deletingChatIds.contains(id);

  void chatDeletingPut(int id, bool deleting) {
    if (deleting) {
      if (!_deletingChatIds.add(id)) return;
    } else if (!_deletingChatIds.remove(id)) {
      return;
    }
    notifyListeners();
  }

  int _nextLocalId = -1;
  int msgNextLocalId() => _nextLocalId--;
  SharedPreferences? _prefs;
  var _loaded = false;

  int _chatCmp(ChatRow a, ChatRow b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final t = b.lastMsgAt.compareTo(a.lastMsgAt);
    return t != 0 ? t : b.id.compareTo(a.id);
  }

  bool _chatStarted(ChatRow c) => c.lastMsgPreview.trim().isNotEmpty || msgs.any((m) => m.chatId == c.id && msgHasBody(m));

  bool _searchHit(ChatRow c, String q) {
    if (q.isEmpty) return true;
    final title = c.title.toLowerCase();
    if (q.startsWith('#')) {
      final tag = q.substring(1);
      if (tag.isEmpty) return title.contains('#');
      return title.contains(q) || c.tags.contains(tag) || title.contains('#$tag');
    }
    if (title.contains(q) || c.tags.any((t) => t.contains(q))) return true;
    if (c.lastMsgPreview.toLowerCase().contains(q)) return true;
    return msgs.any((m) => m.chatId == c.id && m.content.toLowerCase().contains(q));
  }

  String searchSnippetFor(int chatId, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return '';
    for (final m in msgs.reversed) {
      if (m.chatId != chatId) continue;
      final lower = m.content.toLowerCase();
      final idx = lower.indexOf(q);
      if (idx >= 0) {
        final start = (idx - 20).clamp(0, m.content.length);
        final end = (idx + q.length + 40).clamp(0, m.content.length);
        final prefix = start > 0 ? '…' : '';
        final suffix = end < m.content.length ? '…' : '';
        return '$prefix${m.content.substring(start, end).replaceAll('\n', ' ')}$suffix';
      }
    }
    return '';
  }

  List<String> get recentUserPrompts {
    final seen = <String>{};
    final result = <String>[];
    for (final m in msgs.reversed) {
      if (m.role != 'user') continue;
      final text = m.content.trim();
      if (text.isNotEmpty && seen.add(text)) {
        result.add(text);
        if (result.length >= 50) break;
      }
    }
    return result;
  }

  List<ChatRow> get visibleChats {
    final q = search.trim().toLowerCase();
    final out = chats.where((c) => !c.archived && _chatStarted(c) && _searchHit(c, q)).toList();
    out.sort(_chatCmp);
    return out;
  }

  List<ChatRow> get archivedChats {
    final q = search.trim().toLowerCase();
    final out = chats.where((c) => c.archived && _chatStarted(c) && _searchHit(c, q)).toList();
    out.sort((a, b) => b.lastMsgAt.compareTo(a.lastMsgAt));
    return out;
  }

  List<MsgRow> get activeMsgs {
    final id = activeChatId;
    if (id == null) return const [];
    final chatMsgs = [for (final m in msgs) if (m.chatId == id) m];
    chatMsgs.sort(msgOrderCompare);
    return msgsCollapseRetriedAssistants(chatMsgs);
  }

  final Set<int> _tombstonedMsgIds = {};

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_chatRowsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final rows = jsonDecode(raw) as List;
        chats = [for (final item in rows) if (item is Map) ChatRow.fromJson(Map<String, dynamic>.from(item))];
      } catch (_) {}
    }
    final loadedMsgs = <MsgRow>[];
    for (final c in chats) {
      final key = _chatMsgsKey(c.id);
      final msgRaw = _prefs!.getString(key);
      if (msgRaw == null || msgRaw.isEmpty) continue;
      try {
        final rows = jsonDecode(msgRaw) as List;
        loadedMsgs.addAll([for (final item in rows) if (item is Map) MsgRow.fromJson(Map<String, dynamic>.from(item))]);
      } catch (_) {}
    }
    msgs = loadedMsgs;
    for (final cid in loadedMsgs.map((m) => m.chatId).toSet()) {
      _msgsSortChat(cid);
    }
    chatStatusStaleClear();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistChats() async {
    if (!_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_chatRowsKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
  }

  Future<void> _persistMsgs(int chatId) async {
    if (!_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final rows = msgs.where((m) => m.chatId == chatId).map((m) => m.toJson()).toList();
    await _prefs!.setString(_chatMsgsKey(chatId), jsonEncode(rows));
  }

  Timer? _msgPersistDebounce;
  final Set<int> _dirtyMsgChatIds = {};

  void _debouncePersistMsgs(int chatId) {
    _dirtyMsgChatIds.add(chatId);
    if (_msgPersistDebounce?.isActive ?? false) return;
    _msgPersistDebounce = Timer(const Duration(milliseconds: 1200), () {
      _flushDirtyMsgs();
    });
  }

  void _flushDirtyMsgs() {
    _msgPersistDebounce?.cancel();
    _msgPersistDebounce = null;
    for (final cid in _dirtyMsgChatIds) {
      unawaited(_persistMsgs(cid));
    }
    _dirtyMsgChatIds.clear();
  }

  void _touch() {
    unawaited(_persistChats());
    notifyListeners();
  }

  void _msgsSortChat(int chatId) {
    final indices = <int>[];
    for (var i = 0; i < msgs.length; i++) {
      if (msgs[i].chatId == chatId) indices.add(i);
    }
    if (indices.length < 2) return;
    final sorted = indices.map((i) => msgs[i]).toList()..sort(msgOrderCompare);
    for (var j = 0; j < indices.length; j++) {
      msgs[indices[j]] = sorted[j];
    }
  }

  void _touchMsgs(int chatId, {bool debounce = false}) {
    _msgsSortChat(chatId);
    if (debounce) {
      _debouncePersistMsgs(chatId);
    } else {
      _dirtyMsgChatIds.remove(chatId);
      unawaited(_persistMsgs(chatId));
    }
    notifyListeners();
  }

  void msgBlockCollapsedPut({required int msgId, required int blockIndex, required bool collapsed}) {
    final i = msgs.indexWhere((m) => m.id == msgId);
    if (i < 0) return;
    final m = msgs[i];
    final blocks = ChatBlock.decodeList(m.blocksJson);
    if (blockIndex < 0 || blockIndex >= blocks.length) return;
    final old = blocks[blockIndex];
    if (old.collapsed == collapsed) return;
    blocks[blockIndex] = ChatBlock(kind: old.kind, collapsed: collapsed, body: old.body);
    msgs[i] = m.copyWith(blocksJson: ChatBlock.encodeList(blocks));
    _touchMsgs(m.chatId);
  }

  void chatSelect(int id) {
    activeChatId = id;
    for (final c in chats) {
      if (c.id == id && c.unreadStatus) {
        c.unreadStatus = false;
        _touch();
        return;
      }
    }
    notifyListeners();
  }

  void _chatStatusPut(int chatId, {required String status, bool? unread}) {
    for (final c in chats) {
      if (c.id != chatId) continue;
      c.lastMsgStatus = status;
      if (unread != null) c.unreadStatus = unread;
      _touch();
      return;
    }
  }

  void chatStatusStaleClear({int? chatId}) {
    var changed = false;
    for (final c in chats) {
      if (chatId != null && c.id != chatId) continue;
      if (c.lastMsgStatus == 'streaming' && !promptBusyFor(c.id)) {
        c.lastMsgStatus = 'done';
        changed = true;
      }
    }
    if (changed) _touch();
  }

  bool get _chatDraftEmpty {
    final id = activeChatId;
    if (id == null) return true;
    return !msgs.any((m) => m.chatId == id && (m.role == 'user' || m.role == 'assistant') && m.content.trim().isNotEmpty);
  }

  void chatNew() {
    if (_chatDraftEmpty) return;
    activeChatId = null;
    notifyListeners();
  }

  int chatFork(int sourceChatId, {int? upToMsgId}) {
    ChatRow? sourceChat;
    for (final c in chats) {
      if (c.id == sourceChatId) {
        sourceChat = c;
        break;
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final newId = DateTime.now().microsecondsSinceEpoch;
    final baseTitle = sourceChat != null && sourceChat.title.isNotEmpty ? sourceChat.title : 'Forked chat';
    final forkTitle = '$baseTitle (fork)';

    final newChat = ChatRow(
      id: newId,
      title: forkTitle,
      pinnedAt: 0,
      archivedAt: 0,
      lastMsgPreview: sourceChat?.lastMsgPreview ?? '',
      lastMsgAt: now,
      lastMsgStatus: 'done',
      pending: false,
    );
    chats.insert(0, newChat);

    final sourceMsgs = msgs.where((m) => m.chatId == sourceChatId).toList();
    final pivotIdx = upToMsgId != null
        ? sourceMsgs.indexWhere((m) => m.id == upToMsgId)
        : sourceMsgs.length - 1;
    final copyRange = pivotIdx >= 0
        ? sourceMsgs.sublist(0, pivotIdx + 1)
        : sourceMsgs;

    for (final m in copyRange) {
      final copyMsg = m.copyWith(
        id: msgNextLocalId(),
        chatId: newId,
        createdAtMs: m.createdAtMs,
      );
      msgs.add(copyMsg);
    }

    activeChatId = newId;
    _touch();
    _touchMsgs(newId);
    return newId;
  }

  List<int> chatBelowIds(int pivotId) {
    final vis = visibleChats;
    final i = vis.indexWhere((c) => c.id == pivotId);
    if (i < 0 || i >= vis.length - 1) return const [];
    return [for (final c in vis.skip(i + 1)) c.id];
  }

  void chatPin(int id, {required bool pinned}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in chats) {
      if (c.id != id) continue;
      c.pinnedAt = pinned ? now : 0;
      if (pinned) c.archivedAt = 0;
    }
    _touch();
  }

  void chatArchive(List<int> ids, {required bool archived}) {
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in chats) {
      if (!ids.contains(c.id)) continue;
      c.archivedAt = archived ? now : 0;
      if (archived) c.pinnedAt = 0;
    }
    if (archived) archivedOpen = true;
    if (activeChatId != null && archived && ids.contains(activeChatId)) {
      activeChatId = visibleChats.isEmpty ? null : visibleChats.first.id;
    }
    _touch();
  }

  void chatTagsPut(int id, List<String> tags) {
    for (final c in chats) {
      if (c.id != id) continue;
      c.tags = [...tags];
    }
    _touch();
  }

  void chatDelete(int id) {
    chats.removeWhere((c) => c.id == id);
    msgs.removeWhere((m) => m.chatId == id);
    if (activeChatId == id) activeChatId = visibleChats.isEmpty ? null : visibleChats.first.id;
    if (promptChatId == id) _promptClear();
    unawaited(_prefs?.remove(_chatMsgsKey(id)));
    _touch();
  }

  void chatPatchApply(ResChatPatch res) {
    if (!res.hasChat() || !res.hasMember()) return;
    final chat = res.chat;
    final member = res.member;
    if (chat.deletedTsMs > 0 || member.deletedTsMs > 0) {
      chatDelete(chat.id.toInt());
      return;
    }
    chatPutFromServer(chat, member);
  }

  Future<void> chatPinRemote(ChatConn conn, int id, {required bool pinned}) async {
    chatPin(id, pinned: pinned);
    if (id <= 0) return;
    try {
      chatPatchApply(await conn.chatPatch(chatId: Int64(id), pinned: pinned));
    } catch (_) {}
  }

  Future<void> chatArchiveRemote(ChatConn conn, List<int> ids, {required bool archived}) async {
    chatArchive(ids, archived: archived);
    for (final id in ids) {
      if (id <= 0) continue;
      try {
        chatPatchApply(await conn.chatPatch(chatId: Int64(id), archived: archived));
      } catch (_) {}
    }
  }

  Future<void> chatTagsRemote(ChatConn conn, int id, List<String> tags) async {
    chatTagsPut(id, tags);
    if (id <= 0) return;
    try {
      chatPatchApply(await conn.chatPatch(chatId: Int64(id), tags: tags));
    } catch (_) {}
  }

  Future<void> chatDeleteRemote(ChatConn conn, int id) async {
    if (id <= 0) {
      chatDelete(id);
      return;
    }
    chatDeletingPut(id, true);
    if (activeChatId == id) {
      activeChatId = visibleChats.where((c) => c.id != id).map((c) => c.id).firstOrNull;
      notifyListeners();
    }
    try {
      final res = await conn.chatPatch(chatId: Int64(id), deleted: true);
      chatPatchApply(res);
    } catch (_) {
      chatDelete(id);
    } finally {
      chatDeletingPut(id, false);
    }
  }

  void searchPut(String q) {
    search = q;
    notifyListeners();
  }

  void archivedOpenPut(bool v) {
    archivedOpen = v;
    notifyListeners();
  }

  void chatTitlePut(int id, String title) {
    if (id == 0) return;
    final t = title.trim();
    if (t.isEmpty) return;
    final i = chats.indexWhere((c) => c.id == id);
    if (i < 0) return;
    chats[i].title = t;
    _touch();
  }

  void chatIdMigrate(int from, int to) {
    if (from == to || from == 0 || to == 0) return;
    msgs = [for (final m in msgs) m.chatId == from ? m.copyWith(chatId: to) : m];
    chats.removeWhere((c) => c.id == from);
    if (activeChatId == from) activeChatId = to;
    if (promptChatId == from) promptChatId = to;
    unawaited(_prefs?.remove(_chatMsgsKey(from)));
    unawaited(_persistMsgs(to));
    notifyListeners();
  }

  void chatPutFromServer(Chat chat, ChatMember member) {
    final id = chat.id.toInt();
    if (id == 0) return;
    final preview = member.lastMsgPreview.isNotEmpty ? member.lastMsgPreview : chat.lastMsgPreview;
    final lastAt = member.lastMsgTsMs.toInt() != 0 ? member.lastMsgTsMs.toInt() : chat.lastMsgTsMs.toInt();
    var status = member.lastMsgStatus.isNotEmpty ? member.lastMsgStatus : 'done';
    if (status == 'streaming' && !promptBusyFor(id)) status = 'done';
    final title = chat.title.isNotEmpty ? chat.title : chat.peerName;
    final existingIdx = chats.indexWhere((c) => c.id == id);
    final prevUnread = existingIdx >= 0 ? chats[existingIdx].unreadStatus : false;
    final unread = member.unreadCount > 0 || (prevUnread && id != activeChatId);
    final row = ChatRow(
      id: id,
      title: title.isNotEmpty ? title : 'Chat',
      tags: [...chat.tags],
      pinnedAt: member.pinnedTsMs.toInt(),
      archivedAt: member.archivedTsMs.toInt(),
      lastMsgPreview: preview,
      lastMsgAt: lastAt,
      pending: false,
      lastMsgStatus: status,
      unreadStatus: unread,
      contextSummaryPresent: chatMetaContextSummaryPresent(chat.metaJson),
    );
    final pendingIdx = chats.indexWhere((c) => c.pending && c.id != id);
    if (pendingIdx >= 0) {
      final old = chats[pendingIdx];
      msgs = [for (final m in msgs) m.chatId == old.id ? m.copyWith(chatId: id) : m];
      chats.removeAt(pendingIdx);
      if (activeChatId == old.id) activeChatId = id;
      if (promptChatId == old.id) promptChatId = id;
      unawaited(_prefs?.remove(_chatMsgsKey(old.id)));
      unawaited(_persistMsgs(id));
    }
    final i = chats.indexWhere((c) => c.id == id);
    if (i >= 0) {
      chats[i] = row;
    } else {
      chats.add(row);
    }
    _touch();
  }

  MsgRow? _turnAssistant({required int chatId, String reqId = ''}) {
    final rid = reqId.trim();
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.chatId != chatId || m.role != 'assistant') continue;
      if (rid.isNotEmpty && m.reqId.isNotEmpty && m.reqId != rid) continue;
      return m;
    }
    if (rid.isNotEmpty) return null;
    final i = msgs.lastIndexWhere((m) => m.chatId == chatId && m.role == 'assistant');
    return i >= 0 ? msgs[i] : null;
  }

  void msgStreamStart({int? chatId, String reqId = '', String model = ''}) {
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    _chatStatusPut(cid, status: 'streaming', unread: false);
    final rid = reqId.isNotEmpty ? reqId : (pendingPromptReqId ?? '');
    final m = _turnAssistant(chatId: cid, reqId: rid);
    if (m == null) return;
    if (rid.isNotEmpty) m.reqId = rid;
    if (model.isNotEmpty) m.model = model;
    _touchMsgs(cid);
  }

  bool _attachmentsExplicitEmpty(MsgRow row) => row.attachments.isEmpty && (row.attachmentsJson == '[]' || row.attachmentsJson.trim().isEmpty);

  List<MsgAttachment> _mergeAttachments(MsgRow old, MsgRow row) {
    if (row.id > 0) return row.attachments;
    if (row.attachments.isNotEmpty) return row.attachments;
    if (_attachmentsExplicitEmpty(row) && row.reqId.isNotEmpty && row.reqId == old.reqId) return const [];
    if (_attachmentsExplicitEmpty(row) && row.content.trim().isNotEmpty && row.content != old.content) return const [];
    return old.attachments;
  }

  String _mergeAttachmentsJson(MsgRow old, MsgRow row) {
    final merged = _mergeAttachments(old, row);
    if (merged.isEmpty) return '[]';
    if (row.attachmentsJson.isNotEmpty && merged.length == row.attachments.length) return row.attachmentsJson;
    return MsgAttachment.encode(merged);
  }

  String _mergeContent(MsgRow old, MsgRow row) {
    if (row.id > 0 && row.content.trim().isNotEmpty) return row.content;
    if (row.content.trim().isNotEmpty && row.reqId.isNotEmpty && row.reqId == old.reqId && row.content != old.content) return row.content;
    return msgMergeText(old.content, row.content);
  }

  MsgRow _msgMerge(MsgRow old, MsgRow row) => MsgRow(
        id: row.id != 0 ? row.id : old.id,
        chatId: row.chatId != 0 ? row.chatId : old.chatId,
        role: row.role.isNotEmpty ? row.role : old.role,
        content: _mergeContent(old, row),
        thought: msgMergeText(old.thought, row.thought),
        attachmentsJson: _mergeAttachmentsJson(old, row),
        blocksJson: row.blocksJson.isNotEmpty ? row.blocksJson : old.blocksJson,
        traceJson: row.traceJson.isNotEmpty ? row.traceJson : old.traceJson,
        reqId: row.reqId.isNotEmpty ? row.reqId : old.reqId,
        tokensIn: row.tokensIn > old.tokensIn ? row.tokensIn : old.tokensIn,
        tokensOut: row.tokensOut > old.tokensOut ? row.tokensOut : old.tokensOut,
        durationMs: row.durationMs > old.durationMs ? row.durationMs : old.durationMs,
        costUsd: row.costUsd > old.costUsd ? row.costUsd : old.costUsd,
        model: row.model.isNotEmpty ? row.model : old.model,
        error: row.error.isNotEmpty ? row.error : old.error,
        createdAtMs: row.createdAtMs > 0 ? row.createdAtMs : old.createdAtMs,
        attachments: _mergeAttachments(old, row),
      );

  void _chatPreviewTouch(int chatId, String preview, {int? atMs}) {
    for (final c in chats) {
      if (c.id != chatId) continue;
      c.lastMsgPreview = preview.trim().isEmpty ? c.lastMsgPreview : preview;
      final ts = atMs ?? 0;
      if (ts > 0) c.lastMsgAt = ts;
      c.pending = false;
    }
  }

  void msgPut(MsgRow row, {bool notify = true, bool touchPreview = true}) {
    if (row.chatId == 0) return;
    if (row.id > 0 && _tombstonedMsgIds.contains(row.id)) return;
    if (row.reqId.isNotEmpty) {
      final byReq = msgs.indexWhere((m) => m.reqId == row.reqId && m.role == row.role && m.chatId == row.chatId);
      if (byReq >= 0) {
        msgs[byReq] = _msgMerge(msgs[byReq], row);
        if (touchPreview) {
          _chatPreviewTouch(
            row.chatId,
            row.content,
            atMs: row.createdAtMs > 0 ? row.createdAtMs : DateTime.now().millisecondsSinceEpoch,
          );
        }
        if (notify) _touchMsgs(row.chatId);
        return;
      }
    }
    if (row.role == 'assistant') {
      bool sameTurn(MsgRow m) => row.reqId.isEmpty || m.reqId.isEmpty || m.reqId == row.reqId;
      var localIdx = msgs.lastIndexWhere((m) => m.chatId == row.chatId && m.role == 'assistant' && m.id <= 0 && sameTurn(m));
      if (localIdx < 0 && row.id > 0 && promptBusyFor(row.chatId)) {
        localIdx = msgs.lastIndexWhere((m) => m.chatId == row.chatId && m.role == 'assistant' && m.id != row.id && sameTurn(m));
      }
      if (localIdx >= 0) {
        msgs[localIdx] = _msgMerge(msgs[localIdx], row);
        if (touchPreview) {
          _chatPreviewTouch(
            row.chatId,
            row.content,
            atMs: row.createdAtMs > 0 ? row.createdAtMs : DateTime.now().millisecondsSinceEpoch,
          );
        }
        if (notify) _touchMsgs(row.chatId);
        return;
      }
    }
    final i = msgs.indexWhere((m) => m.id == row.id && row.id != 0);
    if (i >= 0) {
      msgs[i] = _msgMerge(msgs[i], row);
      if (touchPreview) {
        _chatPreviewTouch(
          row.chatId,
          row.content,
          atMs: row.createdAtMs > 0 ? row.createdAtMs : DateTime.now().millisecondsSinceEpoch,
        );
      }
      if (notify) _touchMsgs(row.chatId);
      return;
    }
    msgs.add(row);
    if (touchPreview) {
      _chatPreviewTouch(
        row.chatId,
        row.content,
        atMs: row.createdAtMs > 0 ? row.createdAtMs : DateTime.now().millisecondsSinceEpoch,
      );
    }
    if (notify) _touchMsgs(row.chatId);
  }

  void msgPutFromServer(ChatMsg m) {
    final role = switch (m.role) {
      ChatMsgRole.CHAT_MSG_ROLE_USER => 'user',
      ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT => 'assistant',
      ChatMsgRole.CHAT_MSG_ROLE_SYSTEM => 'system',
      _ => 'assistant',
    };
    msgPut(
      MsgRow(
        id: m.id.toInt(),
        chatId: m.chatId.toInt(),
        role: role,
        content: m.content,
        thought: m.thought,
        attachmentsJson: m.attachmentsJson,
        blocksJson: m.blocksJson,
        traceJson: '',
        reqId: m.reqId,
        tokensIn: m.tokensIn,
        tokensOut: m.tokensOut,
        durationMs: m.durationMs,
        costUsd: m.costUsd,
        error: m.hasErrorText() ? m.errorText : '',
        createdAtMs: m.createdTsMs.toInt(),
        attachments: MsgAttachment.decode(m.attachmentsJson),
      ),
      touchPreview: false,
    );
  }

  void msgUpdate({required int id, String? content, String? thought, String? blocksJson, String? traceJson, String? attachmentsJson, List<MsgAttachment>? attachments, int? tokensIn, int? tokensOut, int? durationMs, double? costUsd}) {
    final i = msgs.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final m = msgs[i];
    msgs[i] = m.copyWith(
      content: content ?? m.content,
      thought: thought ?? m.thought,
      blocksJson: blocksJson ?? m.blocksJson,
      traceJson: traceJson ?? m.traceJson,
      attachmentsJson: attachmentsJson ?? m.attachmentsJson,
      attachments: attachments ?? m.attachments,
      tokensIn: tokensIn ?? m.tokensIn,
      tokensOut: tokensOut ?? m.tokensOut,
      durationMs: durationMs ?? m.durationMs,
      costUsd: costUsd ?? m.costUsd,
    );
    _chatPreviewTouch(m.chatId, msgs[i].content, atMs: msgs[i].createdAtMs > 0 ? msgs[i].createdAtMs : DateTime.now().millisecondsSinceEpoch);
    _touchMsgs(m.chatId);
  }

  void msgStreamContent(String text, {int? chatId, String reqId = ''}) {
    if (text.isEmpty) return;
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    final rid = reqId.isNotEmpty ? reqId : (pendingPromptReqId ?? '');
    final m = _turnAssistant(chatId: cid, reqId: rid);
    if (m != null) {
      if (text.startsWith(m.content) && text.length > m.content.length) {
        m.content = text;
      } else {
        m.content = '${m.content}$text';
      }
    } else {
      msgs.add(MsgRow(id: _nextLocalId--, chatId: cid, role: 'assistant', content: text, reqId: rid));
    }
    _chatPreviewTouch(cid, m?.content ?? text, atMs: DateTime.now().millisecondsSinceEpoch);
    _touchMsgs(cid, debounce: true);
  }

  void msgStreamThought(String text, {int? chatId, String reqId = ''}) {
    if (text.isEmpty) return;
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    final rid = reqId.isNotEmpty ? reqId : (pendingPromptReqId ?? '');
    final m = _turnAssistant(chatId: cid, reqId: rid);
    if (m != null) {
      m.thought = '${m.thought}$text';
    } else {
      msgs.add(MsgRow(id: _nextLocalId--, chatId: cid, role: 'assistant', content: '', thought: text, reqId: rid));
    }
    _touchMsgs(cid, debounce: true);
  }

  void msgStreamBlocks(String blocksJson, {int? chatId, String reqId = ''}) {
    if (blocksJson.trim().isEmpty) return;
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    final rid = reqId.isNotEmpty ? reqId : (pendingPromptReqId ?? '');
    final m = _turnAssistant(chatId: cid, reqId: rid);
    if (m != null) {
      m.blocksJson = blocksJson;
      if (m.error.isNotEmpty) m.error = '';
    } else {
      msgs.add(MsgRow(id: _nextLocalId--, chatId: cid, role: 'assistant', content: '', blocksJson: blocksJson, reqId: rid));
    }
    _touchMsgs(cid, debounce: true);
  }

  int? _assistantIdx(int chatId, {String reqId = ''}) {
    final rid = reqId.trim();
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.chatId != chatId || m.role != 'assistant') continue;
      if (rid.isNotEmpty && m.reqId.isNotEmpty && m.reqId != rid) continue;
      return i;
    }
    if (rid.isNotEmpty) return null;
    final i = msgs.lastIndexWhere((m) => m.chatId == chatId && m.role == 'assistant');
    return i >= 0 ? i : null;
  }

  void msgStreamFail(String error, {int? chatId, int startedAtMs = 0}) {
    final text = error.trim();
    if (text.isEmpty) return;
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    final rid = pendingPromptReqId ?? '';
    final i = _assistantIdx(cid, reqId: rid);
    if (i == null) return;
    final m = msgs[i];
    final started = startedAtMs > 0 ? startedAtMs : promptStartedAtMs;
    final duration = m.durationMs > 0 ? m.durationMs : (started > 0 ? DateTime.now().millisecondsSinceEpoch - started : 0);
    msgs[i] = m.copyWith(error: text, durationMs: duration > 0 ? duration : m.durationMs);
    _chatStatusPut(cid, status: 'error', unread: cid != activeChatId);
    _promptClear();
    _flushDirtyMsgs();
    _touchMsgs(cid);
  }

  void msgStreamFinalize({int? chatId, String model = '', int startedAtMs = 0}) {
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    _chatStatusPut(cid, status: 'done', unread: cid != activeChatId);
    final i = msgs.lastIndexWhere((m) => m.chatId == cid && m.role == 'assistant');
    if (i < 0) {
      _promptClear();
      _flushDirtyMsgs();
      return;
    }
    final m = msgs[i];
    final started = startedAtMs > 0 ? startedAtMs : promptStartedAtMs;
    final duration = m.durationMs > 0 ? m.durationMs : (started > 0 ? DateTime.now().millisecondsSinceEpoch - started : 0);
    msgs[i] = m.copyWith(
      durationMs: duration > 0 ? duration : m.durationMs,
      model: m.model.isNotEmpty ? m.model : model,
    );
    _promptClear();
    _flushDirtyMsgs();
    _touchMsgs(cid);
  }

  void msgStreamEnd({int? chatId, int msgId = 0, int tokensIn = 0, int tokensOut = 0, double costUsd = 0, int durationMs = 0, String traceJson = '', String reqId = '', String model = '', String error = ''}) {
    final cid = chatId ?? promptChatId;
    if (cid == null) return;
    final err = error.trim();
    _chatStatusPut(cid, status: err.isNotEmpty ? 'error' : 'done', unread: cid != activeChatId);
    final rid = reqId.isNotEmpty ? reqId : (pendingPromptReqId ?? '');
    final i = _assistantIdx(cid, reqId: rid);
    if (i == null) return;
    final m = msgs[i];
    final duration = durationMs > 0 ? durationMs : (promptStartedAtMs > 0 ? DateTime.now().millisecondsSinceEpoch - promptStartedAtMs : 0);
    msgs[i] = m.copyWith(
      id: msgId != 0 ? msgId : m.id,
      tokensIn: tokensIn > 0 ? tokensIn : m.tokensIn,
      tokensOut: tokensOut > 0 ? tokensOut : m.tokensOut,
      costUsd: costUsd > 0 ? costUsd : m.costUsd,
      durationMs: duration > 0 ? duration : m.durationMs,
      traceJson: traceJson.isNotEmpty ? traceJson : m.traceJson,
      reqId: rid.isNotEmpty ? rid : m.reqId,
      model: model.isNotEmpty ? model : m.model,
      error: err.isNotEmpty ? err : '',
    );
    if (promptChatId == cid) _promptClear();
    _flushDirtyMsgs();
    _touchMsgs(cid);
  }

  void _promptClear() {
    promptBusy = false;
    promptChatId = null;
    promptStartedAtMs = 0;
    pendingPromptReqId = null;
  }

  int chatEnsurePending() {
    final existing = activeChatId;
    if (existing != null) {
      for (final c in chats) {
        if (c.id == existing) return c.pending ? 0 : existing;
      }
    }
    final id = _nextLocalId--;
    chats.insert(0, ChatRow(id: id, title: 'New chat', pending: true, lastMsgAt: DateTime.now().millisecondsSinceEpoch));
    activeChatId = id;
    _touch();
    return 0;
  }

  void promptBusyPut(bool v, {int? chatId, String? reqId}) {
    if (v) {
      promptBusy = true;
      promptChatId = chatId ?? promptChatId;
      pendingPromptReqId = reqId;
      promptStartedAtMs = DateTime.now().millisecondsSinceEpoch;
    } else {
      final id = chatId ?? promptChatId;
      if (id != null) chatStatusStaleClear(chatId: id);
      if (chatId == null || chatId == promptChatId) _promptClear();
    }
    notifyListeners();
  }

  void promptChatIdPut(int id) {
    if (promptChatId != null) promptChatId = id;
  }

  bool msgCanReplaceFailedTurn(int chatId) {
    if (promptBusyFor(chatId)) return false;
    final lastUserIdx = msgs.lastIndexWhere(
      (m) => m.chatId == chatId && m.role == 'user' && (m.content.trim().isNotEmpty || m.attachments.isNotEmpty),
    );
    if (lastUserIdx < 0) return false;
    for (var i = msgs.length - 1; i > lastUserIdx; i--) {
      final m = msgs[i];
      if (m.chatId != chatId || m.role != 'assistant') continue;
      return m.error.trim().isNotEmpty;
    }
    return false;
  }

  void _tombstoneAssistantsAfterUser(int chatId, int lastUserIdx) {
    for (var i = msgs.length - 1; i > lastUserIdx; i--) {
      if (msgs[i].chatId != chatId || msgs[i].role != 'assistant') continue;
      if (msgs[i].id > 0) _tombstonedMsgIds.add(msgs[i].id);
      msgs.removeAt(i);
    }
  }

  void msgReplaceFailedTurnPrep(int chatId) {
    final lastUserIdx = msgs.lastIndexWhere(
      (m) => m.chatId == chatId && m.role == 'user' && (m.content.trim().isNotEmpty || m.attachments.isNotEmpty),
    );
    if (lastUserIdx < 0) return;
    _tombstoneAssistantsAfterUser(chatId, lastUserIdx);
    _touchMsgs(chatId);
    notifyListeners();
  }

  ({String text, List<MsgAttachment> attachments})? retryLastTurnPrep({int? chatId}) {
    if (promptBusy) return null;
    final cid = chatId ?? activeChatId;
    if (cid == null) return null;
    final lastUserIdx = msgs.lastIndexWhere(
      (m) => m.chatId == cid && m.role == 'user' && (m.content.trim().isNotEmpty || m.attachments.isNotEmpty),
    );
    if (lastUserIdx < 0) return null;
    final lastUser = msgs[lastUserIdx];
    _tombstoneAssistantsAfterUser(cid, lastUserIdx);
    _touchMsgs(cid);
    notifyListeners();
    return (text: lastUser.content, attachments: List<MsgAttachment>.from(lastUser.attachments));
  }

  void chatClearMsgs(int id) {
    msgs.removeWhere((m) => m.chatId == id);
    if (promptChatId == id) _promptClear();
    for (final c in chats) {
      if (c.id == id) {
        c.lastMsgPreview = '';
        c.lastMsgStatus = 'done';
      }
    }
    unawaited(_prefs?.remove(_chatMsgsKey(id)));
    _touchMsgs(id);
    _touch();
    notifyListeners();
  }

  void chatHistoryClearAll() {
    msgs.clear();
    _promptClear();
    for (final c in chats) {
      c.lastMsgPreview = '';
      c.lastMsgAt = 0;
      c.lastMsgStatus = 'done';
      unawaited(_prefs?.remove(_chatMsgsKey(c.id)));
    }
    _touch();
    notifyListeners();
  }

  Future<void> chatHistoryClearRemote(ChatConn conn) async {
    await conn.chatHistoryClear();
    chatHistoryClearAll();
  }

  void msgUserTurnRetry({
    required int chatId,
    required String content,
    required List<MsgAttachment> attachments,
    required String reqId,
    required int createdAtMs,
  }) {
    final idx = msgs.lastIndexWhere((m) => m.chatId == chatId && m.role == 'user');
    if (idx >= 0) {
      final old = msgs[idx];
      msgs[idx] = old.copyWith(
        content: content,
        attachments: attachments,
        attachmentsJson: MsgAttachment.encode(attachments),
        reqId: reqId,
        createdAtMs: createdAtMs,
        error: '',
      );
    } else {
      msgs.add(MsgRow(
        id: msgNextLocalId(),
        chatId: chatId,
        role: 'user',
        content: content,
        attachments: attachments,
        attachmentsJson: MsgAttachment.encode(attachments),
        createdAtMs: createdAtMs,
        reqId: reqId,
      ));
    }
    _chatPreviewTouch(chatId, content, atMs: createdAtMs);
    _touchMsgs(chatId);
    notifyListeners();
  }

  void msgsReloadFromServer(int chatId, List<ChatMsg> serverMsgs) {
    if (chatId <= 0 || promptBusyFor(chatId)) return;
    msgs.removeWhere((m) => m.chatId == chatId);
    final sorted = [...serverMsgs]..sort((a, b) => a.id.compareTo(b.id));
    var newestPreview = '';
    var newestAt = 0;
    for (final m in sorted) {
      final at = m.createdTsMs.toInt();
      if (at >= newestAt) {
        newestAt = at;
        newestPreview = m.content;
      }
      msgPutFromServer(m);
    }
    if (newestAt > 0) _chatPreviewTouch(chatId, newestPreview, atMs: newestAt);
    _touchMsgs(chatId);
  }

  void inboxMerge(ResInboxList res) {
    final membersByChat = {for (final m in res.members) m.chatId.toInt(): m};
    for (final chat in res.chats) {
      chatPutFromServer(chat, membersByChat[chat.id.toInt()] ?? ChatMember(chatId: chat.id));
    }
  }

  void navCountsPut(NavCounts nav) {
    navCounts = nav;
    notifyListeners();
  }

  final mentionCatalog = MentionCatalogStore();

  void sessionInitMerge(ResSessionInit init) {
    if (init.hasNav()) navCounts = init.nav;
    if (init.hasBilling()) AppStore.instance.billingPut(init.billing);
    if (init.hasMentions()) mentionCatalog.mergeCatalog(init.mentions);
    if (init.models.isNotEmpty) models = agentModelsFromProto(init.models);
    if (init.hasProfile()) {
      final profile = init.profile;
      final roles = profile.isRoot ? ['root'] : const <String>[];
      unawaited(Session.instance.identityMerge(
        name: profile.name,
        alienId: profile.alienId,
        pic: profile.pic,
        globalRoles: roles.isEmpty ? null : roles,
      ));
      unawaited(UserLocalePrefs.instance.mergeFromProfile(
        tz: profile.tz,
        locationCity: profile.locationCity,
        locationRegion: profile.locationRegion,
        locationCountry: profile.locationCountry,
        locationSource: profile.locationSource,
      ));
    }
    final membersByChat = {for (final m in init.inboxMembers) m.chatId.toInt(): m};
    for (final chat in init.inboxChats) {
      chatPutFromServer(chat, membersByChat[chat.id.toInt()] ?? ChatMember(chatId: chat.id));
    }
    if (init.hasHints()) {
      unawaited(HintStore.instance.merge(init.hints, sinceMs: HintStore.instance.rev));
    }
  }

  Future<void> hintTouch(ChatConn conn, {required int assetIid, required String assetKind}) async {
    if (assetIid <= 0 || assetKind.trim().isEmpty) return;
    try {
      await conn.hintTouch(assetIid: Int64(assetIid), assetKind: assetKind);
    } catch (_) {}
  }

  Future<void> refreshFromConn(ChatConn conn, {String locale = 'en'}) async {
    try {
      final prefs = UserLocalePrefs.instance;
      final locPrefs = UserLocationPrefs.instance;
      final hasLoc = prefs.locationCity.isNotEmpty || prefs.locationRegion.isNotEmpty || prefs.locationCountry.isNotEmpty;
      final init = await conn.sessionInit(
        locale: locale,
        tz: prefs.tz.isNotEmpty ? prefs.tz : UserLocalePrefs.deviceTimezoneDetect(),
        locationCity: prefs.locationCity,
        locationRegion: prefs.locationRegion,
        locationCountry: prefs.locationCountry,
        locationSource: locPrefs.sessionSourceForWire(hasLocationFields: hasLoc),
        includeInbox: true,
        hintsSinceMs: Int64(HintStore.instance.rev),
      );
      sessionInitMerge(init);
    } catch (_) {}
    try {
      inboxMerge(await conn.inboxList(includeArchived: true));
    } catch (_) {}
    chatStatusStaleClear();
    notifyListeners();
  }

  @override
  void dispose() {
    _flushDirtyMsgs();
    super.dispose();
  }
}
