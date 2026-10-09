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
  'tool.var.source': 'source',
  'tool.var.query': 'web',
  'tool.web.search.calling': 'Searching {{query}}…',
  'tool.web.search.done': 'Searched {{query}}',
  'tool.web.visit.calling': 'Reading {{source}}…',
  'tool.web.visit.done': 'Read {{source}}',
  'tool.web.research.calling': 'Researching {{query}}…',
  'tool.web.research.done': 'Researched {{query}}',
  'tool.img.generate.calling': 'Generating image…',
  'tool.img.generate.done': 'Generated image',
  'tool.site.pic.generate.calling': 'Generating site image…',
  'tool.site.pic.generate.done': 'Updated site image',
  'tool.img.edit.calling': 'Editing image…',
  'tool.img.edit.done': 'Edited image',
  'chat.image.upgrade_hd': 'Upgrade to HD',
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
  'tool.account.get.calling': 'Loading your profile…',
  'tool.account.get.done': 'Loaded profile',
  'tool.account.billing.get.calling': 'Checking balance and plan…',
  'tool.account.billing.get.done': 'Checked balance',
  'tool.account.billing.history.calling': 'Loading billing history…',
  'tool.account.billing.history.done': 'Loaded billing history',
  'tool.account.referral.stats.calling': 'Loading referral stats…',
  'tool.account.referral.stats.done': 'Loaded referral stats',
  'tool.account.referral.ledger.calling': 'Loading commission history…',
  'tool.account.referral.ledger.done': 'Loaded commission history',
  'tool.account.snapshot.calling': 'Loading account summary…',
  'tool.account.snapshot.done': 'Loaded account summary',
  'tool.device.list.calling': 'Listing your devices…',
  'tool.device.list.done': 'Listed devices',
  'tool.device.pair.calling': 'Pairing device…',
  'tool.device.pair.done': 'Device paired',
  'tool.bot.list.calling': 'Listing your bots…',
  'tool.bot.list.done': 'Listed bots',
  'tool.site.list.calling': 'Listing your sites…',
  'tool.site.list.done': 'Listed sites',
  'tool.client.list.calling': 'Listing app installs…',
  'tool.client.list.done': 'Listed app installs',
  'mention.research.label': 'Research',
  'mention.research.caption': 'Deep web research',
  'mention.image_high.label': 'Image HD',
  'mention.image_high.caption': 'Pro Flash Image (2K)',
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
  'live.call.verb': 'Call',
  'live.chip.generic': 'Call AI',
  'live.alienai.label': 'Alien AI',
  'live.gemini.label': 'Gemini',
  'live.gemini.thinker.label': 'Gemini Thinker',
  'live.chatgpt.label': 'ChatGPT',
  'live.grok.label': 'Grok',
  'home.liveCall': 'Live Call',
  'home.talkMode': 'Talk Mode',
  'home.chatMode': 'Chat Mode',
  'live.soon': 'Coming soon',
  'live.call.calling': 'Calling…',
  'live.call.limit': 'Call limit',
  'live.call.available': 'available',
  'live.call.no_limit': 'No quota or balance',
  'live.call.top_up_upgrade': 'Top up / Upgrade →',
  'live.price.voice': 'Voice',
  'live.price.video': 'Video',
  'live.attach.title': 'Attach media or document',
  'live.attach.photo': 'Photo',
  'live.attach.file': 'Document',
  'live.attach.clip': 'Send File',
  'live.attach.file_send': 'Send File',
  'presentation.theme.dark.label': 'Dark Neon',
  'presentation.theme.midnight.label': 'Midnight Indigo',
  'presentation.theme.emerald.label': 'Emerald Modern',
  'presentation.theme.sunset.label': 'Sunset Glow',
  'presentation.theme.ocean.label': 'Ocean Deep',
  'presentation.theme.ruby.label': 'Ruby Noir',
  'presentation.theme.gold.label': 'Royal Gold',
  'presentation.theme.arctic.label': 'Arctic Light',
  'presentation.theme.lavender.label': 'Lavender Amethyst',
  'presentation.theme.cream.label': 'Editorial Cream',
  'presentation.theme.monochrome.label': 'Bauhaus Slate',
  'presentation.theme.forest.label': 'Forest Botanical',
  'presentation.theme.sakura.label': 'Sakura Blossom',
  'presentation.theme.cyberpunk.label': 'Neo Cyberpunk',
  'presentation.theme.coffee.label': 'Artisan Coffee',
  'presentation.theme.aurora.label': 'Boreal Aurora',
};

