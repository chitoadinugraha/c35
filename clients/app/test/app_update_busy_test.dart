import 'package:alienai_c35/c/update/app_update_busy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appUpdateUserBusyFromSignals is false when idle', () {
    expect(
      appUpdateUserBusyFromSignals(
        promptBusy: false,
        promptInFlight: false,
        liveCallActive: false,
        remoteControlActive: false,
      ),
      isFalse,
    );
  });

  test('appUpdateUserBusyFromSignals ORs busy sources', () {
    expect(
      appUpdateUserBusyFromSignals(
        promptBusy: true,
        promptInFlight: false,
        liveCallActive: false,
        remoteControlActive: false,
      ),
      isTrue,
    );
    expect(
      appUpdateUserBusyFromSignals(
        promptBusy: false,
        promptInFlight: true,
        liveCallActive: false,
        remoteControlActive: false,
      ),
      isTrue,
    );
    expect(
      appUpdateUserBusyFromSignals(
        promptBusy: false,
        promptInFlight: false,
        liveCallActive: true,
        remoteControlActive: false,
      ),
      isTrue,
    );
    expect(
      appUpdateUserBusyFromSignals(
        promptBusy: false,
        promptInFlight: false,
        liveCallActive: false,
        remoteControlActive: true,
      ),
      isTrue,
    );
  });
}
