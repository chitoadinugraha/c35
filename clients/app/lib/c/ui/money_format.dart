import 'package:alienai_c35/c/ui/ui_format.dart';

const moneyUsdMicro = 1000000;

/// Indonesian grouping: 50000 -> IDR 50.000
String moneyFmtIdr(num n, {int decimals = 0}) {
  if (decimals > 0) {
    final parts = n.toStringAsFixed(decimals).split('.');
    return 'IDR ${moneyFmtIdrGrouped(int.tryParse(parts[0]) ?? 0)}.${parts[1]}';
  }
  return 'IDR ${moneyFmtIdrGrouped(n.round())}';
}

String moneyFmtUsd(double n, {int decimals = 2}) => 'USD ${n.toStringAsFixed(decimals)}';

String moneyFmtIdrGrouped(int n) {
  if (n == 0) return '0';
  final neg = n < 0;
  final s = (neg ? -n : n).toString();
  final out = StringBuffer();
  final lead = s.length % 3;
  if (lead > 0) {
    out.write(s.substring(0, lead));
    if (s.length > lead) out.write('.');
  }
  for (var i = lead; i < s.length; i += 3) {
    out.write(s.substring(i, i + 3));
    if (i + 3 < s.length) out.write('.');
  }
  return neg ? '-$out' : out.toString();
}
const moneyDefaultCurrency = 'IDR';
const moneyDefaultFxMicroPerUsd = 17630000000;

double moneyUsdToLocal(double usd, int fxMicroPerUsd) => usd * fxMicroPerUsd / moneyUsdMicro;

int moneyIdrDetailDecimals(double amount) {
  final abs = amount.abs();
  if (abs < 0.01) return 4;
  if (abs < 1) return 3;
  if (abs < 100) return 2;
  return 0;
}

String moneyFmtIdrDetail(num n) => moneyFmtIdr(n, decimals: moneyIdrDetailDecimals(n.toDouble()));

String moneyCostLabel(double costUsd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  if (costUsd <= 0) return '';
  final cur = currency.toUpperCase();
  if (cur == 'USD') return uiFmtUsd(costUsd);
  final local = moneyUsdToLocal(costUsd, fxMicroPerUsd);
  if (cur == 'IDR') return moneyFmtIdrDetail(local);
  return '$cur ${local.toStringAsFixed(4)}';
}

String moneyBalanceLabel(double balanceUsd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final cur = currency.toUpperCase();
  if (cur == 'USD') return '\$${balanceUsd.toStringAsFixed(2)}';
  final local = moneyUsdToLocal(balanceUsd, fxMicroPerUsd);
  if (cur == 'IDR') return moneyFmtIdr(local);
  return '$cur ${local.toStringAsFixed(2)}';
}

String moneyAllowanceLabel(double usd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final cur = currency.toUpperCase();
  if (cur == 'USD') return '\$${usd.toStringAsFixed(3)}';
  final local = moneyUsdToLocal(usd, fxMicroPerUsd);
  if (cur == 'IDR') return moneyFmtIdr(local);
  return '$cur ${local.toStringAsFixed(2)}';
}
