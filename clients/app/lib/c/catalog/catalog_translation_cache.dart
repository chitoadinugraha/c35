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
  'tool.expense.add.calling': 'Logging expense…',
  'tool.expense.add.done': 'Logged expense',
  'tool.expense.summary.calling': 'Checking spending…',
  'tool.expense.summary.done': 'Checked spending',
  'tool.expense.delete.calling': 'Removing expense…',
  'tool.expense.delete.done': 'Removed expense',
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
  'hint.consumption_add.label': 'Track Consumption',
  'hint.consumption_add.send_text': 'Track food consumption',
  'hint.expense_add.label': 'Track Expense',
  'hint.expense_add.send_text': 'Track expense',
};

const _idFallback = <String, String>{
  'tool.consumption.add.calling': 'Mencatat makanan…',
  'tool.consumption.add.done': 'Makanan tercatat',
  'tool.consumption.today.calling': 'Mengecek makan hari ini…',
  'tool.consumption.today.done': 'Makan hari ini dicek',
  'tool.expense.add.calling': 'Mencatat pengeluaran…',
  'tool.expense.add.done': 'Pengeluaran tercatat',
  'tool.expense.summary.calling': 'Mengecek pengeluaran…',
  'tool.expense.summary.done': 'Pengeluaran dicek',
  'tool.expense.delete.calling': 'Menghapus pengeluaran…',
  'tool.expense.delete.done': 'Pengeluaran dihapus',
  'mention.research.label': 'Riset',
  'mention.research.caption': 'Riset web mendalam',
  'mention.image_high.label': 'Gambar HD',
  'mention.image_high.caption': 'Flash Image pro (2K)',
  'mention.image.label': 'Gambar',
  'mention.image.caption': 'Buat gambar',
  'mention.memorize.label': 'Ingat',
  'mention.memorize.caption': 'Simpan ke memori',
  'topic.general.label': 'Umum',
  'topic.general.caption': 'Asisten default',
  'topic.research.label': 'Riset',
  'topic.research.caption': 'Riset web multi-sumber',
  'topic.image.label': 'Gambar',
  'topic.image.caption': 'Pembuatan gambar',
  'composer.ask.label': 'Tanya',
  'composer.ask.caption': 'Jawab tanpa alat',
  'hint.consumption_add.label': 'Catat konsumsi makanan',
  'hint.consumption_add.send_text': 'Catat konsumsi makanan',
  'hint.expense_add.label': 'Catat pengeluaran',
  'hint.expense_add.send_text': 'Catat pengeluaran',
};

Map<String, String> catalogLocaleFallback(String lang) =>
    catalogLocaleCode(lang) == 'id' ? {..._enFallback, ..._idFallback} : _enFallback;

String catalogLocaleCode(String locale) {
  final s = locale.trim().toLowerCase();
  if (s.startsWith('id')) return 'id';
  return 'en';
}

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
    return _map[k] ?? catalogLocaleFallback(_lang)[k] ?? _enFallback[k] ?? k;
  }

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _lang = catalogLocaleCode(p.getString(_cacheLangKey) ?? 'en');
    _rev = p.getInt(_cacheRevKey) ?? 0;
    final raw = p.getString(_cacheJsonKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _map = {...catalogLocaleFallback(_lang), ...decoded.map((k, v) => MapEntry(k, '$v'))};
      } catch (_) {
        _map = Map<String, String>.from(catalogLocaleFallback(_lang));
      }
    } else {
      _map = Map<String, String>.from(catalogLocaleFallback(_lang));
    }
    catalogTranslationTick.value++;
  }

  Future<void> ensure(String lang, {bool force = false}) async {
    final locale = catalogLocaleCode(lang);
    try {
      final remote = await catalogTranslationsFetch(locale);
      if (!force && locale == _lang && remote.rev > 0 && remote.rev == _rev) return;
      _lang = locale;
      _rev = remote.rev;
      _map = {...catalogLocaleFallback(locale), ...remote.translations};
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheLangKey, _lang);
      await p.setInt(_cacheRevKey, _rev);
      await p.setString(_cacheJsonKey, jsonEncode(_map));
      catalogTranslationTick.value++;
    } catch (e) {
      lError('catalog translation ensure: $e');
      if (_map.isEmpty) _map = Map<String, String>.from(catalogLocaleFallback(locale));
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
