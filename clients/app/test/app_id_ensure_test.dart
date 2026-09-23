import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/app_id_ensure.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Session.instance.clear(clearStored: true);
  });

  test('appIdEnsure sets marker on fresh install without clearing', () async {
    await appIdEnsure();
    final p = await SharedPreferences.getInstance();
    expect(p.getString(C35AppId.markerKey), C35AppId.id);
    expect(Session.instance.signedIn, isFalse);
  });

  test('appIdEnsure clears session on legacy server host migration', () async {
    final p = await SharedPreferences.getInstance();
    await p.setString('id.alienai.c35.server_host', 'https://api.alienai.id');
    await p.setInt(C35AppId.sessionUid, 42);
    await p.setString(C35AppId.sessionToken, 'tok');

    await appIdEnsure();

    expect(Session.instance.signedIn, isFalse);
    expect(p.getString(C35AppId.markerKey), C35AppId.id);
    expect(p.getString(C35AppId.serverHostKey), 'https://api.alienai.id');
    expect(p.containsKey('id.alienai.c35.server_host'), isFalse);
  });

  test('deviceInstallId uses c35- prefix', () async {
    await appIdEnsure();
    final id = await deviceInstallId();
    expect(id.startsWith('c35-'), isTrue);
  });

  test('appIdEnsure clears session when install id lacks c35- prefix', () async {
    final p = await SharedPreferences.getInstance();
    await p.setString(C35AppId.markerKey, C35AppId.id);
    await p.setString(C35AppId.installId, 'plain-uuid');
    await p.setInt(C35AppId.sessionUid, 7);
    await p.setString(C35AppId.sessionToken, 'tok');

    await appIdEnsure();

    expect(Session.instance.signedIn, isFalse);
    expect(p.containsKey(C35AppId.installId), isFalse);
  });
}
