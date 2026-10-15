import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_account_role_badges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('director badge labels hide duplicate director chip', () {
    final s = Session.instance;
    s.globalRoles = const ['director', 'finance'];
    s.rootAccessEnabled = false;
    s.uid = 1;

    final action = UiAccountRoleBadgesAction(onDirectorManageSite: () {});
    final labels = uiAccountRoleBadgeLabels(s, action);
    expect(labels, isNot(contains('Director')));
    expect(uiAccountRoleShowDirectorBadge(s, action), isTrue);
  });

  test('root shows director badge when manage site nav is wired', () {
    final s = Session.instance;
    s.globalRoles = const ['root'];
    s.rootAccessEnabled = true;
    s.uid = 99000;

    final action = UiAccountRoleBadgesAction(onDirectorManageSite: () {});
    final labels = uiAccountRoleBadgeLabels(s, action);
    expect(labels, contains('Root'));
    expect(uiAccountRoleShowDirectorBadge(s, action), isTrue);
  });
}
