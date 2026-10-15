import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chatTitleFromText sentence case', () {
    expect(chatTitleFromText('sekarang jam berapa?'), 'Sekarang jam berapa?');
    expect(chatTitleFromText('SEKARANG HARI APA'), 'SEKARANG HARI APA');
    expect(chatTitleFromText('  '), 'Chat');
  });

  test('chatTitleFromText keeps labeled bracket token', () {
    expect(
      chatTitleFromText('[@iid:42|VM1] can you add rows'),
      '[@iid:42|VM1] Can you add rows',
    );
  });

  test('chatTitleFromText allows longer first line than legacy 48 cap', () {
    final msg = '[@iid:42|VM1] can you see what is on A3 and open chrome please';
    final title = chatTitleFromText(msg);
    expect(title.contains('on A3'), isTrue);
    expect(title.length, lessThanOrEqualTo(kChatTitleMaxChars));
  });

  test('chatTitleDisplayPlain hides empty and new chat', () {
    expect(chatTitleDisplayPlain(''), '');
    expect(chatTitleDisplayPlain('New chat'), '');
    expect(chatTitleDisplayPlain('hello world'), 'Hello world');
  });

  test('chatTitleDisplayPlain prepends sticky site label when title omitted mention', () {
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
    expect(
      chatTitleDisplayPlain(
        'apa barang yang paling untung hari ini?',
        mentions: mentions,
        stickyMentionIds: [siteId],
      ),
      'Gucicha apa barang yang paling untung hari ini?',
    );
  });

  test('chatTitleDisplayPlain resolves device bracket to label', () {
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
      chatTitleDisplayPlain('[@iid:98063412749627392] buka google chrome', mentions: mentions),
      'DESKTOP-D8406DF buka google chrome',
    );
    expect(
      chatTitleDisplayPlain('[@iid:98063412749627392|VM1] buka google chrome', mentions: const []),
      'VM1 buka google chrome',
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

  test('chatTitleOnPromptStart keeps bracket mention in title', () {
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
    expect(
      chatTitleOnPromptStart(
        localChatId: 1,
        serverChatId: 99,
        existingTitle: 'New chat',
        previewLine: 'berapa untung ${composerMentionBracketForId(siteId, label: 'Gucicha')} hari ini?',
        mentions: mentions,
      ),
      'Berapa untung [@iid:12345|Gucicha] hari ini?',
    );
  });
}
