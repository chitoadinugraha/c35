import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:alienai_c35/c/presentation/slide_theme_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolve maps aliases to canonical theme id', () {
    expect(SlideThemeCatalog.resolve('corporate').id, 'emerald');
    expect(SlideThemeCatalog.resolve('indigo').id, 'midnight');
    expect(SlideThemeCatalog.resolve('light').id, 'arctic');
    expect(SlideThemeCatalog.resolve('unknown').id, 'dark');
  });

  test('catalog has eight themes with icons', () {
    expect(SlideThemeCatalog.items.length, 8);
    expect(SlideThemeCatalog.items.every((t) => t.icon.startsWith('iconify://')), isTrue);
  });

  test('builtin dark tokens match preview accent', () {
    final dark = SlideThemeCatalog.resolve('dark');
    expect(dark.accent.value, 0xFFF97316);
    expect(dark.canvasBg.value, 0xFF0D0D11);
  });

  test('colorFromHex parses 6-digit hex', () {
    expect(SlideTheme.colorFromHex('#F97316', const Color(0)).value, 0xFFF97316);
  });
}
