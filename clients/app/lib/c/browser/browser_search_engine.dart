import 'package:shared_preferences/shared_preferences.dart';

class BrowserSearchEngine {
  const BrowserSearchEngine({
    required this.id,
    required this.name,
    this.description = '',
    required this.searchUrl,
    this.faviconUrl = '',
  });

  final String id;
  final String name;
  final String description;
  final String searchUrl;
  final String faviconUrl;

  String search(String query) => searchUrl.replaceAll('{q}', Uri.encodeQueryComponent(query));
}

const browserSearchEnginesFallback = [
  BrowserSearchEngine(
    id: 'google',
    name: 'Google',
    description: 'Web search',
    searchUrl: 'https://www.google.com/search?q={q}',
    faviconUrl: 'https://www.google.com/s2/favicons?domain=google.com&sz=32',
  ),
  BrowserSearchEngine(
    id: 'duckduckgo',
    name: 'DuckDuckGo',
    description: 'Privacy-focused search',
    searchUrl: 'https://duckduckgo.com/?q={q}',
    faviconUrl: 'https://www.google.com/s2/favicons?domain=duckduckgo.com&sz=32',
  ),
  BrowserSearchEngine(
    id: 'brave',
    name: 'Brave Search',
    description: 'Independent search index',
    searchUrl: 'https://search.brave.com/search?q={q}',
    faviconUrl: 'https://www.google.com/s2/favicons?domain=search.brave.com&sz=32',
  ),
  BrowserSearchEngine(
    id: 'bing',
    name: 'Bing',
    description: 'Microsoft web search',
    searchUrl: 'https://www.bing.com/search?q={q}',
    faviconUrl: 'https://www.google.com/s2/favicons?domain=bing.com&sz=32',
  ),
  BrowserSearchEngine(
    id: 'wikipedia',
    name: 'Wikipedia',
    description: 'Free encyclopedia',
    searchUrl: 'https://en.wikipedia.org/w/index.php?search={q}',
    faviconUrl: 'https://www.google.com/s2/favicons?domain=wikipedia.org&sz=32',
  ),
];

const browserHomeUrl = 'about:home';

BrowserSearchEngine browserSearchEngineById(String id, [List<BrowserSearchEngine>? engines]) {
  final list = engines ?? browserSearchEnginesFallback;
  return list.firstWhere((e) => e.id == id, orElse: () => list.first);
}

String browserOmniboxHintFor(BrowserSearchEngine engine) => 'Search ${engine.name} or type a URL';

const browserHomeHttps = 'https://alienai.id/search';

bool browserTabIsHome(String url) {
  final u = url.trim().toLowerCase();
  return u.isEmpty ||
      u == 'about:blank' ||
      u == 'about:newtab' ||
      u == browserHomeUrl ||
      u == browserHomeHttps ||
      u.contains('alienai.id/search') ||
      u.contains('/_c35/home.html');
}

String browserTabTitleFromUrl(String url) {
  if (browserTabIsHome(url)) return 'Alien AI';
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return 'New tab';
  return host.startsWith('www.') ? host.substring(4) : host;
}

String browserTabFaviconUrl(String url, {String? favicon}) {
  if (favicon != null && favicon.isNotEmpty && (favicon.startsWith('https://') || favicon.startsWith('http://'))) {
    return favicon;
  }
  if (browserTabIsHome(url)) {
    return 'https://www.google.com/s2/favicons?domain=alienai.id&sz=32';
  }
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return '';
  return 'https://www.google.com/s2/favicons?domain=${Uri.encodeQueryComponent(host)}&sz=32';
}

bool _browserLooksLikeUrl(String t) {
  if (t.contains(RegExp(r'\s'))) return false;
  if (t.startsWith('http://') || t.startsWith('https://') || t.startsWith('about:')) return true;
  if (t == 'localhost' || t.startsWith('localhost:') || t.startsWith('127.0.0.1')) return true;
  return RegExp(r'^[a-zA-Z0-9][\w.-]*\.[a-zA-Z]{2,}([/:?#].*)?$').hasMatch(t);
}

String browserOmniboxTarget(String raw, {required BrowserSearchEngine engine}) {
  final t = raw.trim();
  if (t.isEmpty || browserTabIsHome(t)) return browserHomeHttps;
  if (t.contains('://')) return t;
  if (_browserLooksLikeUrl(t)) return t.startsWith('http') ? t : 'https://$t';
  return engine.search(t);
}

const _prefsEngineKey = 'c35.browser.search_engine';

Future<String> browserSearchEngineIdLoad() async {
  final p = await SharedPreferences.getInstance();
  return p.getString(_prefsEngineKey) ?? browserSearchEnginesFallback.first.id;
}

Future<void> browserSearchEngineIdSave(String id) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_prefsEngineKey, id);
}