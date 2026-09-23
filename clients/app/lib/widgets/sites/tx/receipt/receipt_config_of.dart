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
  );
}

ReceiptConfig receiptConfigMerge(ReceiptConfig base, ReceiptConfig fromSite) => ReceiptConfig(
      projectName: base.projectName.isNotEmpty ? base.projectName : fromSite.projectName,
      projectLogo: base.projectLogo.isNotEmpty ? base.projectLogo : fromSite.projectLogo,
      receiptHeader: base.receiptHeader.isNotEmpty ? base.receiptHeader : fromSite.receiptHeader,
      receiptFooter: base.receiptFooter.isNotEmpty ? base.receiptFooter : fromSite.receiptFooter,
      projectAddress: base.projectAddress.isNotEmpty ? base.projectAddress : fromSite.projectAddress,
      projectContact: base.projectContact.isNotEmpty ? base.projectContact : fromSite.projectContact,
      showQrLink: base.showQrLink,
    );
