import 'package:alienai_c35/core/notify/local_notif.dart';
import 'package:alienai_c35/core/notify/notify_router.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocal implements LocalNotifPort {
  int calls = 0;

  @override
  Future<void> post({required String title, required String body, required String routeJson}) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeLocal local;

  setUp(() {
    local = _FakeLocal();
    NotifyRouter.localPort = local;
    NotifyRouter.bannerCalls = 0;
    NotifyRouter.onBanner = null;
  });

  testWidgets('resumed shows the banner path and skips local notification', (tester) async {
    var banners = 0;
    NotifyRouter.onBanner = (title, body, routeJson) {
      banners++;
    };
    await NotifyRouter.show('Title', 'Body', '{"chat_id":1}', resumed: true);
    expect(local.calls, 0);
    expect(banners, 1);
    expect(NotifyRouter.bannerCalls, 1);
  });

  testWidgets('background posts one local notification and skips the banner', (tester) async {
    var banners = 0;
    NotifyRouter.onBanner = (title, body, routeJson) {
      banners++;
    };
    await NotifyRouter.show('Title', 'Body', '{}', resumed: false);
    expect(local.calls, 1);
    expect(banners, 0);
    expect(NotifyRouter.bannerCalls, 0);
  });
}
