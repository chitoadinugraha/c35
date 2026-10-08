import 'package:flutter/material.dart';

const siteLinkPlatformIds = [
  'website',
  'whatsapp',
  'phone',
  'email',
  'instagram',
  'facebook',
  'telegram',
  'line',
  'tiktok',
  'youtube',
  'google_business',
  'github',
  'shopee',
  'tokopedia',
  'lazada',
  'location',
];

String siteLinkPlatformLabel(String id) => switch (siteLinkPlatformNormalize(id)) {
      'website' => 'Website',
      'whatsapp' => 'WhatsApp',
      'phone' => 'Phone',
      'email' => 'Email',
      'instagram' => 'Instagram',
      'facebook' => 'Facebook',
      'telegram' => 'Telegram',
      'line' => 'LINE',
      'tiktok' => 'TikTok',
      'youtube' => 'YouTube',
      'google_business' => 'Google Business',
      'github' => 'GitHub',
      'shopee' => 'Shopee',
      'tokopedia' => 'Tokopedia',
      'lazada' => 'Lazada',
      'location' => 'Location',
      _ => 'Link',
    };

String siteLinkDefaultTitle(String id) => siteLinkPlatformLabel(id);

String siteLinkValueLabel(String id) => switch (siteLinkPlatformNormalize(id)) {
      'whatsapp' => 'WhatsApp number',
      'phone' => 'Phone number',
      'email' => 'Email address',
      'instagram' => 'Instagram username',
      'telegram' => 'Telegram username',
      'tiktok' => 'TikTok username',
      _ => 'URL',
    };

String? siteLinkValueHint(String id) => switch (siteLinkPlatformNormalize(id)) {
      'whatsapp' || 'phone' => '628123456789',
      'email' => 'hello@example.com',
      'instagram' => 'username',
      'telegram' => 'username',
      'tiktok' => 'username',
      'facebook' => 'https://facebook.com/page',
      'line' => 'https://line.me/ti/p/~id',
      'google_business' => 'https://g.page/your-business',
      'github' => 'https://github.com/username',
      'shopee' => 'https://shopee.co.id/shop',
      'tokopedia' => 'https://tokopedia.com/shop',
      'lazada' => 'https://lazada.co.id/shop',
      _ => 'https://',
    };

String siteLinkWhatsAppNumberNormalize(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('0')) return '62${digits.substring(1)}';
  return digits;
}

String siteLinkWhatsAppMeUrl(String raw) {
  final n = siteLinkWhatsAppNumberNormalize(raw);
  return n.isNotEmpty ? 'https://wa.me/$n' : 'https://wa.me/';
}

String siteLinkWhatsAppNumberDisplay(String stored) {
  final raw = stored.trim();
  if (raw.isEmpty) return '';
  final fromWaMe = RegExp(r'^https?://wa\.me/(\d+)', caseSensitive: false).firstMatch(raw);
  if (fromWaMe != null) return fromWaMe.group(1)!;
  return siteLinkWhatsAppNumberNormalize(raw);
}

String siteLinkPhoneNormalize(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('0')) return '+62${digits.substring(1)}';
  if (!digits.startsWith('+')) return '+$digits';
  return digits;
}

String siteLinkTelUrl(String raw) {
  final n = siteLinkPhoneNormalize(raw);
  return n.isNotEmpty ? 'tel:$n' : 'tel:';
}

String siteLinkPhoneDisplay(String stored) {
  final raw = stored.trim();
  if (raw.isEmpty) return '';
  final fromTel = RegExp(r'^tel:([+\d]+)', caseSensitive: false).firstMatch(raw);
  if (fromTel != null) return fromTel.group(1)!;
  return siteLinkPhoneNormalize(raw);
}

String siteLinkEmailDisplay(String stored) => stored.trim().replaceFirst(RegExp(r'^mailto:', caseSensitive: false), '');

String siteLinkEmailUrl(String raw) {
  final e = siteLinkEmailDisplay(raw);
  return e.isNotEmpty ? 'mailto:$e' : 'mailto:';
}

String siteLinkUsernameNormalize(String raw, {required List<String> hosts}) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  final withScheme = RegExp(r'^https?://', caseSensitive: false).hasMatch(s)
      ? s
      : (s.contains('/') || hosts.any((h) => s.toLowerCase().contains(h)) ? 'https://$s' : s);
  final uri = Uri.tryParse(withScheme);
  if (uri != null && uri.host.isNotEmpty && hosts.any((h) => uri.host.toLowerCase().contains(h))) {
    final segs = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    s = segs.isNotEmpty ? segs.first : '';
  }
  if (s.startsWith('@')) s = s.substring(1);
  s = s.split(RegExp(r'[/?#]')).first.trim();
  return s;
}

