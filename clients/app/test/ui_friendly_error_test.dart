import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uiFriendlyError maps websocket failures to cannot connect copy', () {
    const raw = 'WebSocketChannelException: HttpException: Connection closed before full header was received, uri = http://127.0.0.1:8080/v1/ws';
    expect(uiFriendlyError(raw), uiCannotConnectToAlienAi);
    expect(uiIsConnectionError(raw), isTrue);
  });

  test('uiFriendlyError maps a closed socket send to connection failed', () {
    const raw = 'Bad state: Cannot add event after closing.';
    expect(uiFriendlyError(raw), uiConnectionFailed);
    expect(uiPromptErrorMessage(raw), uiConnectionFailed);
    expect(uiIsConnectionError(raw), isTrue);
    expect(uiFriendlyError('disconnected'), uiConnectionFailed);
    expect(uiFriendlyError('Bad state: Connection failed'), uiConnectionFailed);
  });

  test('uiFriendlyError and uiIsQuotaError recognize quota exhaustion', () {
    const freemium = 'freemium daily limit: 30 messages per day used. Subscribe to Lite or above for full access.';
    expect(uiIsQuotaError(freemium), isTrue);
    expect(uiFriendlyError(freemium), contains('free daily message limit'));

    const onDemand5h = 'quota exceeded: 5-hour allowance exhausted. Please top up at least IDR 1.000 or wait for the 5-hour quota window to reset.';
    expect(uiIsQuotaError(onDemand5h), isTrue);
    expect(uiFriendlyError(onDemand5h), contains('5-hour quota allowance'));

    const insufficientBal = 'quota exceeded: insufficient safe balance. Minimum IDR 1.000 required to start turn.';
    expect(uiIsQuotaError(insufficientBal), isTrue);
    expect(uiFriendlyError(insufficientBal), "You're out of quota. Upgrade your plan or top up your balance to continue.");

    const liveExhausted = 'Billing quota exhausted';
    expect(uiIsQuotaError(liveExhausted), isTrue);
    expect(uiFriendlyError(liveExhausted), contains("out of quota"));
  });
}
