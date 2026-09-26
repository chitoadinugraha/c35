import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/hint/hint_store.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Session.instance.uid = 33000;
    Session.instance.token = 'test';
    await HintStore.instance.clearForUid(33000);
    await HintStore.instance.restore();
  });

  group('HintStore', () {
    test('merge skips when updated_ts_ms is not newer', () async {
      final store = HintStore.instance;
      await store.merge(
        HintCatalog(
          updatedTsMs: Int64(100),
          items: [HintItem(id: 'a', label: 'A')],
        ),
        sinceMs: 0,
      );
      expect(store.rev, 100);
      expect(store.items.length, 1);

      await store.merge(
        HintCatalog(updatedTsMs: Int64(100), items: [HintItem(id: 'b', label: 'B')]),
        sinceMs: store.rev,
      );
      expect(store.rev, 100);
      expect(store.items.first.id, 'a');
    });

    test('merge updates rev when server returns empty items', () async {
      final store = HintStore.instance;
      await store.merge(
        HintCatalog(
          updatedTsMs: Int64(200),
          items: [HintItem(id: 'c', label: 'C')],
        ),
        sinceMs: store.rev,
      );
      expect(store.rev, 200);
      expect(store.items.first.id, 'c');

      await store.merge(HintCatalog(updatedTsMs: Int64(250)), sinceMs: store.rev);
      expect(store.rev, 250);
      expect(store.items.first.id, 'c');
    });
  });

  group('hintPayloadText', () {
    test('prefers text over send_text', () {
      expect(hintPayloadText({'text': 'hello', 'send_text': 'old'}, fallback: 'fb'), 'hello');
      expect(hintPayloadText({'send_text': 'legacy'}, fallback: 'fb'), 'legacy');
      expect(hintPayloadText({}, fallback: 'fb'), 'fb');
    });
  });

  group('hintTouchAssetIid', () {
    test('reads site_iid from payload and hint id', () {
      final visit = HintItem(
        id: 'hint.site.42.visit',
        action: HintAction(kind: 'open_url', payloadJson: '{"url":"https://alienai.id/x"}'),
      );
      expect(hintTouchAssetIid(visit), 42);

      final pos = HintItem(
        id: 'hint.site.99.pos',
        action: HintAction(kind: 'navigate', payloadJson: '{"site_iid":"99"}'),
      );
      expect(hintTouchAssetIid(pos), 99);
    });
  });

  group('siteRowsFromHints', () {
    test('parses site parent chip for Sites list bootstrap', () {
      final items = [
        HintItem(
          id: 'hint.site:97265523201429504',
          label: 'Grosir Prakarya',
          icon: 'https://example.com/pic.png',
          sort: 30,
          items: [
            HintItem(
              id: 'hint.site.97265523201429504.visit',
              label: 'Visit',
              action: HintAction(
                kind: 'open_url',
                payloadJson: '{"url":"https://alienai.id/grosirprakarya","site_iid":"97265523201429504"}',
              ),
            ),
          ],
        ),
      ];
      final rows = siteRowsFromHints(items);
      expect(rows.length, 1);
      expect(rows.first.name, 'Grosir Prakarya');
      expect(rows.first.alienId, 'grosirprakarya');
      expect(rows.first.siteIid, Int64.parseInt('97265523201429504'));
    });
  });
}
