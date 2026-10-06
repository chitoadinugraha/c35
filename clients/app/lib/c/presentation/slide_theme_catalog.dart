import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/presentation/presentation_theme_item.dart';
import 'package:alienai_c35/c/presentation/slide_theme.dart';

class SlideThemeCatalog {
  static List<PresentationThemeCatalogItem> _items = _builtinItems;

  static List<PresentationThemeCatalogItem> get items => List.unmodifiable(_items);

  static List<SlideTheme> get slideThemes => _items.map((e) => e.toSlideTheme()).toList();

  static SlideTheme resolve(String? ref) {
    final key = (ref ?? '').trim().toLowerCase();
    if (key.isEmpty) return slideThemes.first;
    for (final item in _items) {
      if (item.id == key) return item.toSlideTheme();
      if (item.aliases.any((a) => a.toLowerCase() == key)) return item.toSlideTheme();
    }
    return slideThemes.first;
  }

  static Future<void> refresh() async {
    try {
      final remote = await catalogPresentationThemesFetch();
      if (remote.isNotEmpty) _items = remote;
    } catch (_) {}
  }

  static final List<PresentationThemeCatalogItem> _builtinItems = [
    PresentationThemeCatalogItem(id: 'dark', labelKey: 'presentation.theme.dark.label', sort: 0, icon: 'iconify://mdi:flash', tokens: _darkTokens),
    PresentationThemeCatalogItem(id: 'midnight', labelKey: 'presentation.theme.midnight.label', sort: 10, icon: 'iconify://mdi:moon-waning-crescent', tokens: _midnightTokens, aliases: const ['indigo']),
    PresentationThemeCatalogItem(id: 'emerald', labelKey: 'presentation.theme.emerald.label', sort: 20, icon: 'iconify://mdi:leaf', tokens: _emeraldTokens, aliases: const ['corporate', 'mint']),
    PresentationThemeCatalogItem(id: 'sunset', labelKey: 'presentation.theme.sunset.label', sort: 30, icon: 'iconify://mdi:white-balance-sunny', tokens: _sunsetTokens, aliases: const ['coral', 'pink']),
    PresentationThemeCatalogItem(id: 'ocean', labelKey: 'presentation.theme.ocean.label', sort: 40, icon: 'iconify://mdi:waves', tokens: _oceanTokens, aliases: const ['cyan', 'aqua']),
    PresentationThemeCatalogItem(id: 'ruby', labelKey: 'presentation.theme.ruby.label', sort: 50, icon: 'iconify://mdi:gem', tokens: _rubyTokens, aliases: const ['rose', 'red']),
    PresentationThemeCatalogItem(id: 'gold', labelKey: 'presentation.theme.gold.label', sort: 60, icon: 'iconify://mdi:crown', tokens: _goldTokens, aliases: const ['amber', 'yellow']),
    PresentationThemeCatalogItem(id: 'arctic', labelKey: 'presentation.theme.arctic.label', sort: 70, icon: 'iconify://mdi:snowflake', tokens: _arcticTokens, aliases: const ['light', 'white']),
    PresentationThemeCatalogItem(id: 'lavender', labelKey: 'presentation.theme.lavender.label', sort: 80, icon: 'iconify://mdi:auto-fix', tokens: _lavenderTokens, aliases: const ['amethyst', 'purple', 'violet']),
    PresentationThemeCatalogItem(id: 'cream', labelKey: 'presentation.theme.cream.label', sort: 90, icon: 'iconify://mdi:book-open-page-variant', tokens: _creamTokens, aliases: const ['editorial', 'paper', 'minimal', 'warm']),
    PresentationThemeCatalogItem(id: 'monochrome', labelKey: 'presentation.theme.monochrome.label', sort: 100, icon: 'iconify://mdi:circle-half-full', tokens: _monochromeTokens, aliases: const ['bw', 'slate', 'silver', 'zinc']),
    PresentationThemeCatalogItem(id: 'forest', labelKey: 'presentation.theme.forest.label', sort: 110, icon: 'iconify://mdi:pine-tree', tokens: _forestTokens, aliases: const ['moss', 'nature', 'sage', 'botanical']),
    PresentationThemeCatalogItem(id: 'sakura', labelKey: 'presentation.theme.sakura.label', sort: 120, icon: 'iconify://mdi:flower', tokens: _sakuraTokens, aliases: const ['blossom', 'rose-light', 'pastel', 'floral']),
    PresentationThemeCatalogItem(id: 'cyberpunk', labelKey: 'presentation.theme.cyberpunk.label', sort: 130, icon: 'iconify://mdi:controller', tokens: _cyberpunkTokens, aliases: const ['synthwave', 'neon', 'tokyo', 'gaming']),
    PresentationThemeCatalogItem(id: 'coffee', labelKey: 'presentation.theme.coffee.label', sort: 140, icon: 'iconify://mdi:coffee', tokens: _coffeeTokens, aliases: const ['mocha', 'espresso', 'leather', 'artisan']),
    PresentationThemeCatalogItem(id: 'aurora', labelKey: 'presentation.theme.aurora.label', sort: 150, icon: 'iconify://mdi:weather-night', tokens: _auroraTokens, aliases: const ['teal', 'boreal', 'nordic']),
  ];

