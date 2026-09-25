import 'package:alienai_c35/c/chat/chat_block.dart';
import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('msgDisplayContent strips legacy appended errors', () {
    final m = MsgRow(
      id: 1,
      chatId: 1,
      role: 'assistant',
      content: 'Sekarang hari Senin.Error: billing failed',
      error: 'billing failed',
    );
    expect(msgDisplayContent(m), 'Sekarang hari Senin.');
  });

  test('retryLastTurnPrep drops trailing assistant only', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];
    store.activeChatId = 1;
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'hi'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'failed'),
    ];

    final turn = store.retryLastTurnPrep();

    expect(turn?.text, 'hi');
    expect(store.msgs.length, 1);
    expect(store.msgs.single.role, 'user');
  });

  test('retryLastTurnPrep drops trailing assistant when other chat messages follow in msgs', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A'), ChatRow(id: 2, title: 'B')];
    store.activeChatId = 1;
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'hello chat 1'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'failed'),
      MsgRow(id: 20, chatId: 2, role: 'user', content: 'hello chat 2'),
    ];

    final turn = store.retryLastTurnPrep();

    expect(turn?.text, 'hello chat 1');
    expect(store.msgs.where((m) => m.chatId == 1).length, 1);
    expect(store.msgs.where((m) => m.chatId == 1).single.role, 'user');
    // Ensure chat 2 was untouched
    expect(store.msgs.where((m) => m.chatId == 2).length, 1);
  });

  test('msgCanReplaceFailedTurn is true when last assistant errored', () {
    final store = ChatStore();
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'old prompt'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'ws failed'),
    ];
    expect(store.msgCanReplaceFailedTurn(1), isTrue);
  });

  test('msgReplaceFailedTurnPrep drops failed assistant after last user', () {
    final store = ChatStore();
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'old prompt'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'ws failed'),
    ];
    store.msgReplaceFailedTurnPrep(1);
    expect(store.msgs.length, 1);
    expect(store.msgs.single.content, 'old prompt');
  });

  test('msgsCollapseRetriedAssistants keeps latest successful assistant per user turn', () {
    final rows = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'log food'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'connection closed'),
      MsgRow(id: 12, chatId: 1, role: 'assistant', content: '', blocksJson: '[{"kind":"consumption.food"}]'),
    ];
    final out = msgsCollapseRetriedAssistants(rows);
    expect(out.length, 2);
    expect(out.last.id, 12);
    expect(out.last.error, isEmpty);
  });

  test('msgsCollapseRetriedAssistants keeps latest failed assistant when all attempts fail', () {
    final rows = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'log food'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: '', error: 'first'),
      MsgRow(id: 12, chatId: 1, role: 'assistant', content: '', error: 'second'),
    ];
    final out = msgsCollapseRetriedAssistants(rows);
    expect(out.length, 2);
    expect(out.last.error, 'second');
  });

  test('msgUserTurnRetry updates user message in place without duplicating', () {
    final store = ChatStore();
    store.activeChatId = 1;
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'sekarang jam berapa?', reqId: 'r1'),
      MsgRow(id: 20, chatId: 2, role: 'user', content: 'other chat', reqId: 'r2'),
    ];

    store.msgUserTurnRetry(
      chatId: 1,
      content: 'sekarang jam berapa?',
      attachments: const [],
      reqId: 'r3',
      createdAtMs: 1234567,
    );

    final chat1Msgs = store.msgs.where((m) => m.chatId == 1).toList();
    expect(chat1Msgs.length, 1);
    expect(chat1Msgs.single.reqId, 'r3');
    expect(chat1Msgs.single.createdAtMs, 1234567);
  });

  test('chatClearMsgs clears only target chat messages', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A'), ChatRow(id: 2, title: 'B')];
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'msg 1'),
      MsgRow(id: 20, chatId: 2, role: 'user', content: 'msg 2'),
    ];

    store.chatClearMsgs(1);

    expect(store.msgs.where((m) => m.chatId == 1), isEmpty);
    expect(store.msgs.where((m) => m.chatId == 2).length, 1);
  });

  test('chatHistoryClearAll clears all messages and previews', () {
    final store = ChatStore();
    store.chats = [
      ChatRow(id: 1, title: 'A', lastMsgPreview: 'hi', lastMsgAt: 100),
      ChatRow(id: 2, title: 'B', lastMsgPreview: 'bye', lastMsgAt: 200),
    ];
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'msg 1'),
      MsgRow(id: 20, chatId: 2, role: 'user', content: 'msg 2'),
    ];

    store.chatHistoryClearAll();

    expect(store.msgs, isEmpty);
    expect(store.chats.every((c) => c.lastMsgPreview.isEmpty && c.lastMsgAt == 0), isTrue);
  });

  test('msgStreamFail stores error without changing content', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: 11, chatId: 1, role: 'assistant', content: 'Sekarang hari Senin.')];
    store.promptBusyPut(true, chatId: 1);

    store.msgStreamFail('billing failed', chatId: 1);

    expect(store.msgs.last.content, 'Sekarang hari Senin.');
    expect(store.msgs.last.error, 'billing failed');
    expect(store.promptBusy, isFalse);
  });

  test('msgStream routes to prompt chat, not active chat', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A'), ChatRow(id: 2, title: 'B')];
    store.msgs = [
      MsgRow(id: 10, chatId: 1, role: 'user', content: 'hi'),
      MsgRow(id: 11, chatId: 1, role: 'assistant', content: ''),
    ];
    store.activeChatId = 2;
    store.promptBusyPut(true, chatId: 1);

    store.msgStreamContent('hello', chatId: 1);

    expect(store.msgs.last.chatId, 1);
    expect(store.msgs.last.content, 'hello');
    expect(store.activeMsgs, isEmpty);
  });

  test('promptBusyFor scopes busy state per chat', () {
    final store = ChatStore();
    store.promptBusyPut(true, chatId: 42);

    expect(store.promptBusyFor(42), isTrue);
    expect(store.promptBusyFor(7), isFalse);
    expect(store.promptBusy, isTrue);
  });

  test('chatStatusStaleClear resets orphaned streaming status', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A', lastMsgStatus: 'streaming')];

    store.chatStatusStaleClear();

    expect(store.chats.single.lastMsgStatus, 'done');
  });

  test('chatPutFromServer ignores stale streaming when not prompting', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];

    store.chatPutFromServer(
      Chat(id: Int64(1), title: 'Track food consumption'),
      ChatMember(chatId: Int64(1), lastMsgStatus: 'streaming', lastMsgPreview: 'Track food consumption'),
    );

    expect(store.chats.single.lastMsgStatus, 'done');
  });

  test('chatPutFromServer preserves unread until chat is opened', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A', unreadStatus: true)];
    store.activeChatId = 2;

    store.chatPutFromServer(Chat(id: Int64(1), title: 'A'), ChatMember(chatId: Int64(1), lastMsgPreview: 'hi'));

    expect(store.chats.single.unreadStatus, isTrue);

    store.chatSelect(1);

    expect(store.chats.single.unreadStatus, isFalse);
  });

  test('chatPutFromServer reads unread_count from server member', () {
    final store = ChatStore();

    store.chatPutFromServer(
      Chat(id: Int64(1), title: 'A'),
      ChatMember(chatId: Int64(1), unreadCount: 2, lastMsgPreview: 'hi'),
    );

    expect(store.chats.single.unreadStatus, isTrue);
  });

  test('pending chat id migrates promptChatId on server assign', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: -1, title: 'New chat', pending: true)];
    store.msgs = [MsgRow(id: 1, chatId: -1, role: 'assistant', content: '')];
    store.promptBusyPut(true, chatId: -1);

    store.chatPutFromServer(
      Chat(id: Int64(99)),
      ChatMember(chatId: Int64(99), lastMsgPreview: 'hi'),
    );

    expect(store.promptChatId, 99);
    expect(store.msgs.single.chatId, 99);
  });

  test('chatPutFromServer merges pending when server chat already exists', () {
    final store = ChatStore();
    store.chats = [
      ChatRow(id: -1, title: 'New chat', pending: true),
      ChatRow(id: 99, title: 'Old', lastMsgPreview: 'prev'),
    ];
    store.msgs = [
      MsgRow(id: 1, chatId: -1, role: 'user', content: 'hi'),
      MsgRow(id: 2, chatId: -1, role: 'assistant', content: ''),
    ];
    store.activeChatId = -1;
    store.promptBusyPut(true, chatId: -1);

    store.chatPutFromServer(
      Chat(id: Int64(99), title: 'sekarang jam berapa?'),
      ChatMember(chatId: Int64(99), lastMsgPreview: 'hi'),
    );

    expect(store.chats.map((c) => c.id), [99]);
    expect(store.promptChatId, 99);
    expect(store.activeChatId, 99);
    expect(store.msgs.every((m) => m.chatId == 99), isTrue);
  });

  test('chatIdMigrate moves msgs and prompt state', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: -1, title: 'New chat', pending: true)];
    store.msgs = [MsgRow(id: 1, chatId: -1, role: 'assistant', content: '')];
    store.promptBusyPut(true, chatId: -1);

    store.chatIdMigrate(-1, 42);

    expect(store.chats, isEmpty);
    expect(store.promptChatId, 42);
    expect(store.msgs.single.chatId, 42);
  });

  test('chatDeletingFor tracks in-flight delete', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];

    store.chatDeletingPut(1, true);
    expect(store.chatDeletingFor(1), isTrue);
    expect(store.chatDeletingFor(2), isFalse);

    store.chatDeletingPut(1, false);
    expect(store.chatDeletingFor(1), isFalse);
  });

  test('chatDelete removes chat and messages', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A'), ChatRow(id: 2, title: 'B', lastMsgPreview: 'yo')];
    store.msgs = [MsgRow(id: 10, chatId: 1, role: 'user', content: 'hi')];
    store.activeChatId = 1;

    store.chatDelete(1);

    expect(store.chats.map((c) => c.id), [2]);
    expect(store.msgs, isEmpty);
    expect(store.activeChatId, 2);
  });

  test('chatTagsPut stores tags', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];
    store.chatTagsPut(1, ['work', 'home']);
    expect(store.chats.first.tags, ['work', 'home']);
  });

  test('msgStreamEnd clears prompt only for matching chat', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: 1, chatId: 5, role: 'assistant', content: 'done')];
    store.promptBusyPut(true, chatId: 5);

    store.msgStreamEnd(chatId: 5, msgId: 1, tokensIn: 1, tokensOut: 2);

    expect(store.promptBusy, isFalse);
    expect(store.promptChatId, isNull);
    expect(store.msgs.single.tokensIn, 1);
    expect(store.msgs.single.tokensOut, 2);
  });

  test('msgStreamStart sets reqId and model on assistant', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: 1, chatId: 5, role: 'assistant', content: '')];
    store.promptBusyPut(true, chatId: 5, reqId: 'req-1');

    store.msgStreamStart(chatId: 5, reqId: 'req-1', model: 'alienai');

    expect(store.msgs.single.reqId, 'req-1');
    expect(store.msgs.single.model, 'alienai');
  });

  test('msgPut merges server assistant into local placeholder', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: -1, chatId: 5, role: 'assistant', content: 'hi', reqId: 'req-1')];
    store.promptBusyPut(true, chatId: 5, reqId: 'req-1');

    store.msgPut(MsgRow(id: 99, chatId: 5, role: 'assistant', content: 'hi', reqId: 'req-1', tokensIn: 10, tokensOut: 20, durationMs: 500));

    expect(store.msgs.length, 1);
    expect(store.msgs.single.id, 99);
    expect(store.msgs.single.tokensIn, 10);
    expect(store.msgs.single.tokensOut, 20);
    expect(store.msgs.single.durationMs, 500);
  });

  test('msgStreamFinalize sets duration when PromptEnd missing', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: -1, chatId: 5, role: 'assistant', content: 'done')];
    store.promptBusyPut(true, chatId: 5, reqId: 'req-1');
    final started = DateTime.now().millisecondsSinceEpoch - 1200;

    store.msgStreamFinalize(chatId: 5, model: 'alienai', startedAtMs: started);

    expect(store.promptBusy, isFalse);
    expect(store.msgs.single.durationMs, greaterThan(0));
    expect(store.msgs.single.model, 'alienai');
  });

  test('msgPutFromServer does not bump chat lastMsgAt', () {
    final store = ChatStore();
    final oldAt = DateTime(2024, 1, 1).millisecondsSinceEpoch;
    store.chats = [ChatRow(id: 5, title: 'A', lastMsgPreview: 'prev', lastMsgAt: oldAt)];

    store.msgPutFromServer(
      ChatMsg(
        id: Int64(1),
        chatId: Int64(5),
        role: ChatMsgRole.CHAT_MSG_ROLE_USER,
        content: 'hello',
        createdTsMs: Int64(DateTime(2024, 6, 1).millisecondsSinceEpoch),
      ),
    );

    expect(store.chats.single.lastMsgAt, oldAt);
    expect(store.chats.single.lastMsgPreview, 'prev');
  });

  test('msgPut merge clears stale attachments when user turn is replaced', () {
    final store = ChatStore();
    store.msgs = [
      MsgRow(
        id: 10,
        chatId: 1,
        role: 'user',
        content: 'Catat konsumsi makanan',
        reqId: 'r1',
        attachments: [MsgAttachment(hash: 'abc', name: 'food.jpg', mime: 'image/jpeg')],
        attachmentsJson: '[{"hash":"abc","name":"food.jpg","mime":"image/jpeg"}]',
      ),
    ];

    store.msgPut(MsgRow(
      id: 10,
      chatId: 1,
      role: 'user',
      content: 'Catat pengeluaran',
      reqId: 'r1',
      attachments: const [],
      attachmentsJson: '[]',
    ));

    expect(store.msgs.single.content, 'Catat pengeluaran');
    expect(store.msgs.single.attachments, isEmpty);
  });

  test('activeMsgs sorts by time and keeps user before assistant in a turn', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];
    store.activeChatId = 1;
    store.msgs = [
      MsgRow(id: 12, chatId: 1, role: 'assistant', content: 'answer', createdAtMs: 2000, reqId: 'r1'),
      MsgRow(id: 11, chatId: 1, role: 'user', content: 'question', createdAtMs: 2000, reqId: 'r1'),
    ];

    final out = store.activeMsgs;
    expect(out.map((m) => m.role).toList(), ['user', 'assistant']);
    expect(out.first.content, 'question');
  });

  test('msgsReloadFromServer sorts descending server payload ascending', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 5, title: 'A', lastMsgAt: 1000)];

    store.msgsReloadFromServer(5, [
      ChatMsg(
        id: Int64(12),
        chatId: Int64(5),
        role: ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT,
        content: 'server answer',
        createdTsMs: Int64(2100),
      ),
      ChatMsg(
        id: Int64(11),
        chatId: Int64(5),
        role: ChatMsgRole.CHAT_MSG_ROLE_USER,
        content: 'server user',
        createdTsMs: Int64(2000),
      ),
    ]);

    expect(store.msgs.where((m) => m.chatId == 5).map((m) => m.content).toList(), ['server user', 'server answer']);
    store.activeChatId = 5;
    expect(store.activeMsgs.map((m) => m.role).toList(), ['user', 'assistant']);
  });

  test('msgsReloadFromServer replaces local rows for chat', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 5, title: 'A', lastMsgAt: 1000)];
    store.msgs = [
      MsgRow(id: 1, chatId: 5, role: 'user', content: 'stale local'),
      MsgRow(id: 2, chatId: 5, role: 'assistant', content: 'stale answer'),
      MsgRow(id: 3, chatId: 9, role: 'user', content: 'other chat'),
    ];

    store.msgsReloadFromServer(5, [
      ChatMsg(
        id: Int64(11),
        chatId: Int64(5),
        role: ChatMsgRole.CHAT_MSG_ROLE_USER,
        content: 'server user',
        createdTsMs: Int64(2000),
      ),
      ChatMsg(
        id: Int64(12),
        chatId: Int64(5),
        role: ChatMsgRole.CHAT_MSG_ROLE_ASSISTANT,
        content: 'server answer',
        createdTsMs: Int64(2100),
      ),
    ]);

    expect(store.msgs.where((m) => m.chatId == 5).map((m) => m.content).toList(), ['server user', 'server answer']);
    expect(store.msgs.where((m) => m.chatId == 9).length, 1);
    expect(store.chats.single.lastMsgAt, 2100);
  });

  test('msgPut merges optimistic user message by reqId on server fetch', () {
    final store = ChatStore();
    final localUserMsg = MsgRow(
      id: 999999999,
      chatId: 5,
      role: 'user',
      content: 'hello server',
      reqId: 'uuid-1234',
    );
    store.msgs = [localUserMsg];

    final serverUserMsg = MsgRow(
      id: 100000000001,
      chatId: 5,
      role: 'user',
      content: 'hello server',
      reqId: 'uuid-1234',
    );
    store.msgPut(serverUserMsg);

    expect(store.msgs.length, 1);
    expect(store.msgs.single.id, 100000000001);
    expect(store.msgs.single.reqId, 'uuid-1234');
  });

  test('msgStreamContent preserves repeated tokens such as indentation and punctuation', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: 11, chatId: 1, role: 'assistant', content: '')];
    store.promptBusyPut(true, chatId: 1);

    store.msgStreamContent('    ', chatId: 1);
    store.msgStreamContent('    ', chatId: 1);
    store.msgStreamContent('def foo():\n', chatId: 1);
    store.msgStreamContent('...', chatId: 1);
    store.msgStreamContent('...', chatId: 1);

    expect(store.msgs.single.content, '        def foo():\n......');
  });

  test('msgStreamThought preserves repeated tokens', () {
    final store = ChatStore();
    store.msgs = [MsgRow(id: 11, chatId: 1, role: 'assistant', content: '')];
    store.promptBusyPut(true, chatId: 1);

    store.msgStreamThought('thinking...', chatId: 1);
    store.msgStreamThought('...', chatId: 1);

    expect(store.msgs.single.thought, 'thinking......');
  });

  test('msgBlockCollapsedPut toggles block collapsed state', () {
    final store = ChatStore();
    final initialBlocks = [
      ChatBlock(kind: 'consumption.food', collapsed: true, body: {'consumption_id': 'c1'}),
      ChatBlock(kind: 'consumption.glance', collapsed: false, body: {'calories': 500}),
    ];
    store.msgs = [
      MsgRow(
        id: 11,
        chatId: 1,
        role: 'assistant',
        content: 'Meal saved',
        blocksJson: ChatBlock.encodeList(initialBlocks),
      ),
    ];

    store.msgBlockCollapsedPut(msgId: 11, blockIndex: 0, collapsed: false);

    final updated = ChatBlock.decodeList(store.msgs.single.blocksJson);
    expect(updated[0].collapsed, isFalse);
    expect(updated[1].collapsed, isFalse);

    store.msgBlockCollapsedPut(msgId: 11, blockIndex: 1, collapsed: true);
    final updated2 = ChatBlock.decodeList(store.msgs.single.blocksJson);
    expect(updated2[1].collapsed, isTrue);
  });

  test('ChatBlock decodes legacy flat image blocks', () {
    final block = ChatBlock.fromJson({
      'kind': 'image',
      'hash': 'abc123',
      'url': '/fs/abc123',
      'mime': 'image/png',
      'prompt': 'bread logo',
    });
    expect(block.kind, 'image');
    expect(block.body['hash'], 'abc123');
    expect(block.body['mime'], 'image/png');
  });

  test('deep search matches message body and produces snippet', () {
    final store = ChatStore();
    final chat = ChatRow(id: 1, title: 'Project Discussion', lastMsgAt: 1000);
    store.chats = [chat];
    store.msgs = [
      MsgRow(
        id: 101,
        chatId: 1,
        role: 'user',
        content: 'We need to integrate WebRTC peer connections into flutter client.',
      ),
      MsgRow(
        id: 102,
        chatId: 1,
        role: 'assistant',
        content: 'Understood. Setting up coturn stun/turn credentials.',
      ),
    ];

    store.searchPut('WebRTC');
    expect(store.visibleChats.length, 1);
    expect(store.visibleChats.first.id, 1);

    final snippet = store.searchSnippetFor(1, 'WebRTC');
    expect(snippet, contains('WebRTC peer connections'));

    store.searchPut('nonexistentquery123');
    expect(store.visibleChats, isEmpty);
  });

  test('msgPut adds new assistant row per turn when prior local assistant has different reqId', () {
    final store = ChatStore();
    store.chats = [ChatRow(id: 1, title: 'A')];
    store.activeChatId = 1;
    store.msgs = [
      MsgRow(id: -1, chatId: 1, role: 'user', content: 'first', reqId: 'req-a'),
      MsgRow(id: -2, chatId: 1, role: 'assistant', content: '', error: 'failed', reqId: 'req-a'),
    ];

    store.msgPut(MsgRow(id: -3, chatId: 1, role: 'user', content: 'second', reqId: 'req-b', createdAtMs: 3000));
    store.msgPut(MsgRow(id: -4, chatId: 1, role: 'assistant', content: '', reqId: 'req-b', createdAtMs: 3001));

    expect(store.msgs.length, 4);
    expect(store.activeMsgs.map((m) => m.role).toList(), ['user', 'assistant', 'user', 'assistant']);
    expect(store.activeMsgs.last.reqId, 'req-b');
    expect(store.msgs.where((m) => m.reqId == 'req-a' && m.role == 'assistant').single.error, 'failed');
  });

  test('recentUserPrompts returns deduplicated user prompts in reverse order', () {
    final store = ChatStore();
    store.msgs = [
      MsgRow(id: 1, chatId: 1, role: 'user', content: 'first prompt'),
      MsgRow(id: 2, chatId: 1, role: 'assistant', content: 'first answer'),
      MsgRow(id: 3, chatId: 1, role: 'user', content: 'second prompt'),
      MsgRow(id: 4, chatId: 2, role: 'user', content: 'first prompt'), // duplicate
      MsgRow(id: 5, chatId: 2, role: 'user', content: 'third prompt'),
    ];

    final history = store.recentUserPrompts;
    expect(history, ['third prompt', 'first prompt', 'second prompt']);
  });
}
