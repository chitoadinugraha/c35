import 'dart:convert';

import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheRevKey = 'c35.catalog.translation.rev';
const _cacheLangKey = 'c35.catalog.translation.lang';
const _cacheJsonKey = 'c35.catalog.translation.json';

/// English fallback bundled with the client (server `ai.translation` is authoritative per locale).
const _enFallback = <String, String>{
  'tool.web.search.calling': 'Searching web…',
  'tool.web.search.done': 'Searched web',
  'tool.web.visit.calling': 'Reading source…',
  'tool.web.visit.done': 'Read source',
  'tool.web.research.calling': 'Researching…',
  'tool.web.research.done': 'Researched',
  'tool.img.generate.calling': 'Generating image…',
  'tool.img.generate.done': 'Generated image',
  'tool.consumption.add.calling': 'Logging food…',
  'tool.consumption.add.done': 'Logged food',
  'tool.consumption.today.calling': 'Checking meals today…',
  'tool.consumption.today.done': 'Checked meals today',
  'mention.research.label': 'Research',
  'mention.research.caption': 'Deep web research',
  'mention.image.label': 'Image',
  'mention.image.caption': 'Generate an image',
  'mention.memorize.label': 'Memorize',
  'mention.memorize.caption': 'Save a fact to memory',
  'topic.general.label': 'General',
  'topic.general.caption': 'Default assistant',
  'topic.research.label': 'Research',
  'topic.research.caption': 'Multi-source web research',
  'topic.image.label': 'Image',
  'topic.image.caption': 'Image generation',
  'composer.ask.label': 'Ask',
  'composer.ask.caption': 'Answer without tools',
};

final catalogTranslationTick = ValueNotifier(0);

class CatalogTranslationCache {
  CatalogTranslationCache._();
  static final CatalogTranslationCache instance = CatalogTranslationCache._();

  String _lang = 'en';
  int _rev = 0;
  Map<String, String> _map = Map<String, String>.from(_enFallback);

  String get lang => _lang;
  int get rev => _rev;

  String t(String key) {
    final k = key.trim();
    if (k.isEmpty) return '';
    return _map[k] ?? _enFallback[k] ?? k;
  }

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString(_cacheLangKey) ?? 'en';
    _rev = p.getInt(_cacheRevKey) ?? 0;
    final raw = p.getString(_cacheJsonKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _map = {..._enFallback, ...decoded.map((k, v) => MapEntry(k, '$v'))};
      } catch (_) {
        _map = Map<String, String>.from(_enFallback);
      }
    } else {
      _map = Map<String, String>.from(_enFallback);
    }
    catalogTranslationTick.value++;
  }

  Future<void> ensure(String lang, {bool force = false}) async {
    final locale = lang.trim().isEmpty ? 'en' : lang.trim();
    try {
      final remote = await catalogTranslationsFetch(locale);
      if (!force && locale == _lang && remote.rev > 0 && remote.rev == _rev) return;
      _lang = locale;
      _rev = remote.rev;
      _map = {..._enFallback, ...remote.translations};
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheLangKey, _lang);
      await p.setInt(_cacheRevKey, _rev);
      await p.setString(_cacheJsonKey, jsonEncode(_map));
      catalogTranslationTick.value++;
    } catch (e) {
      lError('catalog translation ensure: $e');
      if (_map.isEmpty) _map = Map<String, String>.from(_enFallback);
    }
  }
}

String catalogT(String key) => CatalogTranslationCache.instance.t(key);

String toolCallingLabel(String toolId) {
  final id = toolId.replaceAll('_', '.').trim();
  if (id.isEmpty) return 'Tool';
  return catalogT('tool.$id.calling');
}

String toolDoneLabel(String toolId) {
  final id = toolId.replaceAll('_', '.').trim();
  if (id.isEmpty) return 'Tool';
  return catalogT('tool.$id.done');
}