String siteLinkInstagramUsernameNormalize(String raw) =>
    siteLinkUsernameNormalize(raw, hosts: const ['instagram.com', 'instagr.am']);

String siteLinkInstagramUrl(String raw) {
  final u = siteLinkInstagramUsernameNormalize(raw);
  return u.isNotEmpty ? 'https://instagram.com/$u' : 'https://instagram.com/';
}

String siteLinkInstagramUsernameDisplay(String stored) => siteLinkInstagramUsernameNormalize(stored);

String siteLinkTelegramUsernameNormalize(String raw) =>
    siteLinkUsernameNormalize(raw, hosts: const ['t.me', 'telegram.me', 'telegram.dog']);

String siteLinkTelegramUrl(String raw) {
  final u = siteLinkTelegramUsernameNormalize(raw);
  return u.isNotEmpty ? 'https://t.me/$u' : 'https://t.me/';
}

String siteLinkTelegramUsernameDisplay(String stored) => siteLinkTelegramUsernameNormalize(stored);

String siteLinkTikTokUsernameNormalize(String raw) => siteLinkUsernameNormalize(raw, hosts: const ['tiktok.com']);

String siteLinkTikTokUrl(String raw) {
  final u = siteLinkTikTokUsernameNormalize(raw);
  return u.isNotEmpty ? 'https://www.tiktok.com/@$u' : 'https://www.tiktok.com/@';
}

String siteLinkTikTokUsernameDisplay(String stored) => siteLinkTikTokUsernameNormalize(stored);

String siteLinkUrlForSave({required String icon, required String raw}) => switch (siteLinkPlatformNormalize(icon)) {
      'whatsapp' => siteLinkWhatsAppMeUrl(raw),
      'phone' => siteLinkTelUrl(raw),
      'email' => siteLinkEmailUrl(raw),
      'instagram' => siteLinkInstagramUrl(raw),
      'telegram' => siteLinkTelegramUrl(raw),
      'tiktok' => siteLinkTikTokUrl(raw),
      _ => raw.trim(),
    };

String siteLinkValueDisplay({required String icon, required String stored}) => switch (siteLinkPlatformNormalize(icon)) {
      'whatsapp' => siteLinkWhatsAppNumberDisplay(stored),
      'phone' => siteLinkPhoneDisplay(stored),
      'email' => siteLinkEmailDisplay(stored),
      'instagram' => siteLinkInstagramUsernameDisplay(stored),
      'telegram' => siteLinkTelegramUsernameDisplay(stored),
      'tiktok' => siteLinkTikTokUsernameDisplay(stored),
      _ => stored,
    };

bool siteLinkHasPreviewValue({required String icon, required String raw}) => switch (siteLinkPlatformNormalize(icon)) {
      'whatsapp' => siteLinkWhatsAppNumberNormalize(raw).isNotEmpty,
      'phone' => siteLinkPhoneNormalize(raw).isNotEmpty,
      'email' => siteLinkEmailDisplay(raw).isNotEmpty,
      'instagram' => siteLinkInstagramUsernameNormalize(raw).isNotEmpty,
      'telegram' => siteLinkTelegramUsernameNormalize(raw).isNotEmpty,
      'tiktok' => siteLinkTikTokUsernameNormalize(raw).isNotEmpty,
      _ => raw.trim().isNotEmpty,
    };

List<String> siteLinkPlatformFilter(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return siteLinkPlatformIds;
  return siteLinkPlatformIds.where((id) => id.contains(q) || siteLinkPlatformLabel(id).toLowerCase().contains(q)).toList();
}

String siteLinkPlatformNormalize(String id) => siteLinkPlatformIds.contains(id) ? id : 'website';

bool siteLinkPreviewUrlEmpty(String url) =>
    url.isEmpty ||
    url == 'https://wa.me/' ||
    url == 'tel:' ||
    url == 'mailto:' ||
    url == 'https://instagram.com/' ||
    url == 'https://t.me/' ||
    url == 'https://www.tiktok.com/@';

TextInputType siteLinkValueKeyboardType(String icon) => switch (siteLinkPlatformNormalize(icon)) {
      'whatsapp' || 'phone' => TextInputType.phone,
      'email' => TextInputType.emailAddress,
      'instagram' || 'telegram' || 'tiktok' => TextInputType.text,
      _ => TextInputType.url,
    };
