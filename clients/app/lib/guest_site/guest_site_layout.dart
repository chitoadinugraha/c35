/// `hub` (narrow) vs `store` (wider catalog). Matches `mod_site::guest_i18n::guest_layout_mode`.
String guestLayoutMode(Map<String, dynamic> meta, {required int productCount}) {
  final explicit = (meta['guest_layout'] ?? meta['layout_mode'] ?? '').toString().trim().toLowerCase();
  if (explicit == 'store') return 'store';
  if (explicit == 'hub') return 'hub';
  return productCount >= 9 ? 'store' : 'hub';
}

double guestLayoutMaxWidth(String layout) => layout == 'store' ? 1040 : 720;

/// Matches web `.guest-page-main` horizontal inset (`site-guest.v1.css`).
const double guestShellHorizontalPadding = 16;

/// Bottom scroll reserve for cart chrome (88px web default; 96px when cart bar visible).
const double guestShellBottomPadding = 88;
const double guestShellBottomPaddingWithCart = 96;

double guestShellListBottomInset({required bool cartBarVisible}) =>
    cartBarVisible ? guestShellBottomPaddingWithCart : guestShellBottomPadding;

int guestProductGridCrossAxisCount(double maxWidth, String layout) {
  if (layout == 'store') {
    if (maxWidth >= 900) return 4;
    if (maxWidth >= 600) return 3;
    return 2;
  }
  if (maxWidth >= 520) return 3;
  return 2;
}
