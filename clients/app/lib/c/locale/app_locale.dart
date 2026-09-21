import 'package:flutter/material.dart';

class AppLocaleEntry {
  const AppLocaleEntry({
    required this.locale,
    required this.name,
    required this.flag,
    this.searchTerms = const [],
  });

  final Locale locale;
  final String name;
  final String flag;
  final List<String> searchTerms;
}

const appLocales = <AppLocaleEntry>[
  AppLocaleEntry(
    locale: Locale('en', 'US'),
    name: 'English',
    flag: 'iconify://circle-flags:us',
    searchTerms: ['english', 'inggris', 'en', 'us'],
  ),
  AppLocaleEntry(
    locale: Locale('id', 'ID'),
    name: 'Bahasa Indonesia',
    flag: 'iconify://circle-flags:id',
    searchTerms: ['indonesia', 'indonesian', 'bahasa', 'id'],
  ),
];

const appLocaleSupported = <Locale>[Locale('en', 'US'), Locale('id', 'ID')];

AppLocaleEntry appLocaleMeta(Locale locale) {
  for (final e in appLocales) {
    if (e.locale.languageCode == locale.languageCode) return e;
  }
  return appLocales.first;
}

String appLocaleLabel(Locale locale) => appLocaleMeta(locale).name;

bool appLocaleSame(Locale a, Locale b) => a.languageCode == b.languageCode;

List<AppLocaleEntry> appLocaleFilter(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [...appLocales];
  return appLocales.where((loc) {
    if (loc.name.toLowerCase().contains(q)) return true;
    if (loc.locale.languageCode.toLowerCase().contains(q)) return true;
    return loc.searchTerms.any((t) => t.toLowerCase().contains(q));
  }).toList();
}
