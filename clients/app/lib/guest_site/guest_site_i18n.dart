/// Guest storefront copy from `SiteDoc.meta.lang` / `meta.locale` (default Indonesian).
class GuestSiteI18n {
  const GuestSiteI18n({this.indonesian = true});

  final bool indonesian;

  factory GuestSiteI18n.fromMeta(Map<String, dynamic> meta) {
    final raw = (meta['lang'] ?? meta['locale'] ?? '').toString().trim().toLowerCase();
    if (raw.isEmpty) return const GuestSiteI18n(indonesian: true);
    return GuestSiteI18n(indonesian: raw.startsWith('id'));
  }

  static const english = GuestSiteI18n(indonesian: false);

  String get priceContact => indonesian ? 'Hubungi kami' : 'Contact us';

  String get tileContactCta => indonesian ? 'Hubungi' : 'Contact';

  String get catalogDefaultTitle => indonesian ? 'Katalog & Layanan' : 'Catalog & services';

  String get catalogSectionEyebrow => indonesian ? 'Katalog' : 'Catalog';

  String get catalogSearchPlaceholder => indonesian ? 'Cari produk…' : 'Search products…';

  String get hubTabShop => indonesian ? 'Toko' : 'Shop';

  String get hubTabPosts => indonesian ? 'Posting' : 'Posts';

  String hubSeeAllPosts(int total) => indonesian ? 'Lihat semua ($total)' : 'See all ($total)';

  String get filterAll => indonesian ? 'Semua' : 'All';

  String get signIn => indonesian ? 'Masuk' : 'Sign in';

  String get shareStoreAria => indonesian ? 'Bagikan toko' : 'Share store';

  String get loadMore => indonesian ? 'Muat lebih banyak' : 'Load more';

  String get loading => indonesian ? 'Memuat…' : 'Loading…';

  String get detailAria => indonesian ? 'Detail produk' : 'Product details';

  String get shareAria => indonesian ? 'Bagikan produk' : 'Share product';

  String get assistantChatSubtitle =>
      indonesian ? 'Biasanya membalas dalam beberapa menit' : 'We typically reply in a few minutes';

  String assistantChatEmpty(String siteName) => indonesian
      ? 'Tanyakan ke $siteName tentang produk, jam buka, atau pesanan Anda.'
      : 'Ask $siteName about products, hours, or your order.';

  String get assistantPlaceholderDefault => indonesian ? 'Ketik pesan…' : 'Type a message…';

  String get assistantPoweredPrefix => 'Powered by';
}
