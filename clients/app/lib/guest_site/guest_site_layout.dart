/// `hub` (narrow) vs `store` (wider catalog). Matches `mod_site::guest_i18n::guest_layout_mode`.
String guestLayoutMode(Map<String, dynamic> meta, {required int productCount}) {
  final explicit = (meta['guest_layout'] ?? meta['layout_mode'] ?? '').toString().trim().toLowerCase();
  if (explicit == 'store') return 'store';
  if (explicit == 'hub') return 'hub';
  return productCount >= 9 ? 'store' : 'hub';
}

double guestLayoutMaxWidth(String layout) => layout == 'store' ? 1040 : 720;

int guestProductGridCrossAxisCount(double maxWidth, String layout) {
  if (layout == 'store') {
    if (maxWidth >= 900) return 4;
    if (maxWidth >= 600) return 3;
    return 2;
  }
  if (maxWidth >= 520) return 3;
  return 2;
}
