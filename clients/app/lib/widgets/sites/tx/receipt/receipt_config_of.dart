import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/receipt/receipt_config.dart';

Map<String, dynamic>? _receiptJsonFromCapabilities(String raw) {
  if (raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final receipt = decoded['receipt'];
    return receipt is Map ? Map<String, dynamic>.from(receipt) : null;
  } catch (_) {
    return null;
  }
}

String _receiptStr(Map<String, dynamic>? json, String key) => (json?[key] as String?)?.trim() ?? '';

int _receiptInt(Map<String, dynamic>? json, String key, int fallback) {
  final v = json?[key];
  if (v is int) return v;
  if (v is num) return v.round();
  return fallback;
}

bool receiptShowQrLinkFromCapabilities(String capabilitiesJson) {
  final receipt = _receiptJsonFromCapabilities(capabilitiesJson);
  return receipt?['show_qr_link'] is bool ? receipt!['show_qr_link'] as bool : true;
}

/// Updates `receipt.show_qr_link` without dropping other capability keys.
String capabilitiesJsonSetReceiptShowQrLink(String capabilitiesJson, bool showQrLink) {
  Map<String, dynamic> root;
  final trimmed = capabilitiesJson.trim();
  if (trimmed.isEmpty) {
    root = <String, dynamic>{};
  } else {
    try {
      final decoded = jsonDecode(trimmed);
      root = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    } catch (_) {
      root = <String, dynamic>{};
    }
  }
  final receipt = Map<String, dynamic>.from(root['receipt'] is Map ? root['receipt'] as Map : {});
  receipt['show_qr_link'] = showQrLink;
  root['receipt'] = receipt;
  return jsonEncode(root);
}

Map<String, dynamic> _capabilitiesRoot(String capabilitiesJson) {
  final trimmed = capabilitiesJson.trim();
  if (trimmed.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(trimmed);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}

/// Persist receipt block under site `capabilities_json`.
String capabilitiesJsonSetReceipt({
  required String capabilitiesJson,
  String? header,
  String? footer,
  String? address,
  String? contact,
  bool? showQrLink,
  bool? showSiteName,
  int? marginMm,
  int? paperWidthMm,
  int? logoSizePx,
}) {
  final root = _capabilitiesRoot(capabilitiesJson);
  final receipt = Map<String, dynamic>.from(root['receipt'] is Map ? root['receipt'] as Map : {});
  if (header != null) receipt['header'] = header;
  if (footer != null) receipt['footer'] = footer;
  if (address != null) receipt['address'] = address;
  if (contact != null) receipt['contact'] = contact;
  if (showQrLink != null) receipt['show_qr_link'] = showQrLink;
  if (showSiteName != null) receipt['show_site_name'] = showSiteName;
  if (marginMm != null) receipt['margin_mm'] = marginMm;
  if (paperWidthMm != null) receipt['paper_width_mm'] = paperWidthMm;
  if (logoSizePx != null) receipt['logo_size_px'] = logoSizePx;
  root['receipt'] = receipt;
  return jsonEncode(root);
}

ReceiptConfig receiptConfigOf(SiteRow? site, {SiteConfig? config}) {
  final receipt = _receiptJsonFromCapabilities(config?.capabilitiesJson ?? '');
  return ReceiptConfig(
    projectName: site?.name ?? '',
    projectLogo: site?.pic ?? '',
    receiptHeader: _receiptStr(receipt, 'header'),
    receiptFooter: _receiptStr(receipt, 'footer'),
    projectAddress: _receiptStr(receipt, 'address'),
    projectContact: _receiptStr(receipt, 'contact'),
    showQrLink: receipt?['show_qr_link'] is bool ? receipt!['show_qr_link'] as bool : true,
    showSiteName: receipt?['show_site_name'] is bool ? receipt!['show_site_name'] as bool : true,
    marginMm: _receiptInt(receipt, 'margin_mm', 0),
    paperWidthMm: _receiptInt(receipt, 'paper_width_mm', 80) == 58 ? 58 : 80,
    logoSizePx: _receiptInt(receipt, 'logo_size_px', 60).clamp(32, 96),
  );
}

ReceiptConfig receiptConfigMerge(ReceiptConfig base, ReceiptConfig fromSite) => ReceiptConfig(
      projectName: base.projectName.isNotEmpty ? base.projectName : fromSite.projectName,
      projectLogo: base.projectLogo.isNotEmpty ? base.projectLogo : fromSite.projectLogo,
      receiptHeader: base.receiptHeader.isNotEmpty ? base.receiptHeader : fromSite.receiptHeader,
      receiptFooter: base.receiptFooter.isNotEmpty ? base.receiptFooter : fromSite.receiptFooter,
      projectAddress: base.projectAddress.isNotEmpty ? base.projectAddress : fromSite.projectAddress,
      projectContact: base.projectContact.isNotEmpty ? base.projectContact : fromSite.projectContact,
      marginMm: fromSite.marginMm,
      paperWidthMm: fromSite.paperWidthMm,
      logoSizePx: fromSite.logoSizePx,
      showQrLink: base.showQrLink,
      showSiteName: fromSite.showSiteName,
    );
