import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:alienai_c35/widgets/ai/ui_msg_copy_prefix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('msgCopyHeader formats sender and stamp', () {
    final ms = DateTime(2024, 12, 2, 16, 1).millisecondsSinceEpoch;
    expect(
      msgCopyHeader(role: 'user', userName: 'Chito', createdAtMs: ms, now: DateTime(2024, 12, 2, 16, 1)),
      '[Chito 2 Dec 2024 16:01]',
    );
    expect(
      msgCopyHeader(role: 'assistant', userName: '', createdAtMs: ms, modelId: 'gpt-4o', models: const [AgentModel.gpt4o], now: DateTime(2024, 12, 2, 16, 1)),
      '[Alien AI (ChatGPT) 2 Dec 2024 16:01]',
    );
    expect(
      msgCopyHeader(role: 'assistant', userName: '', createdAtMs: ms, modelId: 'alien-fast', models: const [], now: DateTime(2024, 12, 2, 16, 1)),
      '[Alien AI 2 Dec 2024 16:01]',
    );
  });

  test('msgCopyTranscript joins blocks with blank line', () {
    final msgs = [
      MsgRow(id: 1, chatId: 1, role: 'user', content: 'Hi', createdAtMs: DateTime(2024, 12, 2, 16, 1).millisecondsSinceEpoch),
      MsgRow(id: 2, chatId: 1, role: 'assistant', content: 'Hello', model: 'gpt-4o', createdAtMs: DateTime(2024, 12, 2, 16, 3).millisecondsSinceEpoch),
    ];
    final out = msgCopyTranscript(
      messages: msgs,
      plainText: (m) => m.content,
      userName: 'Chito',
      models: const [AgentModel.gpt4o],
      modelId: (m) => m.model,
    );
    expect(
      out,
      '[Chito 2 Dec 2024 16:01]\nHi\n\n[Alien AI (ChatGPT) 2 Dec 2024 16:03]\nHello',
    );
  });

  test('msgCopyBody adds leading newlines for selection gap', () {
    expect(msgCopyBody(header: '[A]', leadingNewlines: 2), '\n\n[A]\n');
  });
}
