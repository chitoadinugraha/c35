import 'dart:convert';

import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/catalog.pb.dart';
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
    this.label = '',
    this.kind = '',
    this.sort = 0,
  });

  final String id;
  final String topicId;
  final String icon;
  final String color;
  final int sort;
  final String labelKey;
  final String captionKey;
  final String label;
  final String kind;

  bool get isDevice => kind == 'identity' && topicId == 'device';

  String get displayLabel {
    if (label.isNotEmpty) return label;
    if (labelKey.isEmpty) return id;
    return labelKey.contains('.') ? catalogT(labelKey) : labelKey;
  }

  String get displayCaption {
    if (captionKey.isEmpty) return '';
    return captionKey.contains('.') ? catalogT(captionKey) : captionKey;
  }

  factory CatalogMention.fromMentionItem(MentionItem item) => CatalogMention(
        id: item.id,
        topicId: item.topicId,
        icon: item.icon,
        color: item.color,
        sort: item.sort,
        labelKey: item.labelKey,
        captionKey: item.captionKey,
        label: item.label.isNotEmpty ? item.label : item.title,
        kind: item.kind,
      );

  factory CatalogMention.fromJson(Map<String, dynamic> j) => CatalogMention(
        id: '${j['id'] ?? ''}',
        topicId: '${j['topic_id'] ?? ''}',
        icon: '${j['icon'] ?? ''}',
        color: '${j['color'] ?? ''}',
        sort: (j['sort'] as num?)?.toInt() ?? 0,
        labelKey: '${j['label_key'] ?? ''}',
        captionKey: '${j['caption_key'] ?? ''}',
        label: '${j['label'] ?? ''}',
        kind: '${j['kind'] ?? ''}',
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
