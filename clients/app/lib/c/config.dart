/// Default API base — override at runtime via [C35Config.authApiBase].
const authApiDefaultUrl = 'http://127.0.0.1:8080';

class C35Config {
  static String authApiBase = authApiDefaultUrl;
  static const providerAuthBase = authApiDefaultUrl;
}