const _idFallback = <String, String>{
  'chat.image.upgrade_hd': 'Tingkatkan ke HD',
  'tool.var.source': 'sumber',
  'tool.var.query': 'web',
  'tool.web.search.calling': 'Mencari {{query}}…',
  'tool.web.search.done': 'Telusuri {{query}}',
  'tool.web.visit.calling': 'Membaca {{source}}…',
  'tool.web.visit.done': 'Baca {{source}}',
  'tool.web.research.calling': 'Meneliti {{query}}…',
  'tool.web.research.done': 'Teliti {{query}}',
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
  'tool.account.get.calling': 'Memuat profil…',
  'tool.account.get.done': 'Profil dimuat',
  'tool.account.billing.get.calling': 'Mengecek saldo dan paket…',
  'tool.account.billing.get.done': 'Saldo dicek',
  'tool.account.billing.history.calling': 'Memuat riwayat billing…',
  'tool.account.billing.history.done': 'Riwayat billing dimuat',
  'tool.account.referral.stats.calling': 'Memuat statistik referral…',
  'tool.account.referral.stats.done': 'Statistik referral dimuat',
  'tool.account.referral.ledger.calling': 'Memuat riwayat komisi…',
  'tool.account.referral.ledger.done': 'Riwayat komisi dimuat',
  'tool.account.snapshot.calling': 'Memuat ringkasan akun…',
  'tool.account.snapshot.done': 'Ringkasan akun dimuat',
  'tool.device.list.calling': 'Mendaftar device…',
  'tool.device.list.done': 'Device didaftar',
  'tool.device.pair.calling': 'Memasangkan device…',
  'tool.device.pair.done': 'Device terpasang',
  'tool.bot.list.calling': 'Mendaftar bot…',
  'tool.bot.list.done': 'Bot didaftar',
  'tool.site.list.calling': 'Mendaftar site…',
  'tool.site.list.done': 'Site didaftar',
  'tool.client.list.calling': 'Mendaftar instalasi app…',
  'tool.client.list.done': 'Instalasi app didaftar',
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
  'live.call.verb': 'Telepon',
  'live.chip.generic': 'Telepon AI',
  'live.alienai.label': 'Alien AI',
  'live.gemini.label': 'Gemini',
  'live.gemini.thinker.label': 'Gemini Thinker',
  'live.chatgpt.label': 'ChatGPT',
  'live.grok.label': 'Grok',
  'home.liveCall': 'Panggilan Live',
  'home.talkMode': 'Mode Bicara',
  'home.chatMode': 'Mode Chat',
  'live.soon': 'Segera hadir',
  'live.call.calling': 'Memanggil…',
  'live.call.limit': 'Batas panggilan',
  'live.call.available': 'tersedia',
  'live.call.no_limit': 'Tidak ada kuota atau saldo',
  'live.call.top_up_upgrade': 'Isi saldo / Tingkatkan →',
  'live.price.voice': 'Suara',
  'live.price.video': 'Video',
  'live.attach.title': 'Lampirkan media atau dokumen',
  'live.attach.photo': 'Foto',
  'live.attach.file': 'Dokumen',
  'live.attach.clip': 'Kirim File',
  'live.attach.file_send': 'Kirim File',
  'presentation.theme.dark.label': 'Dark Neon',
  'presentation.theme.midnight.label': 'Midnight Indigo',
  'presentation.theme.emerald.label': 'Emerald Modern',
  'presentation.theme.sunset.label': 'Sunset Glow',
  'presentation.theme.ocean.label': 'Ocean Deep',
  'presentation.theme.ruby.label': 'Ruby Noir',
  'presentation.theme.gold.label': 'Royal Gold',
  'presentation.theme.arctic.label': 'Arctic Light',
  'presentation.theme.lavender.label': 'Lavender Amethyst',
  'presentation.theme.cream.label': 'Editorial Cream',
  'presentation.theme.monochrome.label': 'Bauhaus Slate',
  'presentation.theme.forest.label': 'Forest Botanical',
  'presentation.theme.sakura.label': 'Sakura Blossom',
  'presentation.theme.cyberpunk.label': 'Neo Cyberpunk',
  'presentation.theme.coffee.label': 'Artisan Coffee',
  'presentation.theme.aurora.label': 'Boreal Aurora',
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
