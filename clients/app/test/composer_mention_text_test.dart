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

  test('composerMentionContentSameTurn matches chip draft to bracket wire', () {
    const deviceId = 'iid:42';
    final local = 'buat referral code untuk ${composerMentionToken(deviceId)}';
    const server = 'buat referral code untuk [@iid:42]';
    expect(composerMentionContentSameTurn(local, server), isTrue);
    expect(composerMentionContentSameTurn(local, 'besok hari apa'), isFalse);
  });

  test('composerMentionDraftMergeSticky keeps chips after send', () {
    const deviceId = 'iid:42';
    final sticky = composerMentionDraftFromStickyIds([deviceId], const []);
    expect(sticky, composerMentionToken(deviceId));
    final merged = composerMentionDraftMergeSticky('', [deviceId], const []);
    expect(merged, sticky);
    final withText = composerMentionDraftMergeSticky('clear recycle bin', [deviceId], const []);
    expect(withText, startsWith(sticky));
    expect(withText, contains('clear recycle bin'));
  });

  test('composerMentionBracketFixupNesting collapses double bracket shell', () {
    const deviceId = 'iid:98348080882880512';
    final nested = '[@[${composerMentionBracketForId(deviceId)}] tab list';
    final fixed = composerMentionBracketFixupNesting(nested);
    expect(fixed, startsWith('[@iid:98348080882880512]'));
    expect(fixed, isNot(contains('[@[')));
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

  test('msgUserContentForDisplay strips bracket shell around chip token', () {
    const deviceId = 'iid:98348080882880512';
    final token = composerMentionToken(deviceId);
    final out = msgUserContentForDisplay(
      content: 'apa saja tab terbuka [@ $token ]',
      mentionIdsJson: msgMentionIdsEncode([deviceId]),
      mentions: const [],
    );
    expect(out, isNot(contains('[@')));
    expect(out, isNot(contains(' ]')));
    expect(out, contains(token));
    expect(out.trim(), 'apa saja tab terbuka $token');
  });

  test('msgUserContentForDisplay drops bracket when chip token already present', () {
    const deviceId = 'iid:42';
    final token = composerMentionToken(deviceId);
    final out = msgUserContentForDisplay(
      content: '$token tambah baris [@iid:42]',
      mentionIdsJson: msgMentionIdsEncode([deviceId]),
      mentions: const [],
    );
    expect(out, isNot(contains('[@')));
    expect(out, contains(token));
    expect(out, contains('tambah baris'));
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