import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ChatStore.chatFork', () {
    test('clones thread history up to pivot message', () {
      final store = ChatStore();
      final origChat = ChatRow(
        id: 100,
        title: 'Project Setup',
        lastMsgPreview: 'done',
      );
      store.chats.add(origChat);

      final m1 = MsgRow(id: 1, chatId: 100, role: 'user', content: 'Turn 1');
      final m2 = MsgRow(id: 2, chatId: 100, role: 'assistant', content: 'Reply 1');
      final m3 = MsgRow(id: 3, chatId: 100, role: 'user', content: 'Turn 2');
      final m4 = MsgRow(id: 4, chatId: 100, role: 'assistant', content: 'Reply 2');
      store.msgs.addAll([m1, m2, m3, m4]);

      // Fork from m2 (turn 1)
      final forkedId = store.chatFork(100, upToMsgId: 2);

      expect(forkedId, isNot(100));
      expect(store.activeChatId, forkedId);

      final forkedChat = store.chats.firstWhere((c) => c.id == forkedId);
      expect(forkedChat.title, 'Project Setup (fork)');

      final forkedMsgs = store.msgs.where((m) => m.chatId == forkedId).toList();
      expect(forkedMsgs.length, 2);
      expect(forkedMsgs[0].content, 'Turn 1');
      expect(forkedMsgs[1].content, 'Reply 1');
    });

    test('clones all messages when upToMsgId is null', () {
      final store = ChatStore();
      final origChat = ChatRow(
        id: 200,
        title: 'Full Thread',
      );
      store.chats.add(origChat);

      final m1 = MsgRow(id: 10, chatId: 200, role: 'user', content: 'A');
      final m2 = MsgRow(id: 11, chatId: 200, role: 'assistant', content: 'B');
      store.msgs.addAll([m1, m2]);

      final forkedId = store.chatFork(200);
      final forkedMsgs = store.msgs.where((m) => m.chatId == forkedId).toList();
      expect(forkedMsgs.length, 2);
    });
  });
}
