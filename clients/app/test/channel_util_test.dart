import 'package:alienai_c35/widgets/bots/channel_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('botChannelPlatforms ignores disconnected channels', () {
    const meta = '''
{
  "channels": [
    {"id": "wa-1", "platform": "whatsapp", "status": "disconnected"},
    {"id": "tg-1", "platform": "telegram", "status": "connected"}
  ]
}
''';
    expect(botChannelPlatforms(meta), ['telegram']);
  });

  test('botChannelPlatforms includes pairing channels', () {
    const meta = '''
{
  "channels": [
    {"id": "wa-1", "platform": "whatsapp", "status": "pairing"}
  ]
}
''';
    expect(botChannelPlatforms(meta), ['whatsapp']);
  });
}
