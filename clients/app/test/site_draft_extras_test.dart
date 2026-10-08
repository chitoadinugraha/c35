import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing notify reads as until_handled', () {
    expect(siteDraftExtrasParse('').orderRing, kSiteOrderRingUntilHandled);
    expect(siteDraftExtrasParse('{}').orderRing, kSiteOrderRingUntilHandled);
    expect(siteDraftExtrasParse('{"notify":{}}').orderRing, kSiteOrderRingUntilHandled);
    expect(siteDraftExtrasParse('{"tagline":"hi"}').orderRing, kSiteOrderRingUntilHandled);
  });

  test('once stays once', () {
    const raw = '{"notify":{"order_ring":"once"},"tagline":"hi"}';
    expect(siteDraftExtrasParse(raw).orderRing, kSiteOrderRingOnce);
    final merged = siteDraftExtrasMerge(raw, knowledge: const []);
    expect(siteDraftExtrasParse(merged).orderRing, kSiteOrderRingOnce);
    final rewritten = siteDraftExtrasMerge('{}', orderRing: kSiteOrderRingOnce);
    expect(siteDraftExtrasParse(rewritten).orderRing, kSiteOrderRingOnce);
  });

  test('knowledge round-trip', () {
    const item = SiteKnowledgeDraft(id: 'k1', title: 'Hours', content: 'Open 9 to 5');
    final encoded = siteDraftExtrasMerge('{"tagline":"hi"}', knowledge: const [item]);
    final parsed = siteDraftExtrasParse(encoded);
    expect(parsed.knowledge, hasLength(1));
    expect(parsed.knowledge.single.id, 'k1');
    expect(parsed.knowledge.single.title, 'Hours');
    expect(parsed.knowledge.single.content, 'Open 9 to 5');
    expect(siteDraftJsonMap(encoded)['tagline'], 'hi');
  });

  test('payment account round-trip', () {
    const item = SitePaymentAccountDraft(
      id: 'pa1',
      bank: 'BCA',
      accountName: 'Toko',
      accountNumber: '123',
      qrisPic: 'fs/qris.png',
    );
    final encoded = siteDraftExtrasMerge('{}', paymentAccounts: const [item]);
    final parsed = siteDraftExtrasParse(encoded);
    expect(parsed.paymentAccounts, hasLength(1));
    final row = parsed.paymentAccounts.single;
    expect(row.id, 'pa1');
    expect(row.bank, 'BCA');
    expect(row.accountName, 'Toko');
    expect(row.accountNumber, '123');
    expect(row.qrisPic, 'fs/qris.png');
  });
}
