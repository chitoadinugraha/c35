import 'dart:typed_data';

import 'package:alienai_c35/c/chat/composer_draft_store.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores drafts per chat id and new-chat sentinel', () {
    final store = ComposerDraftStore.instance;
    store.put(null, text: 'hello new', mentionIds: const ['iid:1']);
    store.put(42, text: 'chat forty-two', mentionIds: const []);
    expect(store.get(null)?.text, 'hello new');
    expect(store.get(42)?.text, 'chat forty-two');
    store.remove(null);
    expect(store.get(null), isNull);
  });

  test('migrateKey moves draft when pending chat becomes server id', () {
    final store = ComposerDraftStore.instance;
    store.put(-3, text: 'pending', mentionIds: const []);
    store.migrateKey(-3, 9001);
    expect(store.get(-3), isNull);
    expect(store.get(9001)?.text, 'pending');
  });

  test('persists to shared preferences per uid', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ComposerDraftStore.instance;
    await store.restoreForUid(99000);
    store.put(null, text: 'x', mentionIds: const []);
    await store.restoreForUid(99000);
    store.put(7, text: 'saved', mentionIds: const ['vm']);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await store.restoreForUid(99000);
    expect(store.get(7)?.text, 'saved');
    expect(store.get(7)?.mentionIds, ['vm']);
    await store.clearForUid(99000);
    await store.restoreForUid(99000);
    expect(store.get(7), isNull);
  });

  test('attachments round-trip url/hash only', () {
    final store = ComposerDraftStore.instance;
    final staged = [
      StagedMedia(
        name: 'photo.png',
        bytes: Uint8List(0),
        mime: 'image/png',
        type: MediaType.image,
        size: 1234,
        hash: 'abc123',
        previewUrl: '/fs/abc123',
        uploadProgress: 1.0,
      ),
    ];
    store.put(1, text: '', mentionIds: const [], stagedAttachments: staged);
    final draft = store.get(1);
    expect(draft?.attachments.length, 1);
    expect(draft!.attachments.first.hash, 'abc123');
    expect(draft.attachments.first.url, '/fs/abc123');
    final restored = draft.attachments.first.toStaged();
    expect(restored.hash, 'abc123');
    expect(restored.bytes.isEmpty, isTrue);
    store.remove(1);
  });
}
