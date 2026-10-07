import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasMetrics ignores model-only rows (thinking / streaming)', () {
    const modelOnly = MsgUsageStats(model: 'alienai');
    expect(modelOnly.hasData, isTrue);
    expect(modelOnly.hasMetrics, isFalse);
    expect(msgUsageStreaming(busy: true, msgReqId: 'a', liveReqId: 'a'), isTrue);
  });
}
