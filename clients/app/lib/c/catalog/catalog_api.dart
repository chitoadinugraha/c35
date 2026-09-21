import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:http/http.dart' as http;

class CatalogMention {
  const CatalogMention({
    required this.id,
    required this.topicId,
    required this.icon,
    required this.color,
    required this.labelKey,
    required this.captionKey,
    this.sort = 0,
  });

  final String id;
  final String topicId;
  final String icon;
  final String color;
  final int sort;
  final String labelKey;
  final String captionKey;

  factory CatalogMention.fromJson(Map<String, dynamic> j) => CatalogMention(
        id: '${j['id'] ?? ''}',
        topicId: '${j['topic_id'] ?? ''}',
        icon: '${j['icon'] ?? ''}',
        color: '${j['color'] ?? ''}',
        sort: (j['sort'] as num?)?.toInt() ?? 0,
        labelKey: '${j['label_key'] ?? ''}',
        captionKey: '${j['caption_key'] ?? ''}',
      );
}

class CatalogTranslationsRes {
  const CatalogTranslationsRes({required this.lang, required this.rev, required this.translations});

  final String lang;
  final int rev;
  final Map<String, String> translations;
}

String _catalogBase() => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

Map<String, String> _authHeaders() {
  final token = Session.instance.token.trim();
  return {
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    if (token.isNotEmpty) 'X-Session-Token': token,
  };
}

Future<CatalogTranslationsRes> catalogTranslationsFetch(String lang, {String categories = 'tool,mention,topic'}) async {
  final uri = Uri.parse('${_catalogBase()}/v1/translations/$lang').replace(queryParameters: {'category': categories});
  final res = await http.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw 'translations fetch failed (${res.statusCode})';
  final j = jsonDecode(res.body) as Map<String, dynamic>;
  final raw = j['translations'];
  final map = <String, String>{};
  if (raw is Map) {
    for (final e in raw.entries) {
      map['${e.key}'] = '${e.value}';
    }
  }
  return CatalogTranslationsRes(lang: '${j['lang'] ?? lang}', rev: (j['rev'] as num?)?.toInt() ?? 0, translations: map);
}

Future<List<CatalogMention>> catalogMentionsFetch() async {
  final res = await http.get(Uri.parse('${_catalogBase()}/v1/catalog/mentions'), headers: _authHeaders()).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw 'mentions fetch failed (${res.statusCode})';
  final j = jsonDecode(res.body) as Map<String, dynamic>;
  final rows = j['mentions'];
  if (rows is! List) return const [];
  return rows.map((e) => CatalogMention.fromJson(Map<String, dynamic>.from(e as Map))).toList();
}
