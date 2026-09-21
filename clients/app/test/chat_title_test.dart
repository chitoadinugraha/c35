import 'package:alienai_c35/c/chat/chat_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chatTitleFromText sentence case', () {
    expect(chatTitleFromText('sekarang jam berapa?'), 'Sekarang jam berapa?');
    expect(chatTitleFromText('SEKARANG HARI APA'), 'Sekarang hari apa');
    expect(chatTitleFromText('  '), 'Chat');
  });

  test('chatTitleDisplay hides empty and new chat', () {
    expect(chatTitleDisplay(''), '');
    expect(chatTitleDisplay('New chat'), '');
    expect(chatTitleDisplay('hello world'), 'Hello world');
  });
}
