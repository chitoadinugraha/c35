import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:alienai_c35/c/presentation/slide_theme_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolve maps aliases to canonical theme id', () {
    expect(SlideThemeCatalog.resolve('corporate').id, 'emerald');
    expect(SlideThemeCatalog.resolve('indigo').id, 'midnight');
    expect(SlideThemeCatalog.resolve('light').id, 'arctic');
    expect(SlideThemeCatalog.resolve('amethyst').id, 'lavender');
    expect(SlideThemeCatalog.resolve('editorial').id, 'cream');
    expect(SlideThemeCatalog.resolve('bw').id, 'monochrome');
    expect(SlideThemeCatalog.resolve('nature').id, 'forest');
    expect(SlideThemeCatalog.resolve('blossom').id, 'sakura');
    expect(SlideThemeCatalog.resolve('synthwave').id, 'cyberpunk');
    expect(SlideThemeCatalog.resolve('espresso').id, 'coffee');
    expect(SlideThemeCatalog.resolve('nordic').id, 'aurora');
    expect(SlideThemeCatalog.resolve('unknown').id, 'dark');
  });

  test('catalog has sixteen themes with icons', () {
    expect(SlideThemeCatalog.items.length, 16);
    expect(SlideThemeCatalog.items.every((t) => t.icon.startsWith('iconify://')), isTrue);
  });

  test('builtin dark tokens match preview accent', () {
    final dark = SlideThemeCatalog.resolve('dark');
    expect(dark.accent, const Color(0xFFF97316));
    expect(dark.canvasBg, const Color(0xFF0D0D11));
  });

  test('colorFromHex parses 6-digit hex', () {
    expect(SlideTheme.colorFromHex('#F97316', const Color(0x00000000)), const Color(0xFFF97316));
  });
}
