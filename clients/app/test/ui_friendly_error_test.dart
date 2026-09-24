import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiFriendlyError maps websocket failures to cannot connect copy', () {
    const raw = 'WebSocketChannelException: HttpException: Connection closed before full header was received, uri = http://127.0.0.1:8080/v1/ws';
    expect(uiFriendlyError(raw), uiCannotConnectToAlienAi);
    expect(uiIsConnectionError(raw), isTrue);
  });
}
