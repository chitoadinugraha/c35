import 'package:alienai_c35/c/chat/chat_inbox.dart';
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
}
