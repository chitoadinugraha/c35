import 'package:alienai_c35/c/ui/money_format.dart';

const referralCodeNormMaxLen = 20;
const referralCodeGroupLen = 4;
const referralCodeHint = 'ABCD-1234-EFGH-IJKL-MNOP';

String referralCodeNorm(String code) => code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

String? referralCodeFormValidate(String code) => referralCodeNorm(code).isEmpty ? 'Code required' : null;

String? referralPackageCodeFormValidate(String code) {
  final norm = referralCodeNorm(code);
  if (norm.isEmpty) return 'Code required';
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

double? referralWithdrawAmountParse(String raw) => double.tryParse(raw.trim().replaceAll(',', ''));

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
