import 'package:alienai_c35/c/ui/ui_format.dart';

const moneyUsdMicro = 1000000;
const moneyDefaultCurrency = 'IDR';
const moneyDefaultFxMicroPerUsd = 17630000000;

double moneyUsdToLocal(double usd, int fxMicroPerUsd) => usd * fxMicroPerUsd / moneyUsdMicro;

String moneyCostLabel(double costUsd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  if (costUsd <= 0) return '';
  final cur = currency.toUpperCase();
  if (cur == 'USD') return uiFmtUsd(costUsd);
  final local = moneyUsdToLocal(costUsd, fxMicroPerUsd);
  if (cur == 'IDR') {
    if (local < 0.01) return 'Rp ${local.toStringAsFixed(4)}';
    if (local < 1) return 'Rp ${local.toStringAsFixed(2)}';
    return 'Rp ${local.round()}';
  }
  return '$cur ${local.toStringAsFixed(4)}';
}

String moneyBalanceLabel(double balanceUsd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final cur = currency.toUpperCase();
  if (cur == 'USD') return '\$${balanceUsd.toStringAsFixed(2)}';
  final local = moneyUsdToLocal(balanceUsd, fxMicroPerUsd);
  if (cur == 'IDR') return 'Rp ${local.round()}';
  return '$cur ${local.toStringAsFixed(2)}';
}

String moneyAllowanceLabel(double usd, {String currency = moneyDefaultCurrency, int fxMicroPerUsd = moneyDefaultFxMicroPerUsd}) {
  final cur = currency.toUpperCase();
  if (cur == 'USD') return '\$${usd.toStringAsFixed(3)}';
  final local = moneyUsdToLocal(usd, fxMicroPerUsd);
  if (cur == 'IDR') return 'Rp ${local.round()}';
  return '$cur ${local.toStringAsFixed(2)}';
}
