import 'package:alienai_c35/c/catalog/catalog_api.dart';
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

  test('composerMentionIdsForWire keeps sticky device when text has no chip', () {
    const deviceId = 'iid:98063412749627392';
    final ids = composerMentionIdsForWire(
      fromComposer: const [],
      selectedSticky: [deviceId],
      chatSticky: [deviceId],
      text: 'can you minimize the Alien AI Agent',
    );
    expect(ids, [deviceId]);
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

  test('composerMentionBracketFixupNesting fixes stored double prefix', () {
    const raw = '[@[@iid:98063412749627392]]tambahkan 5 baris';
    final fixed = composerMentionBracketFixupNesting(raw);
    expect(fixed, startsWith('[@iid:98063412749627392]'));
    expect(fixed, isNot(contains('[@[')));
  });

  test('composerMentionStripTrailingOpenBracketShell before chip insert', () {
    const deviceId = 'iid:98063412749627392';
    final token = composerMentionToken(deviceId);
    final before = composerMentionStripTrailingOpenBracketShell('[@ ');
    final wire = composerMentionTextForWire('$before$token tambah', const [], mentionIds: [deviceId]);
    expect(wire, startsWith('[@iid:98063412749627392]'));
    expect(wire, isNot(contains('[@[')));
  });

  test('composerMentionTextForWire emits bracket mention', () {
    const deviceId = 'iid:97279816209936384';
    final draft = 'berapa ping ${composerMentionToken(deviceId)} ke google ?';
    final wire = composerMentionTextForWire(draft, const [], mentionIds: [deviceId]);
    expect(wire, contains('[@iid:97279816209936384]'));
    expect(wire, isNot(contains(composerMentionStart)));
  });

  test('composerMentionTextForWire embeds catalog label snapshot', () {
    const deviceId = 'iid:42';
    const mentions = [
      CatalogMention(
        id: deviceId,
        topicId: 'device',
        icon: '',
        color: '',
        labelKey: '',
        captionKey: '',
        label: 'VM1',
        kind: 'identity',
      ),
    ];
    final wire = composerMentionTextForWire(
      'hello ${composerMentionToken(deviceId)} there',
      mentions,
      mentionIds: [deviceId],
    );
    expect(wire, contains('[@iid:42|VM1]'));
  });

  test('composerMentionContentSameTurn ignores label snapshot', () {
    final local = 'hi ${composerMentionToken('iid:42')}';
    expect(composerMentionContentSameTurn(local, '[@iid:42|VM1] hi'), isTrue);
  });

  test('composerMentionBracketForId does not double label in canonical id', () {
    expect(composerMentionBracketForId('iid:42|VM1', label: 'VM1'), '[@iid:42|VM1]');
    expect(
      composerMentionBracketForId('[@iid:42|VM1]', label: 'VM1'),
      '[@iid:42|VM1]',
    );
  });

  test('composerMentionTextForWire does not duplicate when text already has bracket', () {
    const deviceId = 'iid:42';
    const mentions = [
      CatalogMention(
        id: deviceId,
        topicId: 'device',
        icon: '',
        color: '',
        labelKey: '',
        captionKey: '',
        label: 'VM1',
        kind: 'identity',
      ),
    ];
    final wire = composerMentionTextForWire(
      '[@iid:42|VM1] change A3',
      mentions,
      mentionIds: [deviceId],
    );
    expect(wire, '[@iid:42|VM1] change A3');
    expect(wire, isNot(contains('|VM1]|VM1')));
  });

  test('composerMentionBracketRepair closes mention before message text', () {
    const deviceId = 'iid:98063412749627392';
    const raw = '[@iid:98063412749627392what is on my screen?';
    final out = composerMentionDisplayRestore(raw, const []);
    expect(out, contains(composerMentionToken(deviceId)));
    expect(out, contains('what is on my screen?'));
    expect(out, isNot(contains('[@iid:')));
  });

  test('composerMentionStripDanglingOpenBrackets removes truncated title tail', () {
    expect(
      composerMentionStripDanglingOpenBrackets('[@iid:9806341274962'),
      '',
    );
  });

  test('composerMentionSanitizeLabelLeaks repairs corrupt suffix', () {
    const deviceId = 'iid:42';
    const mentions = [
      CatalogMention(
        id: deviceId,
        topicId: 'device',
        icon: '',
        color: '',
        labelKey: '',
        captionKey: '',
        label: 'VM1',
        kind: 'identity',
      ),
    ];
    final corrupt = '${composerMentionToken(deviceId)}|VM1]|VM1]change A3';
    final out = composerMentionDisplayFinalize(corrupt, mentions);
    expect(out, contains(composerMentionToken(deviceId)));
    expect(out, isNot(contains('|VM1]')));
    expect(out, contains('change A3'));
  });

  test('composerMentionTextForWire collapses bracket shell before chip token', () {
    const deviceId = 'iid:98063412749627392';
    final token = composerMentionToken(deviceId);
    final wire = composerMentionTextForWire(
      '[@ $token ]tambahkan 5 baris contoh',
      const [],
      mentionIds: [deviceId],
    );
    expect(wire, startsWith('[@iid:98063412749627392]'));
    expect(wire, isNot(contains('[@[')));
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