import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('root access toggle gates isRoot for root role', () async {
    SharedPreferences.setMockInitialValues({});
    final s = Session.instance;
    await s.clear(clearStored: false);
    s.globalRoles = const ['root'];
    s.rootAccessEnabled = true;
    expect(s.hasRootRole, isTrue);
    expect(s.isRoot, isTrue);

    await s.rootAccessPut(false);
    expect(s.isRoot, isFalse);
    expect(s.hasRootRole, isTrue);

    final p = await SharedPreferences.getInstance();
    expect(p.getBool(C35AppId.sessionRootAccessEnabled), isFalse);

    await s.rootAccessPut(true);
    expect(s.isRoot, isTrue);
  });

  test('dev chito viewer respects root access toggle', () async {
    SharedPreferences.setMockInitialValues({});
    final s = Session.instance;
    await s.clear(clearStored: false);
    s.uid = 99000;
    s.globalRoles = const [];
    s.rootAccessEnabled = true;
    expect(s.isRoot, isTrue);

    await s.rootAccessPut(false);
    expect(s.isRoot, isFalse);
  });
}
