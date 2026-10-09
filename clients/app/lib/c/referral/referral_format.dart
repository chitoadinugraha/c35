import 'package:alienai_c35/c/ui/money_format.dart';

const referralCodeNormMaxLen = 20;
const referralCodeGroupLen = 4;
const referralCodeHint = 'ABCD-1234-EFGH-IJKL-MNOP';

String referralCodeNorm(String code) => code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

const voucherPublicOrigin = 'https://alienai.id';

String voucherPublicUrl(String code) => '$voucherPublicOrigin/voucher/${referralCodeNorm(code)}';

String voucherAppWebUrl(String code) => '$voucherPublicOrigin/app/voucher/${referralCodeNorm(code)}';

String voucherAppSchemeUrl(String code) => 'id.alienai://voucher/${referralCodeNorm(code)}';

/// Code from `https://alienai.id/voucher/<code>`, `/app/voucher/<code>`, or `id.alienai://voucher/<code>`.
String? voucherCodeFromUri(Uri uri) {
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (uri.scheme == 'id.alienai' && uri.host.toLowerCase() == 'voucher') {
    if (segs.isEmpty) return null;
    final norm = referralCodeNorm(segs.first);
    return norm.isEmpty ? null : norm;
  }
  final i = segs.indexWhere((s) => s.toLowerCase() == 'voucher');
  if (i >= 0 && i + 1 < segs.length) {
    final norm = referralCodeNorm(segs[i + 1]);
    return norm.isEmpty ? null : norm;
  }
  return null;
}

/// QR payload or a typed code.
String? voucherCodeFromScan(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.hasScheme || trimmed.contains('/'))) {
    final fromUri = voucherCodeFromUri(uri);
    if (fromUri != null) return fromUri;
  }
  final norm = referralCodeNorm(trimmed);
  if (norm.isEmpty) return null;
  if (referralPackageCodeFormValidate(norm) != null) return null;
  return norm;
}

String? referralCodeFormValidate(String code) => referralCodeNorm(code).isEmpty ? 'Code required' : null;

bool referralCodeIsVoucher(String norm) => norm.startsWith('V') && norm.length > 1;

String? referralPackageCodeFormValidate(String code) {
  final norm = referralCodeNorm(code);
  if (norm.isEmpty) return 'Code required';
  if (referralCodeIsVoucher(norm)) {
    if (norm.length < 11) return 'Enter the full voucher code';
    return null;
  }
  if (norm.length != referralCodeNormMaxLen) return 'Enter the full 20-character code';
  return null;
}

const referralWithdrawPayoutWallet = 'wallet_credit';
const referralWithdrawPayoutBank = 'bank_transfer';
const referralWithdrawCurrencyIdr = 'IDR';
const referralWithdrawCurrencyUsd = 'USD';

bool referralCurrencyIsIdr(String currency) => currency.toUpperCase() == 'IDR';

String referralCommissionAmountLabel(String currency, double usd, double idr) =>
    referralCurrencyIsIdr(currency) ? 'Rp ${moneyFmtIdrGrouped(idr.round())}' : referralUsdLabel(usd);

double? referralWithdrawAmountParse(String raw, {bool idr = true}) =>
    idr ? moneyParseIdr(raw) : double.tryParse(raw.trim().replaceAll(',', ''));

String? referralWithdrawAmountValidate(double? amount) => amount == null || amount <= 0 ? 'Amount must be positive' : null;

String referralWithdrawNameNorm(String value) => value.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).join(' ').toLowerCase();

String? referralWithdrawBankValidate({
  required String bankId,
  required String accountNumber,
  required String accountName,
  required String registeredName,
  required int? amount,
  required double availableIdr,
}) {
  if (bankId.trim().isEmpty) return 'Choose a bank';
  if (accountNumber.trim().isEmpty) return 'Account number required';
  if (accountName.trim().isEmpty) return 'Atas nama required';
  final registered = registeredName.trim();
  if (registered.isNotEmpty && referralWithdrawNameNorm(accountName) != referralWithdrawNameNorm(registered)) {
    return 'Account name must match your registered name';
  }
  final amountErr = referralWithdrawAmountValidate(amount?.toDouble());
  if (amountErr != null) return amountErr;
  if (amount! > availableIdr) return 'Insufficient commission balance';
  return null;
}

String referralUsdLabel(double usd) => '\$${usd.toStringAsFixed(2)}';

bool referralCommissionHasBalance(double usd, double idr) => idr > 0 || usd > 0;

String referralCommissionStripLabel(double usd, double idr) {
  if (idr > 0) return 'Rp ${moneyFmtIdrGrouped(idr.round())}';
  if (usd > 0) return referralUsdLabel(usd);
  return '—';
}

String referralLedgerWhenLabel(int createdAtMs) {
  if (createdAtMs <= 0) return '';
  final at = DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}:${two(at.minute)}';
}

String referralCodeFormat(String code) {
  final cleaned = referralCodeNorm(code);
  if (cleaned.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < cleaned.length; i++) {
    if (i > 0 && i % referralCodeGroupLen == 0) buf.write('-');
    buf.write(cleaned[i]);
  }
  return buf.toString();
}

String referralCodeInputFormat(String raw) {
  final norm = referralCodeNorm(raw);
  if (norm.length <= referralCodeNormMaxLen) return referralCodeFormat(norm);
  return referralCodeFormat(norm.substring(0, referralCodeNormMaxLen));
}

String referralCodeTypeLabel(String type) => switch (type) {
      'referral' => 'Sign up',
      'package' => 'Package',
      _ => type,
    };

String referralGlobalRoleLabel(String role) => switch (role) {
      'director' => 'Director',
      'marketing' => 'Marketing',
      'partner' => 'Partner',
      'finance' => 'Finance',
      'root' => 'Root',
      _ => role,
    };

bool referralCodeAffiliateListHidden(int expiresAtMs, int maxUses, int usedCount) {
  if (expiresAtMs > 0 && expiresAtMs <= DateTime.now().millisecondsSinceEpoch) return true;
  if (maxUses > 0 && usedCount >= maxUses) return true;
  return false;
}

String referralCodeExpiresLabelMs(int expiresAtMs) {
  if (expiresAtMs <= 0) return '';
  final at = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
  final now = DateTime.now();
  if (!at.isAfter(now)) return 'Expired';
  final diff = at.difference(now);
  if (diff.inHours < 24) {
    if (diff.inHours > 0) return 'Expires in ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'Expires in ${diff.inMinutes}m';
    return 'Expires in <1m';
  }
  return 'Expires ${at.month}/${at.day}';
}

String referralCodePriceUsdLabel(double priceUsd, int durationMonths, int maxUses, int usedCount) {
  final parts = <String>[];
  if (priceUsd > 0) parts.add('\$${priceUsd.toStringAsFixed(2)}');
  if (durationMonths > 0) parts.add('${durationMonths}mo');
  if (maxUses > 0) parts.add('$usedCount/$maxUses');
  return parts.join(' · ');
}
