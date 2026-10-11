import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/ui/money_format.dart';

/// Sentinel stored on `site.product.price` for quote-only items.
const guestProductPriceContact = -1;

String guestProductPriceLabel(int price) {
  if (price == guestProductPriceContact) return 'Contact Us';
  if (price <= 0) return '';
  return moneyFmtIdr(price);
}

bool guestProductCanAddToCart(int price) => price > 0;

/// `grid` (default) or `list`.
String productGridDisplay(Map<String, dynamic> props, {Map<String, dynamic>? meta}) {
  final raw = props['display']?.toString().trim().toLowerCase() ?? '';
  if (raw == 'list') return 'list';
  if (raw == 'grid' || raw == 'card') return 'grid';
  final metaRaw = meta?['catalog_display']?.toString().trim().toLowerCase() ?? '';
  if (metaRaw == 'list') return 'list';
  return 'grid';
}

String _picHashOnly(String pic) {
  final p = pic.trim();
  if (p.isEmpty) return '';
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  var path = p;
  if (path.startsWith('/fs/')) path = path.substring(4);
  else if (path.startsWith('fs/')) path = path.substring(3);
  return path.split('?').first;
}

String guestSitePicThumbUrl(String pic) {
  final h = _picHashOnly(pic);
  if (h.isEmpty) return '';
  if (h.startsWith('http')) return h;
  if (pic.trim().startsWith('/fs/')) return 'https://f.alienai.id$pic'.split('?').first + '?v=thumb';
  return 'https://f.alienai.id/fs/$h?v=thumb';
}

String guestSitePicDisplayUrl(String pic) {
  final h = _picHashOnly(pic);
  if (h.isEmpty) return '';
  if (h.startsWith('http')) return h;
  return 'https://f.alienai.id/fs/$h?v=small';
}

/// In-app authenticated file URL with variant query.
String guestSitePicServePath(String pic, {required bool display}) {
  final h = _picHashOnly(pic);
  if (h.isEmpty) return '';
  final variant = display ? 'small' : 'thumb';
  return '/fs/$h?v=$variant';
}

String guestSitePicPublicUrl(String pic, {required bool display}) {
  final h = _picHashOnly(pic);
  if (h.isEmpty) return '';
  if (h.startsWith('http')) return h;
  final variant = display ? 'small' : 'thumb';
  return '${C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '')}/fs/$h?v=$variant';
}
