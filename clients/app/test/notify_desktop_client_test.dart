import 'package:alienai_c35/core/notify/notify_desktop_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseNotifyPushPayload decodes JSON line', () {
    final p = parseNotifyPushPayload(
      r'notify_push {"id":42,"title":"T","body":"B","route_json":"{\"chat_id\":1}"}',
    );
    expect(p, isNotNull);
    expect(p!.id, 42);
    expect(p.title, 'T');
    expect(p.body, 'B');
    expect(p.routeJson, '{"chat_id":1}');
  });

  test('parseNotifyPushPayload rejects bad prefix', () {
    expect(parseNotifyPushPayload('hello'), isNull);
  });
}
