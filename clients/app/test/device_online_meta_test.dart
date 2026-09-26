import 'package:alienai_c35/c/device/device_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deviceOnlineFromMeta uses last_seen_ts_ms from agent presence', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(
      deviceOnlineFromMeta('{"online":true,"last_seen_ts_ms":$now}'),
      isTrue,
    );
  });

  test('deviceOnlineFromMeta is false when stale', () {
    final old = DateTime.now().millisecondsSinceEpoch - 300000;
    expect(
      deviceOnlineFromMeta('{"online":true,"last_seen_ts_ms":$old}'),
      isFalse,
    );
  });
}
