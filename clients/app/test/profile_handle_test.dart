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
}