  static const Map<String, dynamic> _darkTokens = {
    'canvas_bg': '#0D0D11', 'card_bg': '#141418', 'border': '#26262C', 'accent': '#F97316', 'accent2': '#06B6D4',
    'text': '#F4F4F5', 'subtext': '#A1A1AA', 'badge_bg': '#261810', 'bullet_card_bg': '#14FFFFFF',
    'gradient_from': '#1A1A22', 'gradient_to': '#0E0E12',
  };
  static const Map<String, dynamic> _midnightTokens = {
    'canvas_bg': '#0B0F19', 'card_bg': '#0F172A', 'border': '#1E293B', 'accent': '#6366F1', 'accent2': '#38BDF8',
    'text': '#F8FAFC', 'subtext': '#94A3B8', 'badge_bg': '#1E1B4B', 'bullet_card_bg': '#1A6366F1',
    'gradient_from': '#1E1B4B', 'gradient_to': '#0F172A',
  };
  static const Map<String, dynamic> _emeraldTokens = {
    'canvas_bg': '#041C16', 'card_bg': '#062820', 'border': '#0D4236', 'accent': '#10B981', 'accent2': '#34D399',
    'text': '#ECFDF5', 'subtext': '#6EE7B7', 'badge_bg': '#064E3B', 'bullet_card_bg': '#1A10B981',
    'gradient_from': '#064E3B', 'gradient_to': '#041C16',
  };
  static const Map<String, dynamic> _sunsetTokens = {
    'canvas_bg': '#140814', 'card_bg': '#1E101E', 'border': '#3A1A38', 'accent': '#EC4899', 'accent2': '#F59E0B',
    'text': '#FFF1F2', 'subtext': '#FDA4AF', 'badge_bg': '#3B0764', 'bullet_card_bg': '#1AEC4899',
    'gradient_from': '#3B0764', 'gradient_to': '#180816',
  };
  static const Map<String, dynamic> _oceanTokens = {
    'canvas_bg': '#030712', 'card_bg': '#0B1220', 'border': '#1E3A5F', 'accent': '#22D3EE', 'accent2': '#3B82F6',
    'text': '#F0F9FF', 'subtext': '#7DD3FC', 'badge_bg': '#0C4A6E', 'bullet_card_bg': '#1A22D3EE',
    'gradient_from': '#0C4A6E', 'gradient_to': '#030712',
  };
  static const Map<String, dynamic> _rubyTokens = {
    'canvas_bg': '#0F0507', 'card_bg': '#1A0A0E', 'border': '#4A1D28', 'accent': '#FB7185', 'accent2': '#F43F5E',
    'text': '#FFF1F2', 'subtext': '#FDA4AF', 'badge_bg': '#4C0519', 'bullet_card_bg': '#1AFB7185',
    'gradient_from': '#4C0519', 'gradient_to': '#0F0507',
  };
  static const Map<String, dynamic> _goldTokens = {
    'canvas_bg': '#0A0908', 'card_bg': '#14110E', 'border': '#3D3428', 'accent': '#FACC15', 'accent2': '#F59E0B',
    'text': '#FEFCE8', 'subtext': '#FDE68A', 'badge_bg': '#422006', 'bullet_card_bg': '#1AFACC15',
    'gradient_from': '#422006', 'gradient_to': '#0A0908',
  };
  static const Map<String, dynamic> _arcticTokens = {
    'canvas_bg': '#F1F5F9', 'card_bg': '#FFFFFF', 'border': '#CBD5E1', 'accent': '#0369A1', 'accent2': '#0284C7',
    'text': '#0F172A', 'subtext': '#475569', 'badge_bg': '#E0F2FE', 'bullet_card_bg': '#140369A1',
    'gradient_from': '#E2E8F0', 'gradient_to': '#F8FAFC',
  };
  static const Map<String, dynamic> _lavenderTokens = {
    'canvas_bg': '#0E0C1A', 'card_bg': '#161326', 'border': '#2E254C', 'accent': '#A855F7', 'accent2': '#EC4899',
    'text': '#FAF5FF', 'subtext': '#D8B4FE', 'badge_bg': '#3B185F', 'bullet_card_bg': '#1AA855F7',
    'gradient_from': '#2A1647', 'gradient_to': '#0E0C1A',
  };
  static const Map<String, dynamic> _creamTokens = {
    'canvas_bg': '#FDFBF7', 'card_bg': '#FFFFFF', 'border': '#E7E1D8', 'accent': '#C2410C', 'accent2': '#D97706',
    'text': '#1C1917', 'subtext': '#78716C', 'badge_bg': '#FFEDD5', 'bullet_card_bg': '#0CC2410C',
    'gradient_from': '#FAF5EE', 'gradient_to': '#FDFBF7',
  };
  static const Map<String, dynamic> _monochromeTokens = {
    'canvas_bg': '#09090B', 'card_bg': '#131316', 'border': '#27272A', 'accent': '#E4E4E7', 'accent2': '#71717A',
    'text': '#FAFAFA', 'subtext': '#A1A1AA', 'badge_bg': '#27272A', 'bullet_card_bg': '#12FFFFFF',
    'gradient_from': '#202024', 'gradient_to': '#09090B',
  };
  static const Map<String, dynamic> _forestTokens = {
    'canvas_bg': '#08130B', 'card_bg': '#102014', 'border': '#1E3A24', 'accent': '#84CC16', 'accent2': '#A3E635',
    'text': '#F7FEE7', 'subtext': '#BEF264', 'badge_bg': '#1A2E05', 'bullet_card_bg': '#1A84CC16',
    'gradient_from': '#16331C', 'gradient_to': '#08130B',
  };
  static const Map<String, dynamic> _sakuraTokens = {
    'canvas_bg': '#FFF5F5', 'card_bg': '#FFFFFF', 'border': '#FED7D7', 'accent': '#E11D48', 'accent2': '#FB7185',
    'text': '#1C1917', 'subtext': '#831843', 'badge_bg': '#FFE4E6', 'bullet_card_bg': '#0DE11D48',
    'gradient_from': '#FCE7F3', 'gradient_to': '#FFF5F5',
  };
  static const Map<String, dynamic> _cyberpunkTokens = {
    'canvas_bg': '#070614', 'card_bg': '#100E26', 'border': '#282054', 'accent': '#F43F5E', 'accent2': '#00F5FF',
    'text': '#FDF4FF', 'subtext': '#E879F9', 'badge_bg': '#3B0764', 'bullet_card_bg': '#1AF43F5E',
    'gradient_from': '#2B1055', 'gradient_to': '#070614',
  };
  static const Map<String, dynamic> _coffeeTokens = {
    'canvas_bg': '#120C0A', 'card_bg': '#1C1411', 'border': '#362520', 'accent': '#D97706', 'accent2': '#EA580C',
    'text': '#FEF3C7', 'subtext': '#D1A074', 'badge_bg': '#2C1810', 'bullet_card_bg': '#1AD97706',
    'gradient_from': '#2B1710', 'gradient_to': '#120C0A',
  };
  static const Map<String, dynamic> _auroraTokens = {
    'canvas_bg': '#040E1A', 'card_bg': '#091B30', 'border': '#13365C', 'accent': '#2DD4BF', 'accent2': '#818CF8',
    'text': '#F0FDFA', 'subtext': '#5EEAD4', 'badge_bg': '#134E4A', 'bullet_card_bg': '#1A2DD4BF',
    'gradient_from': '#0F3559', 'gradient_to': '#040E1A',
  };
}
