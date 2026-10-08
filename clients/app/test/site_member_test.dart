import 'package:alienai_c35/c/site/site_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('siteMemberRoleLabel', () {
    test('wire roles map to UI labels', () {
      expect(siteMemberRoleLabel('staff'), 'Staff');
      expect(siteMemberRoleLabel('manage'), 'Manager');
      expect(siteMemberRoleLabel('guest'), 'Guest');
      expect(siteMemberRoleLabel('owner'), 'Owner');
    });

    test('CSA roles map to same labels', () {
      expect(siteMemberRoleLabel('employee'), 'Staff');
      expect(siteMemberRoleLabel('manager'), 'Manager');
    });

    test('unknown role falls back to raw string', () {
      expect(siteMemberRoleLabel('custom'), 'custom');
    });
  });

  group('siteMemberRoleWire', () {
    test('maps CSA employee/manager to staff/manage', () {
      expect(siteMemberRoleWire('employee'), 'staff');
      expect(siteMemberRoleWire('manager'), 'manage');
      expect(siteMemberRoleWire('Staff'), 'staff');
      expect(siteMemberRoleWire('guest'), 'guest');
    });
  });

  group('siteMemberDisplayName', () {
    test('prefers trimmed display name over email', () {
      expect(
        siteMemberDisplayName(displayName: '  Ada Lovelace  ', email: 'ada@example.com'),
        'Ada Lovelace',
      );
    });

    test('falls back to email when name empty', () {
      expect(siteMemberDisplayName(displayName: '', email: 'ada@example.com'), 'ada@example.com');
      expect(siteMemberDisplayName(displayName: null, email: 'ada@example.com'), 'ada@example.com');
    });
  });

  group('siteMemberInitials', () {
    test('two-word name uses first and last initials', () {
      expect(siteMemberInitials(displayName: 'Ada Lovelace', email: 'a@x.com'), 'AL');
    });

    test('falls back to email prefix', () {
      expect(siteMemberInitials(displayName: '', email: 'ada@example.com'), 'AD');
    });
  });

  test('siteMemberRoles lists staff/manage/guest', () {
    expect(siteMemberRoles.map((e) => e.$1).toList(), ['staff', 'manage', 'guest']);
    expect(siteMemberRoles.map((e) => e.$2).toList(), ['Staff', 'Manager', 'Guest']);
  });

  test('siteMemberIsManager treats owner and manage', () {
    expect(siteMemberIsManager('owner'), isTrue);
    expect(siteMemberIsManager('manage'), isTrue);
    expect(siteMemberIsManager('manager'), isTrue);
    expect(siteMemberIsManager('staff'), isFalse);
    expect(siteMemberIsManager('guest'), isFalse);
  });
}
