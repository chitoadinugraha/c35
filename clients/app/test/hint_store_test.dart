import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/hint/hint_store.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
}
