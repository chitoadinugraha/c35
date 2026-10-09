import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
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

  test('chatTitleDisplay resolves device bracket to label', () {
    const deviceId = 'iid:98063412749627392';
    const mentions = [
      CatalogMention(
        id: deviceId,
        topicId: 'device',
        icon: '',
        color: '',
        labelKey: '',
        captionKey: '',
        label: 'DESKTOP-D8406DF',
        kind: 'identity',
      ),
    ];
    expect(
      chatTitleDisplay('[@iid:98063412749627392] buka google chrome', mentions: mentions),
      'Desktop-d8406df buka google chrome',
    );
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

  test('chatTitleOnPromptStart keeps resolved mention label in title', () {
    const siteId = 'iid:12345';
    const mentions = [
      CatalogMention(
        id: siteId,
        topicId: 'web.builder',
        icon: '',
        color: '',
        labelKey: '',
        captionKey: '',
        label: 'Gucicha',
        kind: 'identity',
      ),
    ];
    final token = composerMentionToken(siteId);
    expect(
      chatTitleOnPromptStart(
        localChatId: 1,
        serverChatId: 99,
        existingTitle: 'New chat',
        previewLine: 'berapa untung $token hari ini?',
        mentions: mentions,
      ),
      'Berapa untung gucicha hari ini?',
    );
  });
}
