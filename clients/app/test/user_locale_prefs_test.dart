import 'package:alienai_c35/c/location/user_location_prefs.dart';
import 'package:alienai_c35/c/settings/user_locale_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserLocalePrefs.instance.load();
    await UserLocationPrefs.instance.load();
  });

  test('mergeFromProfile applies server ip when local city empty', () async {
    await UserLocalePrefs.instance.put(locationSource: 'user');
    await UserLocalePrefs.instance.mergeFromProfile(
      locationCity: 'Jakarta',
      locationCountry: 'ID',
      locationSource: 'ip',
    );
    expect(UserLocalePrefs.instance.locationCity, 'Jakarta');
    expect(UserLocalePrefs.instance.locationSource, 'ip');
  });

  test('mergeFromProfile keeps manual city when locked', () async {
    await UserLocalePrefs.instance.put(
      locationCity: 'Bandung',
      locationSource: 'user',
    );
    await UserLocalePrefs.instance.mergeFromProfile(
      locationCity: 'Jakarta',
      locationSource: 'ip',
    );
    expect(UserLocalePrefs.instance.locationCity, 'Bandung');
    expect(UserLocalePrefs.instance.locationSource, 'user');
  });
}
