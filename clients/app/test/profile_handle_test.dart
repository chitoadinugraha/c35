import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profileHandleDisplay normalizes alien id', () {
    expect(profileHandleDisplay('chito'), '@chito');
    expect(profileHandleDisplay('@chito'), '@chito');
    expect(profileHandleDisplay(''), '@user');
  });

  test('profileAlienAddress matches handle display', () {
    expect(profileAlienAddress('@chito'), 'chito@alienai.id');
    expect(profileAlienAddress('chito'), 'chito@alienai.id');
  });

  test('profileIdentityLabel prefers alien id else email or phone', () {
    expect(profileIdentityLabel(handle: '@chito', email: 'gucicha@gmail.com'), 'chito@alienai.id');
    expect(profileIdentityLabel(handle: '', email: 'gucicha@gmail.com'), 'gucicha@gmail.com');
    expect(profileIdentityLabel(handle: '@user', email: 'gucicha@gmail.com'), 'gucicha@gmail.com');
    expect(profileIdentityLabel(handle: '', email: '', phone: '628123456789'), '628123456789');
    expect(profileIdentityLabel(handle: '', email: '', phone: ''), '');
  });
}
