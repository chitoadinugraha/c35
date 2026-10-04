import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chatTitleFromText sentence case', () {
    expect(chatTitleFromText('sekarang jam berapa?'), 'Sekarang jam berapa?');
    expect(chatTitleFromText('SEKARANG HARI APA'), 'Sekarang hari apa');
    expect(chatTitleFromText('  '), 'Chat');
  });

  test('chatTitleDisplay hides empty and new chat', () {
    expect(chatTitleDisplay(''), '');
    expect(chatTitleDisplay('New chat'), '');
    expect(chatTitleDisplay('hello world'), 'Hello world');
  });

  test('chatTitleOnPromptStart keeps title on follow-up', () {
    expect(
      chatTitleOnPromptStart(
        localChatId: 42,
        serverChatId: 42,
        existingTitle: 'What is rust?',
        previewLine: 'thanks',
      ),
      'What is rust?',
    );
  });

  test('chatTitleOnPromptStart uses first line for new server chat', () {
    expect(
      chatTitleOnPromptStart(
        localChatId: -1,
        serverChatId: 99,
        existingTitle: 'New chat',
        previewLine: 'hello there',
      ),
      'Hello there',
    );
  });

  test('chatTitleOnPromptStart fills placeholder on same id', () {
    expect(
      chatTitleOnPromptStart(
        localChatId: 10,
        serverChatId: 10,
        existingTitle: 'New chat',
        previewLine: 'first message',
      ),
      'First message',
    );
  });
}
