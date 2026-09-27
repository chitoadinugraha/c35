import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composerMentionUserContentDisplay strips control chars when catalog empty', () {
    const deviceId = 'iid:97279816209936384';
    final raw = 'What is on ${composerMentionStart}$deviceId${composerMentionEnd} screen?';
    expect(
      composerMentionUserContentDisplay(raw, const []),
      'What is on $deviceId screen?',
    );
  });

  test('composerMentionTextForWire emits bracket mention', () {
    const deviceId = 'iid:97279816209936384';
    final draft = 'berapa ping ${composerMentionToken(deviceId)} ke google ?';
    final wire = composerMentionTextForWire(draft, const [], mentionIds: [deviceId]);
    expect(wire, contains('[@iid:97279816209936384]'));
    expect(wire, isNot(contains(composerMentionStart)));
  });

  test('composerMentionDisplayRestore wraps bracket iid', () {
    const deviceId = 'iid:42';
    final out = composerMentionDisplayRestore('ping [@iid:42] ke google', const []);
    expect(out, contains(composerMentionToken(deviceId)));
  });

  test('composerMentionIdsCollect reads bracket form', () {
    expect(composerMentionIdsCollect('hello [@catalog:research] there'), ['catalog:research']);
  });

  test('composerMentionIdsCollect reads drive bracket', () {
    expect(composerMentionIdsCollect('read [@drive:notes/todo.txt]'), ['drive:notes/todo.txt']);
  });

  test('composerMentionDisplayRestore wraps inline iid in sentence', () {
    const deviceId = 'iid:97279816209936384';
    final out = composerMentionDisplayRestore(
      'berapa ping $deviceId ke google ?',
      const [],
    );
    expect(out, 'berapa ping ${composerMentionToken(deviceId)} ke google ?');
  });

  test('msgUserContentForDisplay wraps inline iid using stored mention ids', () {
    const deviceId = 'iid:97279816209936384';
    final out = msgUserContentForDisplay(
      content: 'berapa ping [@iid:97279816209936384] ke google ?',
      mentionIdsJson: msgMentionIdsEncode([deviceId]),
      mentions: const [],
    );
    expect(out, contains(composerMentionToken(deviceId)));
  });
}