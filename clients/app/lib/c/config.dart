/// Default API base — override at runtime via [serverHostInit] / [C35Config.authApiBase].
const authApiProductionUrl = 'https://api.alienai.id';
const authApiLocalUrl = 'http://127.0.0.1:8080';

class C35Config {
  static String authApiBase = authApiProductionUrl;
  /// OAuth / provider sign-in always uses production (Google callback is registered there).
  static const providerAuthBase = authApiProductionUrl;
}
